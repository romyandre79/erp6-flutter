import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../core/models/project_model.dart';
import '../core/models/task_model.dart';

class ProjectService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();
  final String _baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:8080';

  ProjectService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.validateStatus = (status) => status! < 500;
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<dynamic> _executeFlow(Map<String, String> fields, {Map<String, dynamic>? extraArgs}) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception('No authentication token found');

      final formData = FormData.fromMap({
        'menu': 'admin',
        ...fields,
        if (extraArgs != null) ...extraArgs.map((key, value) => MapEntry(key, value.toString())),
      });

      String endpoint = '/api/admin/execute-flow';
      
      // Fix potential double /api issue
      // If baseUrl ends with /api, we should query /admin/execute-flow instead 
      // OR assuming baseUrl is the root API url.
      
      // Let's log the effective URL for debugging
      print('Base URL: ${_dio.options.baseUrl}');
      
      // Smart fix: if _dio.options.baseUrl has /api and endpoint has /api, strip one.
      if (_dio.options.baseUrl.endsWith('/api') && endpoint.startsWith('/api')) {
         endpoint = '/admin/execute-flow';
      }

      print('Requesting: $endpoint');

      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      print('ExecuteFlow Response format: ${response.data.runtimeType}');

      dynamic responseData = response.data;
      if (responseData is String) {
         try {
           if (responseData.trim().isEmpty) {
             print('Empty response string received');
             return [];
           }
           // Print first 500 chars to debug
           print('Attempting to decode string (first 500 chars): ${responseData.substring(0, responseData.length > 500 ? 500 : responseData.length)}');
           
           responseData = jsonDecode(responseData);
         } catch (e) {
           print('Failed to decode string response. Raw content: $responseData');
           // Check if it's likely HTML (common with server errors)
           if (responseData.toString().trim().startsWith('<')) {
             throw Exception('Server returned HTML instead of JSON. Check API URL or authentication.');
           }
           throw Exception('Invalid JSON response from server: $e');
         }
      }

      // Handle Map response (wrapped)
      if (responseData is Map) {
        if (responseData['code'] == 200) {
          return responseData['data'];
        } else {
          throw Exception('Flow execution failed: ${responseData['message'] ?? response.statusMessage}');
        }
      } 
      // Handle List response (direct)
      else if (responseData is List) {
        return responseData;
      }

      throw Exception('Unexpected response format: ${responseData.runtimeType}');
    } catch (e) {
      print('Error executing flow ${fields['flowname']}: $e');
      rethrow;
    }
  }

  Future<List<Project>> fetchProjects() async {
    try {
      print('Fetching projects...');
      final data = await _executeFlow({
        'flowname': 'searchprojects',
        'search': 'true',
        'archived': '0',
      });
      print('FetchProjects Raw Data Type: ${data.runtimeType}');
      // print('FetchProjects Raw Data: $data'); // Comment out if too verbose

      if (data is Map && data.containsKey('data') && data['data'] is List) {
         return (data['data'] as List).map((json) => Project.fromJson(json)).toList();
      } else if (data is List) {
         return data.map((json) => Project.fromJson(json)).toList();
      }
      throw Exception('Create Project flow returned unexpected data format: $data');
    } catch (e) {
      print('Error fetching projects: $e');
      rethrow; // Let UI handle it
    }
  }

  Future<List<Task>> fetchTasks(String projectId) async {
    try {
      print('Fetching tasks for project: $projectId');
      final data = await _executeFlow({
        'flowname': 'getcards',
        'projectid': projectId,
        'search': 'true',
      });
      
      // print('FetchTasks Raw Data: $data'); // Debug if needed

      // Check structure: getcards returns { code: 200, data: { data: [...] } } usually
      if (data is Map && data.containsKey('data') && data['data'] is List) {
         return (data['data'] as List).map((json) => Task.fromJson(json)).toList();
       } else if (data is List) {
        return data.map((json) => Task.fromJson(json)).toList();
       }
      return [];
    } catch (e) {
      print('Error fetching tasks: $e');
      rethrow; // Let UI handle it
    }
  }

  Future<List<dynamic>> fetchProjectMembers(String projectId) async {
    try {
      print('Fetching members for project: $projectId');
      final data = await _executeFlow({
        'flowname': 'getprojectmembers',
        'projectid': projectId,
        'search': 'true',
      });
      
      print('FetchMembers Raw Data Type: ${data.runtimeType}');

      if (data is Map && data.containsKey('data') && data['data'] is List) {
         return data['data'] as List;
       } else if (data is List) {
          return data;
       }
      return [];
    } catch (e) {
      print('Error fetching project members: $e');
      // Return empty list instead of throwing to avoid blocking UI
      return [];
    }
  }
  
  Future<void> updateTaskStatus(Task task, String newStatus) async {
    try {
        await _executeFlow({
          'flowname': 'modifcard',
          'search': 'false',
          'cardid': task.id,
          'projectid': task.projectId, // Now available in Task model
          'status': newStatus,
          'title': task.title, // Required fields likely needed to avoid clearing
          'description': task.description ?? '',
          'priority': task.priority ?? 'medium',
          'assignee': _formatAssigneeForSave(task.assignee),
        }, extraArgs: {
          'tags': jsonEncode(task.tags),
        });
    } catch (e) {
       print('Error updating task status: $e');
       rethrow;
    }
  }

  Future<void> updateTaskPosition(String taskId, String projectId, int newPosition, Task task) async {
      try {
          await _executeFlow({
            'flowname': 'modifcard',
            'search': 'false',
            'cardid': taskId,
            'projectid': projectId,
            'position': newPosition.toString(),
            'status': task.status,
            'title': task.title,
            'description': task.description ?? '',
             'priority': task.priority ?? 'medium',
             'assignee': _formatAssigneeForSave(task.assignee),
          },extraArgs: {
             'tags': jsonEncode(task.tags),
          });
      } catch (e) {
          print('Error updating task position: $e');
      }
  }

  String _formatAssigneeForSave(dynamic assignee) {
      if (assignee == null) return '';
      if (assignee is String) return assignee;
      if (assignee is Map) {
          return assignee['id']?.toString() ?? assignee['userid']?.toString() ?? assignee['email']?.toString() ?? '';
      }
      return assignee.toString();
  }

  Future<void> saveTask(Task task) async {
      try {
          final isEdit = task.id.isNotEmpty;
          await _executeFlow({
            'flowname': 'modifcard',
            'search': 'false',
            if (isEdit) 'cardid': task.id,
            'projectid': task.projectId,
            'title': task.title,
            'description': task.description ?? '',
            'status': task.status,
            'priority': task.priority ?? 'medium',
            'startdate': task.startDate?.toIso8601String() ?? '',
            'enddate': task.dueDate?.toIso8601String() ?? '',
            'assignee': _formatAssigneeForSave(task.assignee),
          }, extraArgs: {
            'tags': jsonEncode(task.tags),
          });
      } catch (e) {
         print('Error saving task: $e');
         rethrow;
      }
  }

  Future<void> saveProject(Project project) async {
    try {
        final isEdit = project.id.isNotEmpty;
        await _executeFlow({
           'flowname': 'modifproject',
           'search': 'false',
           if (isEdit) 'projectid': project.id,
           'name': project.name,
           'description': project.description ?? '',
           // Defaulting color if null, matching backend expectations or passing empty
           'color': project.color ?? '#3b82f6', 
           // TODO: Add company selection in UI. For now, hardcode or use a default if available
           'companyid': '1', 
           'startdate': project.startDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
           'enddate': project.endDate?.toIso8601String() ?? DateTime.now().add(const Duration(days: 30)).toIso8601String(),
           'columns': jsonEncode(project.columns ?? [
              {'title': 'To Do', 'status': 'todo'},
              {'title': 'In Progress', 'status': 'inprogress'},
              {'title': 'Done', 'status': 'done'},
           ]),
        });
    } catch (e) {
       print('Error saving project: $e');
       rethrow;
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
        await _executeFlow({
           'flowname': 'deleteproject',
           'search': 'false', // Assuming generic param, though flow might ignore
           'projectid': projectId,
        });
    } catch (e) {
       print('Error deleting project: $e');
       rethrow;
    }
  }
}
