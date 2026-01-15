import 'package:flutter/material.dart';
import '../../core/models/task_model.dart';
import 'kanban_column.dart';

class KanbanBoard extends StatelessWidget {
  final List<Task> tasks;
  final List<dynamic> columns;
  final Function(Task, String) onTaskStatusChanged;
  final Function(Task)? onCardTap;
  final Function(String)? onAddTap;

  const KanbanBoard({
    super.key,
    required this.tasks,
    required this.columns,
    required this.onTaskStatusChanged,
    this.onCardTap,
    this.onAddTap,
  });

  List<Task> _getTasksByStatus(String status) {
    return tasks.where((t) => t.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800; // Treat tablets as mobile-ish for horizontal scrolling
    final columnWidth = isMobile ? screenWidth * 0.85 : 300.0;
    
    // Use dynamic columns or fallback
    final columnsData = columns.isNotEmpty ? columns : [
      {'title': 'To Do', 'status': 'todo'},
      {'title': 'In Progress', 'status': 'inprogress'},
      {'title': 'Done', 'status': 'done'}, // Reduced default set
    ];

    if (isMobile) {
       return ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const PageScrollPhysics(), // Snap to columns
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: columnsData.length,
          itemBuilder: (context, index) {
            final col = columnsData[index];
            final title = col['title']?.toString() ?? 'Untitled';
            final status = col['status']?.toString() ?? '';
            return Padding(
              padding: EdgeInsets.only(right: index == columnsData.length - 1 ? 0 : 16),
              child: KanbanColumn(
                title: title,
                status: status,
                tasks: _getTasksByStatus(status),
                onDrop: onTaskStatusChanged,
                onCardTap: onCardTap,
                onAddTap: onAddTap,
                width: columnWidth,
              ),
            );
          },
        );
    } else {
      // Desktop: Standard Row
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columnsData.map((col) {
               final title = col['title']?.toString() ?? 'Untitled';
               final status = col['status']?.toString() ?? '';
               return KanbanColumn(
                 title: title,
                 status: status,
                 tasks: _getTasksByStatus(status),
                 onDrop: onTaskStatusChanged,
                 onCardTap: onCardTap,
                 onAddTap: onAddTap,
                 width: 300, // Fixed width for desktop
               );
          }).toList(),
        ),
      );
    }
  }
}
