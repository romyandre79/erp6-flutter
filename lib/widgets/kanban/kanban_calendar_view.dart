import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/task_model.dart';

class KanbanCalendarView extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task)? onCardTap;

  const KanbanCalendarView({super.key, required this.tasks, this.onCardTap});

  @override
  State<KanbanCalendarView> createState() => _KanbanCalendarViewState();
}

class _KanbanCalendarViewState extends State<KanbanCalendarView> {
  DateTime _focusedDay = DateTime.now();

  List<Task> _getTasksForDay(DateTime day) {
    return widget.tasks.where((task) {
      if (task.dueDate == null) return false;
      return isSameDay(task.dueDate!, day);
    }).toList();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + offset, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_focusedDay.year, _focusedDay.month);
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final startingWeekday = firstDayOfMonth.weekday; // 1=Mon, 7=Sun.
    // Adjust to standard Sun=0 or Sun=7 convention. Material DateUtils uses Mon=1.
    // Let's assume Sun-Sat grid.
    // If weekday is 1 (Mon), and we want Sun start, we need 1 empty, so offset is weekday.
    // Actually standard is usually Mon start in business, but let's do Sun start.
    // Sun=7 in DateTime.
    final offset = (startingWeekday % 7); 

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(onPressed: () => _changeMonth(-1), icon: const Icon(Icons.chevron_left)),
              Text(
                DateFormat('MMMM yyyy').format(_focusedDay),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(onPressed: () => _changeMonth(1), icon: const Icon(Icons.chevron_right)),
            ],
          ),
        ),
        
        // Days Header
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text('Sun'), Text('Mon'), Text('Tue'), Text('Wed'), Text('Thu'), Text('Fri'), Text('Sat'),
          ],
        ),
        const SizedBox(height: 8),
        
        // Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.8,
            ),
            itemCount: daysInMonth + offset,
            itemBuilder: (context, index) {
              if (index < offset) return const SizedBox();
              
              final dayNum = index - offset + 1;
              final currentDay = DateTime(_focusedDay.year, _focusedDay.month, dayNum);
              final tasksForDay = _getTasksForDay(currentDay);
              final isToday = isSameDay(currentDay, DateTime.now());

              return GestureDetector(
                onTap: () {
                    // Show tasks dialog if any
                    if (tasksForDay.isNotEmpty) {
                        _showTasksDialog(context, currentDay, tasksForDay);
                    }
                },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday ? Colors.blue.withOpacity(0.1) : Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          '$dayNum',
                          style: TextStyle(
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday ? Colors.blue : Colors.black,
                              fontSize: 12
                          ),
                        ),
                      ),
                      if (tasksForDay.isNotEmpty)
                        Expanded(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${tasksForDay.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showTasksDialog(BuildContext context, DateTime date, List<Task> tasks) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(DateFormat('MMM d, y').format(date)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              return ListTile(
                title: Text(task.title),
                subtitle: Text(task.status),
                leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100, 
                    radius: 10,
                ),
                onTap: () {
                    Navigator.pop(context);
                    widget.onCardTap?.call(task);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
        ],
      ),
    );
  }
}
