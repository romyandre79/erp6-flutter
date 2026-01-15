import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/models/task_model.dart';

class KanbanGanttView extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task)? onCardTap;

  const KanbanGanttView({super.key, required this.tasks, this.onCardTap});

  @override
  State<KanbanGanttView> createState() => _KanbanGanttViewState();
}

class _KanbanGanttViewState extends State<KanbanGanttView> {
  final double _dayWidth = 50.0;
  final double _rowHeight = 50.0;
  late DateTime _startDate;
  late DateTime _endDate;
  final int _daysBuffer = 7;

  @override
  void initState() {
    super.initState();
    _calculateRange();
  }

  void _calculateRange() {
    if (widget.tasks.isEmpty) {
      _startDate = DateTime.now().subtract(const Duration(days: 7));
      _endDate = DateTime.now().add(const Duration(days: 7));
      return;
    }

    DateTime min = DateTime.now();
    DateTime max = DateTime.now();

    for (var t in widget.tasks) {
      if (t.dueDate != null) {
        if (t.dueDate!.isBefore(min)) min = t.dueDate!;
        if (t.dueDate!.isAfter(max)) max = t.dueDate!;
      }
    }

    _startDate = min.subtract(Duration(days: _daysBuffer));
    _endDate = max.add(Duration(days: _daysBuffer));
  }

  int _daysBetween(DateTime from, DateTime to) {
    return to.difference(from).inDays;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tasks.isEmpty) {
       return const Center(child: Text("No tasks with dates found", style: TextStyle(color: Colors.grey)));
    }

    final totalDays = _daysBetween(_startDate, _endDate) + 1;
    final totalWidth = totalDays * _dayWidth;
    final totalBodyHeight = widget.tasks.where((t) => t.dueDate != null).length * _rowHeight;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Container(
              height: 40,
              color: Colors.grey.shade100,
              child: Row(
                children: List.generate(totalDays, (index) {
                  final date = _startDate.add(Duration(days: index));
                  return Container(
                    width: _dayWidth,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.grey.shade300)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(DateFormat('E').format(date).substring(0, 1), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        Text('${date.day}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
              ),
            ),
            
            // Body (Stack of Background + Content)
            SizedBox(
              height: totalBodyHeight,
              width: totalWidth,
              child: Stack(
                children: [
                  // 1. Vertical Grid Lines (Background)
                  Row(
                    children: List.generate(totalDays, (index) {
                      return Container(
                        width: _dayWidth,
                        decoration: BoxDecoration(
                          border: Border(right: BorderSide(color: Colors.grey.shade100)),
                        ),
                      );
                    }),
                  ),

                  // 2. Horizontal Lines (Rows)
                  Column(
                    children: List.generate(widget.tasks.where((t) => t.dueDate != null).length, (index) {
                      return Container(
                        height: _rowHeight,
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                        ),
                      );
                    }),
                  ),

                  // 3. Tasks
                  ..._buildTaskBars(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTaskBars() {
    final List<Widget> bars = [];
    int rowIndex = 0;

    for (var task in widget.tasks) {
      if (task.dueDate == null) continue;

      final start = task.dueDate!.subtract(const Duration(days: 2));
      final end = task.dueDate!;
      
      final startOffset = _daysBetween(_startDate, start) * _dayWidth;
      final durationDays = _daysBetween(start, end) + 1;
      final width = durationDays * _dayWidth;
      final topOffset = rowIndex * _rowHeight;

      bars.add(Positioned(
        left: startOffset,
        top: topOffset + 10, // Centered in row (row is 50, bar is 30)
        width: width,
        height: 30,
        child: InkWell(
          onTap: () => widget.onCardTap?.call(task),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade200,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue.shade400),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              task.title,
              style: const TextStyle(fontSize: 12, overflow: TextOverflow.ellipsis),
            ),
          ),
        ),
      ));
      
      rowIndex++;
    }
    return bars;
  }
}
