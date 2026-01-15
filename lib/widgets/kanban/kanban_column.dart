import 'package:flutter/material.dart';
import '../../core/models/task_model.dart';
import 'kanban_card.dart';

class KanbanColumn extends StatelessWidget {
  final String title;
  final String status;
  final List<Task> tasks;
  final Function(Task, String) onDrop; // Task, NewStatus
  final Function(Task)? onCardTap;
  final Function(String)? onAddTap; // Status
  final double width;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.status,
    required this.tasks,
    required this.onDrop,
    this.onCardTap,
    this.onAddTap,
    this.width = 300,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tasks.length.toString(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => onAddTap?.call(status),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
          ),
          
          // List / DragTarget
          Expanded(
            child: DragTarget<Task>(
              onWillAccept: (data) => true,
              onAccept: (task) {
                onDrop(task, status);
              },
              builder: (context, candidateData, rejectedData) {
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Draggable<Task>(
                      data: task,
                      feedback: SizedBox(
                        width: 280,
                        child: Opacity(
                          opacity: 0.8,
                          child: KanbanCard(task: task),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.4,
                        child: KanbanCard(task: task),
                      ),
                      child: KanbanCard(
                        task: task,
                        onTap: () => onCardTap?.call(task),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
