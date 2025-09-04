import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/note.dart';

class SemanticSearchService {
  static const String _dbName = 'semantic_search.db';
  static const String _assetDbPath = 'assets/databases/comprehensive_search.db';
  Database? _database;
  Map<String, double> _idfScores = {};
  Map<int, Map<String, double>> _docVectors = {};
  bool _isPrebuiltLoaded = false;

  // Cache for performance
  Map<String, List<String>>? _phoneticIndex;
  Map<String, List<String>>? _fuzzyCache;

  static Future<void> initializeDatabaseFactory() async {
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;

    await initializeDatabaseFactory();
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    String dbPath;

    if (kIsWeb) {
      dbPath = _dbName;
    } else {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      dbPath = '${documentsDirectory.path}/$_dbName';

      final dbFile = File(dbPath);
      if (!await dbFile.exists() || !_isPrebuiltLoaded) {
        await _copyDatabaseFromAssets(dbPath);
      }
    }

    return await openDatabase(dbPath, version: 1);
  }

  Future<void> _copyDatabaseFromAssets(String dbPath) async {
    try {
      print('Loading comprehensive database from assets...');
      final data = await rootBundle.load(_assetDbPath);
      final bytes = data.buffer.asUint8List();

      final file = File(dbPath);
      await file.writeAsBytes(bytes);

      print('Comprehensive database loaded successfully');

      final db = await openDatabase(dbPath);
      final vocabResult =
          await db.rawQuery('SELECT COUNT(*) as count FROM vocabulary');
      final docResult =
          await db.rawQuery('SELECT COUNT(*) as count FROM documents');

      final vocabCount = vocabResult.first['count'];
      final docCount = docResult.first['count'];

      print(
          'Database contains $vocabCount vocabulary terms and $docCount training documents');
      await db.close();

      _isPrebuiltLoaded = true;
    } catch (e) {
      print('Failed to load database from assets: $e');
      await _createEmptyDatabase(dbPath);
    }
  }

