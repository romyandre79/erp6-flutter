import 'dart:convert';

class Task {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  String status;
  final String? priority;
  final dynamic assignee; // Changed to dynamic to support object or string
  final DateTime? startDate; // Added for Gantt
  final DateTime? dueDate;
  final List<String> tags;

  Task({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.status,
    this.priority,
    this.assignee,
    this.startDate,
    this.dueDate,
    this.tags = const [],
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    
    // Helper to parse tags which might be a JSON string or List
    List<String> parseTags(dynamic tags) {
      if (tags == null) return [];
      if (tags is List) return tags.map((e) => e.toString()).toList();
      if (tags is String && tags.isNotEmpty) {
        try {
           final parsed = jsonDecode(tags);
           if (parsed is List) return parsed.map((e) => e.toString()).toList();
        } catch (e) {
           return tags.split(',').map((e) => e.trim()).toList();
        }
      }
      return [];
    }

    return Task(
      id: json['cardid']?.toString() ?? json['id']?.toString() ?? '',
      projectId: json['projectid']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Task',
      description: json['description']?.toString(),
      status: json['status']?.toString() ?? 'todo',
      priority: json['priority']?.toString(),
      assignee: json['assignee'],
      startDate: json['startdate'] != null ? DateTime.tryParse(json['startdate'].toString()) : null,
      dueDate: json['duedate'] != null ? DateTime.tryParse(json['duedate'].toString()) : (json['enddate'] != null ? DateTime.tryParse(json['enddate'].toString()) : null),
      tags: parseTags(json['tags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardid': id,
      'projectid': projectId,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'assignee': assignee,
      'startdate': startDate?.toIso8601String(),
      'duedate': dueDate?.toIso8601String(),
      'tags': tags,
    };
  }
}
