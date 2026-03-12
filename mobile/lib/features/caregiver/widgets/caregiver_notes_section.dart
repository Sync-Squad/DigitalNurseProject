import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/modern_surface_theme.dart';

class CaregiverNotesSection extends StatefulWidget {
  final String elderId;

  const CaregiverNotesSection({super.key, required this.elderId});

  @override
  State<CaregiverNotesSection> createState() => _CaregiverNotesSectionState();
}

class _CaregiverNotesSectionState extends State<CaregiverNotesSection> {
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Load notes from backend
    // For now, using mock data
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _notes = [
          {
            'id': '1',
            'text': 'Patient seems to be doing well today. Appetite is good.',
            'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
          },
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _addNote() async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Enter your note...',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(textController.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      // TODO: Save note to backend
      setState(() {
        _notes.insert(0, {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'text': result,
          'timestamp': DateTime.now(),
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ModernSurfaceTheme.cardPadding(),
      decoration: ModernSurfaceTheme.glassCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Caregiver Notes',
                style: ModernSurfaceTheme.sectionTitleStyle(context),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addNote,
                tooltip: 'Add Note',
              ),
            ],
          ),
          SizedBox(height: 16.h),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_notes.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24.h),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.note_add,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'No notes yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    TextButton(
                      onPressed: _addNote,
                      child: const Text('Add your first note'),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._notes.map(
              (note) => _NoteItem(
                note: note,
                onDelete: () {
                  setState(() {
                    _notes.removeWhere((n) => n['id'] == note['id']);
                  });
                  // TODO: Delete note from backend
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _NoteItem extends StatelessWidget {
  final Map<String, dynamic> note;
  final VoidCallback onDelete;

  const _NoteItem({required this.note, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final timestamp = note['timestamp'] as DateTime;
    final text = note['text'] as String;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: Theme.of(context).textTheme.bodyMedium),
                SizedBox(height: 8.h),
                Text(
                  DateFormat('MMM d, y • h:mm a').format(timestamp),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
            tooltip: 'Delete note',
          ),
        ],
      ),
    );
  }
}
