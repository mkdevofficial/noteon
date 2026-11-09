import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:noteon/data/models/label_model.dart';
import 'package:noteon/data/models/note_model.dart';
import 'package:noteon/features/settings/app_lock_service.dart';

enum NoteViewMode { list, grid, compact }

class NoteCardWidget extends ConsumerStatefulWidget {
  final NoteModel note;
  final NoteViewMode viewMode;
  final List<LabelModel> allLabels;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onTogglePin;
  final Function(int color) onColorChanged;
  final VoidCallback onTrash;
  final VoidCallback onArchive;

  const NoteCardWidget({
    super.key,
    required this.note,
    required this.viewMode,
    required this.allLabels,
    required this.onTap,
    required this.onLongPress,
    required this.onTogglePin,
    required this.onColorChanged,
    required this.onTrash,
    required this.onArchive,
  });

  @override
  ConsumerState<NoteCardWidget> createState() => _NoteCardWidgetState();
}

class _NoteCardWidgetState extends ConsumerState<NoteCardWidget> {
  bool _isUnlockedLocally = false;

  Future<void> _handleTap() async {
    if (widget.note.lockedLocalOnly && !_isUnlockedLocally) {
      final success = await ref
          .read(appLockProvider.notifier)
          .authenticate(reason: 'Unlock note to view content');
      if (success) {
        setState(() => _isUnlockedLocally = true);
        widget.onTap();
      }
    } else {
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Use note color if custom, otherwise theme card color
    Color cardBg;
    if (widget.note.color != 0xFFFFFFFF && widget.note.color != 0) {
      cardBg = Color(widget.note.color);
    } else {
      cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    }

    final isLightNoteBg =
        ThemeData.estimateBrightnessForColor(cardBg) == Brightness.light;
    final textColor = isLightNoteBg ? Colors.black87 : Colors.white;
    final textSubColor = isLightNoteBg ? Colors.black54 : Colors.white70;

    final noteLabels = widget.allLabels
        .where((l) => widget.note.labelIds.contains(l.id))
        .toList();

    final timeStr = DateFormat('MMM d').format(widget.note.updatedAt);

    if (widget.viewMode == NoteViewMode.compact) {
      return Card(
        color: cardBg,
        child: InkWell(
          onTap: _handleTap,
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                if (widget.note.lockedLocalOnly && !_isUnlockedLocally)
                  Icon(Icons.lock_rounded, size: 18, color: textSubColor)
                else if (widget.note.type == 'checklist')
                  Icon(Icons.checklist_rounded, size: 18, color: textSubColor)
                else
                  Icon(
                    Icons.description_outlined,
                    size: 18,
                    color: textSubColor,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.note.title.isNotEmpty
                        ? widget.note.title
                        : 'Untitled Note',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (widget.note.pinned) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.push_pin_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: TextStyle(fontSize: 12, color: textSubColor),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      color: cardBg,
      child: InkWell(
        onTap: _handleTap,
        onLongPress: widget.onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title & Pin Button
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      widget.note.title.isNotEmpty
                          ? widget.note.title
                          : 'Untitled Note',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.note.lockedLocalOnly)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        size: 18,
                        color: textSubColor,
                      ),
                    ),
                  IconButton(
                    icon: Icon(
                      widget.note.pinned
                          ? Icons.push_pin_rounded
                          : Icons.push_pin_outlined,
                      size: 20,
                      color: widget.note.pinned
                          ? theme.colorScheme.primary
                          : textSubColor,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: widget.onTogglePin,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Content snippet (hidden if locked)
              if (widget.note.lockedLocalOnly && !_isUnlockedLocally) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.lock_rounded, size: 16, color: textSubColor),
                      const SizedBox(width: 6),
                      Text(
                        'Locked Note',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSubColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (widget.note.plainText.isNotEmpty) ...[
                Text(
                  widget.note.plainText,
                  maxLines: widget.viewMode == NoteViewMode.grid ? 6 : 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSubColor,
                    height: 1.4,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Footer: Labels & Date
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final label in noteLabels.take(3))
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Color(label.color).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '#${label.name}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(label.color),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    timeStr,
                    style: TextStyle(fontSize: 11, color: textSubColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
