// lib/screens/notes_list_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../providers/note_provider.dart';
import 'note_edit_screen.dart';

class NotesListScreen extends StatelessWidget {
  const NotesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: Text('Notes',

          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 30,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),

            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30,
                color: const Color.fromARGB(255, 97, 98, 99))),

        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.of(context).push(CupertinoPageRoute(
              builder: (context) => const NoteEditScreen(),
            ));
          },
          child: Icon(CupertinoIcons.add),
        ),
      ),
      child: Consumer<NoteProvider>(
        builder: (context, noteProvider, child) {
          if (noteProvider.notes.isEmpty) {
            return Center(
              child: Text(
                'No notes yet. Add one!',
                style: TextStyle(
                  fontSize: 16,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            );
          }

          final groupedNotes = noteProvider.groupedNotes;
          final monthKeys = groupedNotes.keys.toList();

          // Sort month keys: PINNED first, then chronologically (newest first)
          monthKeys.sort((a, b) {
            if (a == 'PINNED' && b != 'PINNED') return -1;
            if (a != 'PINNED' && b == 'PINNED') return 1;
            if (a == 'PINNED' && b == 'PINNED') return 0;

            DateTime dateA = DateFormat('MMM yyyy').parse(a);
            DateTime dateB = DateFormat('MMM yyyy').parse(b);
            return dateB.compareTo(dateA);
          });

          return ListView.builder(
            padding: EdgeInsets.fromLTRB(16, 110, 16, 16),
            itemCount: _calculateTotalItems(noteProvider, monthKeys),
            itemBuilder: (context, index) {
              return _buildItem(context, noteProvider, monthKeys, index);
            },
          );
        },
      ),
    );
  }

  int _calculateTotalItems(NoteProvider noteProvider, List<String> monthKeys) {
    int totalItems = 0;
    for (String monthKey in monthKeys) {
      totalItems++; // Header
      if (noteProvider.isSectionExpanded(monthKey)) {
        totalItems += noteProvider.groupedNotes[monthKey]!.length; // Notes
      }
    }
    return totalItems;
  }

  Widget _buildItem(BuildContext context, NoteProvider noteProvider,
      List<String> monthKeys, int index) {
    int currentIndex = 0;

    for (String monthKey in monthKeys) {
      // Check if this is a section header
      if (currentIndex == index) {
        return _buildSectionHeader(context, noteProvider, monthKey);
      }
      currentIndex++;

      // Check if this is within the notes for this section
      if (noteProvider.isSectionExpanded(monthKey)) {
        final notesInSection = noteProvider.groupedNotes[monthKey]!;
        if (index < currentIndex + notesInSection.length) {
          final noteIndex = index - currentIndex;
          final note = notesInSection[noteIndex];
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _buildNoteCard(context, noteProvider, note),
          );
        }
        currentIndex += notesInSection.length;
      }
    }

    return Container(); // Fallback
  }

  Widget _buildSectionHeader(
      BuildContext context, NoteProvider noteProvider, String monthKey) {
    final isExpanded = noteProvider.isSectionExpanded(monthKey);
    final notesCount = noteProvider.groupedNotes[monthKey]!.length;
    final isPinnedSection = monthKey == 'PINNED';

    return Padding(
      padding: EdgeInsets.only(bottom: 8, top: 16),
      child: Container(
        decoration: BoxDecoration(
          color: isPinnedSection
              ? CupertinoColors.systemOrange.withOpacity(0.1)
              : CupertinoColors.systemGrey6.resolveFrom(context),
          borderRadius: BorderRadius.circular(8),
        ),
        child: CupertinoButton(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onPressed: () => noteProvider.toggleSection(monthKey),
          child: Row(
            children: [
              Icon(
                isExpanded
                    ? CupertinoIcons.chevron_down
                    : CupertinoIcons.chevron_right,
                size: 16,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              SizedBox(width: 8),
              if (isPinnedSection) ...[
                Icon(
                  CupertinoIcons.pin_fill,
                  size: 16,
                  color: CupertinoColors.systemOrange,
                ),
                SizedBox(width: 6),
              ],
              Text(
                monthKey,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isPinnedSection
                      ? CupertinoColors.systemOrange
                      : CupertinoColors.label.resolveFrom(context),
                ),
              ),
              Spacer(),
              Text(
                '$notesCount note${notesCount == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteCard(
      BuildContext context, NoteProvider noteProvider, Note note) {
    return Dismissible(
      key: Key(note.id.toString()),
      background: Container(
        margin: EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              note.isPinned ? CupertinoIcons.pin_slash : CupertinoIcons.pin,
              color: CupertinoColors.white,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              note.isPinned ? 'Unpin' : 'Pin',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: CupertinoColors.destructiveRed,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.delete,
              color: CupertinoColors.white,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          return await showCupertinoDialog<bool>(

            context: context,
            builder: (BuildContext ctx) {
              return CupertinoAlertDialog(
                title: Text('Delete Note'),
                content: Text('Are you sure you want to delete this note? This action cannot be undone.'),
                actions: [
                  CupertinoDialogAction(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Cancel'),
                  ),
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: Text('Delete'),
                  ),
                ],
              );
            },
          ) ?? false;

                context: context,
                builder: (BuildContext ctx) {
                  return CupertinoAlertDialog(
                    title: const Text('Delete Note'),
                    content: const Text(
                        'Are you sure you want to delete this note? This action cannot be undone.'),
                    actions: [
                      CupertinoDialogAction(
                        child: const Text('Cancel'),
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        child: const Text('Delete'),
                        onPressed: () => Navigator.of(ctx).pop(true),
                      ),
                    ],
                  );
                },
              ) ??
              false;

        } else if (direction == DismissDirection.startToEnd) {
          noteProvider.togglePinNote(note);
          return false;
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          noteProvider.deleteNote(note.id!);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: CupertinoListTile(
          padding: EdgeInsets.all(20),
          title: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              note.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: CupertinoColors.label.resolveFrom(context),
              ),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.label.resolveFrom(context),
                ),
              ),
              SizedBox(height: 8),
              Text(
                DateFormat.yMMMd().format(note.createdAt),
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          onTap: () {
            Navigator.of(context).push(CupertinoPageRoute(
              builder: (context) => NoteEditScreen(note: note),
            ));
          },
        ),
      ),
    );
  }
}
