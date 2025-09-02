import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class AudioPlayerWidget extends StatefulWidget {
  final String audioPath;
  final Function(String) onRemove;
  final Function(Offset) onMove;
  final Offset position;
  final bool isSelected;
  final Function() onTap;
  final Function(String, String)? onRename;
  final bool isDragging; // Add this parameter
  final String? customName; // Add this parameter

  const AudioPlayerWidget({
    super.key,
    required this.audioPath,
    required this.onRemove,
    required this.onMove,
    required this.position,
    required this.isSelected,
    required this.onTap,
    this.onRename,
    this.isDragging = false, // Add this parameter
    this.customName, // Add this parameter
  });

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String _fileName = '';
  DateTime? _dateAdded;
  int _fileSize = 0;
  String _fileExtension = '';
 


  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializeAudio();
    
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });
  }

  Future<void> _initializeAudio() async {
    try {
      final file = File(widget.audioPath);
      if (await file.exists()) {
        // Use custom name if available, otherwise use filename
        _fileName = widget.customName ?? path.basenameWithoutExtension(widget.audioPath);
        _fileExtension = path.extension(widget.audioPath).replaceFirst('.', '').toUpperCase();
        _dateAdded = await file.lastModified();
        _fileSize = await file.length();
        
        await _audioPlayer.setSourceDeviceFile(widget.audioPath);
        
        if (mounted) setState(() {});
      }
    } catch (e) {
      print('Error initializing audio: $e');
    }
  }


  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    } catch (e) {
      print('Error toggling play/pause: $e');
    }
  }

  Future<void> _seekForward() async {
    final newPosition = _position + const Duration(seconds: 10);
    if (newPosition < _duration) {
      await _audioPlayer.seek(newPosition);
    }
  }

  Future<void> _seekBackward() async {
    final newPosition = _position - const Duration(seconds: 10);
    if (newPosition > Duration.zero) {
      await _audioPlayer.seek(newPosition);
    } else {
      await _audioPlayer.seek(Duration.zero);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes);
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  void _showAudioInfo() {
    final nameController = TextEditingController(text: _fileName);
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Audio Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 80,
                    child: Text(
                      'Name:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: CupertinoTextField(
                      controller: nameController,
                      style: const TextStyle(fontSize: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: CupertinoColors.separator,
                            width: 0.5,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 80,
                    child: Text(
                      'Date:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatDate(_dateAdded),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 80,
                    child: Text(
                      'Duration:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatDuration(_duration),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 80,
                    child: Text(
                      'Type:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '$_fileExtension Audio',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 80,
                    child: Text(
                      'Size:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _formatFileSize(_fileSize),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Save'),
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty && newName != _fileName) {
                setState(() => _fileName = newName);
                widget.onRename?.call(widget.audioPath, newName);
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Remove Audio'),
        content: const Text('Are you sure you want to remove this audio file?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Remove'),
            onPressed: () {
              Navigator.of(context).pop();
              widget.onRemove(widget.audioPath);
            },
          ),
        ],
      ),
    );
  }

  void _onProgressBarTap(TapDownDetails details) async {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localOffset = box.globalToLocal(details.globalPosition);
    
    final double progressBarStart = 12.0;
    final double progressBarWidth = 280.0 - 24.0;
    final double tapPosition = localOffset.dx - progressBarStart;
    final double progress = (tapPosition / progressBarWidth).clamp(0.0, 1.0);
    
    final Duration newPosition = Duration(
      milliseconds: (_duration.inMilliseconds * progress).round(),
    );
    
    await _audioPlayer.seek(newPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground.resolveFrom(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isSelected 
              ? CupertinoColors.activeBlue 
              : CupertinoColors.separator.resolveFrom(context),
          width: widget.isSelected ? 2 : 1,
        ),
        boxShadow: widget.isDragging ? [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6.resolveFrom(context),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.music_note,
                  size: 16,
                  color: CupertinoColors.systemBlue,
                ),
                
                const SizedBox(width: 8),
                
                Expanded(
                  child: GestureDetector(
                    onTap: widget.isDragging ? null : _showAudioInfo,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fileName.isNotEmpty ? _fileName : 'Audio File',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_formatFileSize(_fileSize)} • ${_formatDuration(_duration)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel.resolveFrom(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                if (!widget.isDragging) ...[
                  // Info button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 30,
                    onPressed: _showAudioInfo,
                    child: const Icon(
                      CupertinoIcons.info,
                      size: 16,
                      color: CupertinoColors.systemBlue,
                    ),
                  ),
                  
                  // Remove button
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 30,
                    onPressed: _showRemoveDialog,
                    child: const Icon(
                      CupertinoIcons.xmark,
                      size: 16,
                      color: CupertinoColors.systemRed,
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Controls Section (disabled during drag)
          Container(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // Duration info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                // Progress bar
                GestureDetector(
                  onTapDown: widget.isDragging ? null : _onProgressBarTap,
                  child: Container(
                    height: 20,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: LinearProgressIndicator(
                      value: _duration.inMilliseconds > 0 
                          ? _position.inMilliseconds / _duration.inMilliseconds 
                          : 0,
                      backgroundColor: CupertinoColors.systemGrey4.resolveFrom(context),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isDragging 
                            ? CupertinoColors.systemGrey2.resolveFrom(context)
                            : CupertinoColors.systemBlue
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 40,
                      onPressed: widget.isDragging ? null : _seekBackward,
                      child: Icon(
                        CupertinoIcons.gobackward_10,
                        size: 24,
                        color: widget.isDragging 
                            ? CupertinoColors.systemGrey2.resolveFrom(context)
                            : null,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 40,
                      onPressed: widget.isDragging ? null : _togglePlayPause,
                      child: Icon(
                        _isPlaying 
                            ? CupertinoIcons.pause_circle_fill 
                            : CupertinoIcons.play_circle_fill,
                        size: 32,
                        color: widget.isDragging 
                            ? CupertinoColors.systemGrey2.resolveFrom(context)
                            : CupertinoColors.systemBlue,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 40,
                      onPressed: widget.isDragging ? null : _seekForward,
                      child: Icon(
                        CupertinoIcons.goforward_10,
                        size: 24,
                        color: widget.isDragging 
                            ? CupertinoColors.systemGrey2.resolveFrom(context)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
