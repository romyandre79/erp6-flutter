import 'package:flutter/material.dart';
import '../../core/models/task_model.dart';
import 'package:heroicons/heroicons.dart';

class KanbanCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;

  const KanbanCard({super.key, required this.task, this.onTap});

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
      case 'urgent':
        return Colors.red.shade100;
      case 'medium':
        return Colors.amber.shade100;
      case 'low':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getPriorityTextColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
      case 'urgent':
        return Colors.red.shade800;
      case 'medium':
        return Colors.amber.shade800;
      case 'low':
        return Colors.green.shade800;
      default:
        return Colors.grey.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Priority
            if (task.priority != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  task.priority!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getPriorityTextColor(task.priority),
                  ),
                ),
              ),
            
            // Title
            Text(
              task.title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: 12),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 // Assignee (Avatar Helper needed in future, using Icon for now)
                 if (task.assignee != null)
                   Row(
                     children: [
                        const HeroIcon(HeroIcons.userCircle, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          task.assignee!.toString(),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                     ],
                   ),
                 
                 // Due Date
                 if (task.dueDate != null)
                   Row(
                     children: [
                        const HeroIcon(HeroIcons.calendar, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          "${task.dueDate!.day}/${task.dueDate!.month}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                     ],
                   )
              ],
            )
          ],
        ),
      ),
    );
  }
}
