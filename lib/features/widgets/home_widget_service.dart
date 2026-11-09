import 'package:home_widget/home_widget.dart';
import 'package:noteon/data/models/task_model.dart';

class HomeWidgetService {
  static const String appWidgetProvider = 'TodayTasksWidgetProvider';
  static const String groupId = 'group.com.example.noteon';

  static Future<void> updateTodayTasksWidget(List<TaskModel> todayTasks) async {
    try {
      final count = todayTasks.where((t) => !t.isDone).length;
      final topTaskTitle = todayTasks.isNotEmpty
          ? todayTasks.first.title
          : 'No tasks today 🎉';

      await HomeWidget.saveWidgetData<int>('today_tasks_count', count);
      await HomeWidget.saveWidgetData<String>('top_task_title', topTaskTitle);
      await HomeWidget.updateWidget(
        name: appWidgetProvider,
        iOSName: 'NoteOnWidget',
      );
    } catch (_) {
      // Home widget might not be placed on home screen yet
    }
  }
}
