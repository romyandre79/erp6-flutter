import 'dart:convert';

class Project {
  final String id;
  final String name;
  final String? description;
  final String? color;
  final bool archived;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<dynamic>? columns;
  final List<dynamic>? members;

  Project({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.archived = false,
    this.startDate,
    this.endDate,
    this.columns,
    this.members,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    var cols = json['columns'];
    if (cols is String) {
      try {
        cols = jsonDecode(cols);
      } catch (e) {
        cols = [];
      }
    }
    
    return Project(
      id: json['projectid']?.toString() ?? '',
      name: json['name'] ?? 'Untitled Project',
      description: json['description'],
      color: json['color'],
      archived: json['archived'] == true || json['archived'] == 1 || json['archived'] == '1',
      startDate: json['startdate'] != null ? DateTime.tryParse(json['startdate']) : null,
      endDate: json['enddate'] != null ? DateTime.tryParse(json['enddate']) : null,
      columns: cols is List ? cols : [],
      members: json['members'] is List ? json['members'] : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectid': id,
      'name': name,
      'description': description,
      'color': color,
      'archived': archived,
      'startdate': startDate?.toIso8601String(),
      'enddate': endDate?.toIso8601String(),
      'columns': columns,
      'members': members,
    };
  }
}