  Future<void> _createEmptyDatabase(String dbPath) async {
    final db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
          CREATE TABLE vocabulary (
            term TEXT PRIMARY KEY,
            idf REAL
          )
        ''').then((_) => db.execute('''
          CREATE TABLE documents (
            doc_id INTEGER PRIMARY KEY,
            content TEXT,
            vector_json TEXT
          )
        '''));
      },
    );
    await db.close();
  }

  // Vietnamese character normalization for phonetic matching
  String _normalizeVietnamese(String text) {
    final vnMap = {
      'ă': 'a',
      'â': 'a',
      'á': 'a',
      'à': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'ê': 'e',
      'é': 'e',
      'è': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ô': 'o',
      'ơ': 'o',
      'ó': 'o',
      'ò': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ư': 'u',
      'ú': 'u',
      'ù': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'í': 'i',
      'ì': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ý': 'y',
      'ỳ': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd'
    };

    String result = text.toLowerCase();
    vnMap.forEach((key, value) {
      result = result.replaceAll(key, value);
    });

    return result;
  }

  // Edit distance calculation
  int _editDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;

    if (len1 == 0) return len2;
    if (len2 == 0) return len1;

    final dp = List.generate(len1 + 1, (i) => List.filled(len2 + 1, 0));

    for (int i = 0; i <= len1; i++) dp[i][0] = i;
    for (int j = 0; j <= len2; j++) dp[0][j] = j;

    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        if (s1[i - 1] == s2[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1];
        } else {
          dp[i][j] = 1 +
              [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]]
                  .reduce((a, b) => a < b ? a : b);
        }
      }
    }

    return dp[len1][len2];
  }

  // Build phonetic index for fast lookup
  Map<String, List<String>> _buildPhoneticIndex() {
    if (_phoneticIndex != null) return _phoneticIndex!;

    _phoneticIndex = <String, List<String>>{};

    for (final term in _idfScores.keys) {
      if (term.startsWith('syn_')) continue;

      final normalized = _normalizeVietnamese(term);
      _phoneticIndex!.putIfAbsent(normalized, () => []).add(term);

      // Also add the original term
      if (normalized != term) {
        _phoneticIndex!.putIfAbsent(term, () => []).add(term);
      }
    }

    return _phoneticIndex!;
  }

  // Find fuzzy matches using multiple techniques
  List<String> _findFuzzyMatches(String query) {
    final cacheKey = query.toLowerCase();
    if (_fuzzyCache?.containsKey(cacheKey) == true) {
      return _fuzzyCache![cacheKey]!;
    }

    final matches = <String>{};
    final queryNormalized = _normalizeVietnamese(query.toLowerCase());
    final phoneticIndex = _buildPhoneticIndex();

    // 1. Exact phonetic match
    if (phoneticIndex.containsKey(queryNormalized)) {
      matches.addAll(phoneticIndex[queryNormalized]!);
    }

    // 2. Substring matching (both directions)
    for (final term in _idfScores.keys) {
      if (term.startsWith('syn_')) continue;

      final termNormalized = _normalizeVietnamese(term);

      // Query contains term or term contains query
      if (termNormalized.contains(queryNormalized) ||
          queryNormalized.contains(termNormalized)) {
        matches.add(term);
      }
    }

    // 3. Edit distance matching (limited to prevent performance issues)
    final maxDistance = query.length <= 3 ? 1 : (query.length <= 6 ? 2 : 3);

    for (final term in _idfScores.keys) {
      if (term.startsWith('syn_') || matches.contains(term)) continue;
      if (matches.length > 20) break; // Prevent excessive matches

      final termNormalized = _normalizeVietnamese(term);
      final distance = _editDistance(queryNormalized, termNormalized);

      if (distance <= maxDistance) {
        matches.add(term);
      }
    }

    final result = matches.toList();
    _fuzzyCache ??= <String, List<String>>{};
    _fuzzyCache![cacheKey] = result;

    return result;
  }

  Future<void> _loadIndex() async {
    if (_idfScores.isNotEmpty) return;

    final db = await database;

    final vocabRows = await db.query('vocabulary');
    _idfScores.clear();
    for (final row in vocabRows) {
      _idfScores[row['term'] as String] = row['idf'] as double;
    }

    final vectorRows = await db.query('documents');
    _docVectors.clear();
    for (final row in vectorRows) {
      final docId = row['doc_id'] as int;
      final vectorJson = row['vector_json'] as String;
      final vector = Map<String, double>.from(jsonDecode(vectorJson));
      _docVectors[docId] = vector;
    }

    print(
        'Loaded ${_idfScores.length} vocabulary terms and ${_docVectors.length} document vectors');
  }

  List<String> _tokenize(String text) {
    final regex = RegExp(r'\b\w+\b');
    return regex
        .allMatches(text.toLowerCase())
        .map((m) => m.group(0)!)
        .toList();
  }

  Map<String, double> _computeTfIdf(String text) {
    final tokens = _tokenize(text);
    final Map<String, double> termFreq = {};

    for (final token in tokens) {
      termFreq[token] = (termFreq[token] ?? 0) + 1.0;
    }

    final Map<String, double> vector = {};
    final totalTerms = tokens.length;

    for (final entry in termFreq.entries) {
      final term = entry.key;
      final tf = entry.value;
      final idf = _idfScores[term];

      if (idf != null && totalTerms > 0) {
        final tfScore = tf / totalTerms;
        vector[term] = tfScore * idf;
      }
    }

    return vector;
  }

  double _cosineSimilarity(Map<String, double> vec1, Map<String, double> vec2) {
    final commonTerms = vec1.keys.toSet().intersection(vec2.keys.toSet());
    if (commonTerms.isEmpty) return 0.0;

    double dotProduct = 0.0;
    for (final term in commonTerms) {
      dotProduct += vec1[term]! * vec2[term]!;
    }

    final mag1 = sqrt(vec1.values.fold(0.0, (sum, val) => sum + val * val));
    final mag2 = sqrt(vec2.values.fold(0.0, (sum, val) => sum + val * val));

    if (mag1 == 0 || mag2 == 0) return 0.0;

    return dotProduct / (mag1 * mag2);
  }

  Future<void> indexNotes(List<Note> notes) async {
    if (notes.isEmpty) return;

    await _loadIndex();

    final db = await database;
    final result =
        await db.rawQuery('SELECT MAX(doc_id) as max_id FROM documents');
    final maxPrebuiltId = (result.first['max_id'] as int?) ?? -1;

    print(
        'Adding ${notes.length} user notes to prebuilt database (starting from ID ${maxPrebuiltId + 1})');

    final batch = db.batch();
    for (int i = 0; i < notes.length; i++) {
      final note = notes[i];
      final docId = maxPrebuiltId + 1 + i;
      final searchText = '${note.title} ${note.content} ${note.tags.join(' ')}';
      final vector = _computeTfIdf(searchText);

      _docVectors[docId] = vector;

      batch.insert(
          'documents',
          {
            'doc_id': docId,
            'content': searchText,
            'vector_json': jsonEncode(vector),
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit();
    print('User notes integrated with prebuilt database');
  }

  // Enhanced search with fuzzy matching
  Future<List<SemanticSearchResult>> search(String query, List<Note> allNotes,
      {int limit = 20}) async {
    if (query.trim().isEmpty) return [];

    await _loadIndex();

    if (allNotes.isNotEmpty) {
      final db = await database;
      final userResult = await db.rawQuery(
          'SELECT COUNT(*) as count FROM documents WHERE doc_id > 59');
      final hasUserNotes =
          (userResult.first['count'] as int) >= allNotes.length;

      if (!hasUserNotes) {
        await indexNotes(allNotes);
      }
    }

    // Try exact search first
    var results = await _exactSearch(query, allNotes, limit);

    // If no exact results, try fuzzy search
    if (results.isEmpty) {
      results = await _fuzzySearch(query, allNotes, limit);
    }

    return results;
  }

  Future<List<SemanticSearchResult>> _exactSearch(
      String query, List<Note> allNotes, int limit) async {
    final queryVector = _computeTfIdf(query);
    final List<SemanticSearchResult> results = [];

    for (final entry in _docVectors.entries) {
      final docId = entry.key;
      final docVector = entry.value;

      final similarity = _cosineSimilarity(queryVector, docVector);

      if (similarity > 0.15) {
        // Higher threshold for exact search
        // Map doc_id to user notes
        final noteIndex = docId - 60; // Assuming 60 prebuilt docs
        if (noteIndex >= 0 && noteIndex < allNotes.length) {
          results.add(SemanticSearchResult(
            note: allNotes[noteIndex],
            score: similarity,
            index: noteIndex,
          ));
        }
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }

  Future<List<SemanticSearchResult>> _fuzzySearch(
      String query, List<Note> allNotes, int limit) async {
    // Find fuzzy matches
    final fuzzyTerms = _findFuzzyMatches(query);

    if (fuzzyTerms.isEmpty) {
      return _stringBasedSearch(query, allNotes, limit);
    }

    // Create expanded query with original + fuzzy terms
    final expandedQuery = [query, ...fuzzyTerms.take(5)].join(' ');
    final queryVector = _computeTfIdf(expandedQuery);

    final List<SemanticSearchResult> results = [];

    for (final entry in _docVectors.entries) {
      final docId = entry.key;
      final docVector = entry.value;

      final similarity = _cosineSimilarity(queryVector, docVector);

      if (similarity > 0.05) {
        // Lower threshold for fuzzy search
        final noteIndex = docId - 60;
        if (noteIndex >= 0 && noteIndex < allNotes.length) {
          results.add(SemanticSearchResult(
            note: allNotes[noteIndex],
            score: similarity,
            index: noteIndex,
          ));
        }
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }

  // Fallback string-based search
  List<SemanticSearchResult> _stringBasedSearch(
      String query, List<Note> allNotes, int limit) {
    final results = <SemanticSearchResult>[];
    final queryLower = _normalizeVietnamese(query.toLowerCase());

    for (int i = 0; i < allNotes.length; i++) {
      final note = allNotes[i];
      final searchText = _normalizeVietnamese(
          '${note.title} ${note.content} ${note.tags.join(' ')}'.toLowerCase());

      double score = 0.0;

      // Direct substring match
      if (searchText.contains(queryLower)) {
        score += 0.8;
      }

      // Word-level fuzzy matching
      final searchWords = searchText.split(RegExp(r'\s+'));
      for (final word in searchWords) {
        final distance = _editDistance(queryLower, word);
        final maxLen = max(queryLower.length, word.length);

        if (distance <= maxLen * 0.4) {
          score += (1.0 - distance / maxLen) * 0.4;
        }
      }

      if (score > 0.1) {
        results.add(SemanticSearchResult(
          note: note,
          score: score,
          index: i,
        ));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }
}

class SemanticSearchResult {
  final Note note;
  final double score;
  final int index;

  SemanticSearchResult({
    required this.note,
    required this.score,
    required this.index,
  });
}
