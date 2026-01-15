import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../../core/models/task_model.dart';

class KanbanListView extends StatelessWidget {
  final List<Task> tasks;
  final Function(Task)? onCardTap;

  const KanbanListView({super.key, required this.tasks, this.onCardTap});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(child: Text("No tasks found", style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final task = tasks[index];
        return InkWell(
          onTap: () => onCardTap?.call(task),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                // Status Indicator
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getStatusColor(task.status),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if ((task.description ?? '').isNotEmpty)
                        Text(
                          task.description!,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildBadge(task.status, _getStatusColor(task.status)),
                          const SizedBox(width: 8),
                          if (task.priority != null)
                             _buildBadge(task.priority!, Colors.grey.shade400, isOutline: true),
                        ],
                      )
                    ],
                  ),
                ),
                
                // Meta
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                     if (task.assignee != null)
                       CircleAvatar(
                         radius: 12,
                         backgroundColor: Colors.blue.shade100,
                         child: Text(
                           task.assignee.toString().substring(0, 1).toUpperCase(),
                           style: TextStyle(fontSize: 10, color: Colors.blue.shade800),
                         ),
                       ),
                     const SizedBox(height: 8),
                     if (task.dueDate != null)
                       Row(
                         children: [
                           HeroIcon(HeroIcons.calendar, size: 14, color: Colors.grey.shade500),
                           const SizedBox(width: 4),
                           Text(
                             "${task.dueDate!.day}/${task.dueDate!.month}",
                             style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                           ),
                         ],
                       )
                   ],
                 )
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'todo': return Colors.blue;
      case 'inprogress': return Colors.orange;
      case 'done': return Colors.green;
      default: return Colors.grey;
    }
  }

  Widget _buildBadge(String text, Color color, {bool isOutline = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isOutline ? Colors.transparent : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: isOutline ? Border.all(color: color) : null,
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isOutline ? color : color, // If outline, text is color. If fill, text is usually same base color or dark.
          // Let's simplified opacity handling
        ).copyWith(color: isOutline ? color : _darken(color)),
      ),
    );
  }
  
  Color _darken(Color c, [int percent = 40]) {
      assert(1 <= percent && percent <= 100);
      var f = 1 - percent / 100;
      return Color.fromARGB(
          c.alpha,
          (c.red * f).round(),
          (c.green * f).round(),
          (c.blue * f).round()
      );
  }
}
