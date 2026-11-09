import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/features/tasks/quick_add_dialog.dart';

class MainShellScreen extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShellScreen({super.key, required this.navigationShell});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen>
    with SingleTickerProviderStateMixin {
  bool _isSpeedDialOpen = false;
  late AnimationController _animController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleSpeedDial() {
    setState(() {
      _isSpeedDialOpen = !_isSpeedDialOpen;
      if (_isSpeedDialOpen) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  void _closeSpeedDial() {
    if (_isSpeedDialOpen) {
      setState(() {
        _isSpeedDialOpen = false;
        _animController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      body: Stack(
        children: [
          widget.navigationShell,
          // Dim background when speed dial is open
          if (_isSpeedDialOpen)
            GestureDetector(
              onTap: _closeSpeedDial,
              child: Container(color: Colors.black.withValues(alpha: 0.4)),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          _closeSpeedDial();
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.note_alt_outlined),
            selectedIcon: const Icon(Icons.note_alt_rounded),
            label: l10n?.navNotes ?? 'Notes',
          ),
          NavigationDestination(
            icon: const Icon(Icons.check_circle_outline_rounded),
            selectedIcon: const Icon(Icons.check_circle_rounded),
            label: l10n?.navTasks ?? 'Tasks',
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month_rounded),
            label: l10n?.navCalendar ?? 'Calendar',
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_rounded),
            selectedIcon: const Icon(Icons.saved_search_rounded),
            label: l10n?.navSearch ?? 'Search',
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: l10n?.navSettings ?? 'Settings',
          ),
        ],
      ),
      floatingActionButton: _buildSpeedDialFab(theme, l10n),
    );
  }

  Widget _buildSpeedDialFab(ThemeData theme, AppLocalizations? l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Speed dial option: Quick Add (natural language)
        ScaleTransition(
          scale: _expandAnimation,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLabel(l10n?.quickAdd ?? 'Quick Add', theme),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'fab_quick_add',
                  backgroundColor: const Color(0xFFE76F51),
                  foregroundColor: Colors.white,
                  onPressed: () {
                    _closeSpeedDial();
                    QuickAddDialog.show(context);
                  },
                  child: const Icon(Icons.bolt_rounded),
                ),
              ],
            ),
          ),
        ),

        // Speed dial option: New Task
        ScaleTransition(
          scale: _expandAnimation,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLabel(l10n?.newTask ?? 'New Task', theme),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'fab_new_task',
                  backgroundColor: const Color(0xFF4A6572),
                  foregroundColor: Colors.white,
                  onPressed: () {
                    _closeSpeedDial();
                    context.push('/task/new');
                  },
                  child: const Icon(Icons.add_task_rounded),
                ),
              ],
            ),
          ),
        ),

        // Speed dial option: New Checklist
        ScaleTransition(
          scale: _expandAnimation,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLabel(l10n?.newChecklist ?? 'New Checklist', theme),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'fab_new_checklist',
                  backgroundColor: const Color(0xFF2A9D8F),
                  foregroundColor: Colors.white,
                  onPressed: () {
                    _closeSpeedDial();
                    context.push('/note/new?type=checklist');
                  },
                  child: const Icon(Icons.checklist_rounded),
                ),
              ],
            ),
          ),
        ),

        // Speed dial option: New Note
        ScaleTransition(
          scale: _expandAnimation,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLabel(l10n?.newNote ?? 'New Note', theme),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  heroTag: 'fab_new_note',
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onSecondary,
                  onPressed: () {
                    _closeSpeedDial();
                    context.push('/note/new?type=text');
                  },
                  child: const Icon(Icons.edit_note_rounded),
                ),
              ],
            ),
          ),
        ),

        // Primary Speed Dial Button
        FloatingActionButton(
          heroTag: 'fab_main_speed_dial',
          onPressed: _toggleSpeedDial,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          child: AnimatedRotation(
            turns: _isSpeedDialOpen ? 0.375 : 0.0, // Rotate 135 deg to make 'X'
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.add_rounded, size: 28),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
