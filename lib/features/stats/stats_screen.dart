import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:noteon/core/l10n/app_localizations.dart';
import 'package:noteon/data/models/task_model.dart';
import 'package:noteon/data/providers/repository_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final user =
        ref.watch(authStateProvider).valueOrNull ??
        ref.read(authRepositoryProvider).currentUser;
    final uid = user?.uid ?? 'guest_user';

    final tasksStream = ref.watch(tasksRepositoryProvider).watchTasks(uid: uid);

    return Scaffold(
      appBar: AppBar(title: Text(l10n?.statistics ?? 'Productivity & Stats')),
      body: SafeArea(
        child: StreamBuilder<List<TaskModel>>(
          stream: tasksStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final tasks = snapshot.data ?? [];
            final now = DateTime.now();
            final todayMidnight = DateTime(now.year, now.month, now.day);
            final weekAgo = todayMidnight.subtract(const Duration(days: 7));

            // Completed this week
            final completedThisWeek = tasks.where((t) {
              return t.isDone &&
                  t.completedAt != null &&
                  t.completedAt!.isAfter(weekAgo);
            }).length;

            // Overdue tasks
            final overdueCount = tasks.where((t) {
              return !t.isDone &&
                  t.dueAt != null &&
                  t.dueAt!.isBefore(todayMidnight);
            }).length;

            // Total time spent in focus timer
            final totalFocusMinutes =
                tasks.fold<int>(0, (sum, t) => sum + t.timeSpentSec) ~/ 60;

            // Completed tasks distribution across last 7 days for the chart
            final dayCounts = List.generate(7, (i) {
              final day = todayMidnight.subtract(Duration(days: 6 - i));
              final nextDay = day.add(const Duration(days: 1));
              return tasks.where((t) {
                return t.isDone &&
                    t.completedAt != null &&
                    t.completedAt!.isAfter(day) &&
                    t.completedAt!.isBefore(nextDay);
              }).length;
            });

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Summary KPI Cards Row
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        theme: theme,
                        icon: Icons.check_circle_rounded,
                        color: Colors.green,
                        title: l10n?.completedThisWeek ?? 'This Week',
                        value: '$completedThisWeek',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
                        theme: theme,
                        icon: Icons.warning_amber_rounded,
                        color: Colors.red,
                        title: l10n?.overdueTasks ?? 'Overdue',
                        value: '$overdueCount',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildKpiCard(
                        theme: theme,
                        icon: Icons.local_fire_department_rounded,
                        color: Colors.orange,
                        title: l10n?.currentStreak ?? 'Streak',
                        value: '5 ${l10n?.days ?? "days"}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildKpiCard(
                        theme: theme,
                        icon: Icons.timer_outlined,
                        color: Colors.blue,
                        title: 'Focus Time',
                        value: '${totalFocusMinutes}m',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Productivity Weekly Chart Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tasks Completed (Last 7 Days)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY:
                                  (dayCounts.reduce((a, b) => a > b ? a : b) +
                                          2)
                                      .toDouble(),
                              barTouchData: BarTouchData(enabled: true),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final idx = value.toInt();
                                      if (idx < 0 || idx >= 7) {
                                        return const SizedBox.shrink();
                                      }
                                      final day = todayMidnight.subtract(
                                        Duration(days: 6 - idx),
                                      );
                                      const days = [
                                        'M',
                                        'T',
                                        'W',
                                        'T',
                                        'F',
                                        'S',
                                        'S',
                                      ];
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(
                                          days[day.weekday - 1],
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                for (var i = 0; i < 7; i++)
                                  BarChartGroupData(
                                    x: i,
                                    barRods: [
                                      BarChartRodData(
                                        toY: dayCounts[i].toDouble(),
                                        color: theme.colorScheme.primary,
                                        width: 18,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required ThemeData theme,
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
