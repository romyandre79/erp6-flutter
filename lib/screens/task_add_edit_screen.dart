import 'package:flutter/material.dart';
import '../core/models/task_model.dart';
import '../services/project_service.dart';
import 'package:intl/intl.dart';
import 'package:heroicons/heroicons.dart';

class TaskAddEditScreen extends StatefulWidget {
  final Task? task;
  final String projectId;
  final String? initialStatus;
  final List<dynamic> columns; 
  final List<dynamic> members;

  const TaskAddEditScreen({
    super.key, 
    this.task, 
    required this.projectId, 
    this.initialStatus,
    this.columns = const [], 
    this.members = const [],
  });

  @override
  State<TaskAddEditScreen> createState() => _TaskAddEditScreenState();
}

class _TaskAddEditScreenState extends State<TaskAddEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projectService = ProjectService();
  
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  
  String _status = 'todo'; 
  String _priority = 'medium';
  dynamic _assignee; // Can be ID (string/int) or user object
  DateTime? _startDate;
  DateTime? _dueDate;
  bool _isLoading = false;
  late List<dynamic> _validColumns;
  late List<dynamic> _validMembers;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _tagsController = TextEditingController(text: widget.task?.tags.join(', ') ?? '');
    
    // Assignee handling
    _assignee = widget.task?.assignee;
    // Try to map existing assignee to a member ID if possible
    if (_assignee is Map) {
       _assignee = _assignee['id'] ?? _assignee['userid'];
    } else if (_assignee != null) {
       _assignee = _assignee.toString(); 
    }

    // Initialize members list
    _validMembers = List.from(widget.members);

    // Validate if current assignee exists in members list
    if (_assignee != null) {
       final exists = _validMembers.any((m) {
          final mId = _getMemberId(m)?.toString();
          return mId == _assignee.toString();
       });
       
       if (!exists) {
         // Add unknown member to avoid crash
         _validMembers.add({'id': _assignee, 'userid': _assignee, 'name': 'Unknown User ($_assignee)'});
       }
       // Ensure _assignee type matches the dropdown values (String)
       _assignee = _assignee.toString();
    }

    // Ensure we have at least some default columns if none provided
    if (widget.columns.isNotEmpty) {
      _validColumns = widget.columns;
    } else {
      _validColumns = [
        {'title': 'To Do', 'status': 'todo'},
        {'title': 'In Progress', 'status': 'inprogress'},
        {'title': 'Done', 'status': 'done', 'is_completed': true}, // Example structure
      ];
    }
    
    if (widget.task != null) {
      _setInitialStatus(widget.task!.status);
      _priority = widget.task!.priority ?? 'medium';
      _startDate = widget.task!.startDate;
      _dueDate = widget.task!.dueDate;
    } else if (widget.initialStatus != null) {
       _setInitialStatus(widget.initialStatus!);
    } else {
       if (_validColumns.isNotEmpty) {
         _status = _validColumns.first['status']?.toString() ?? 'todo';
       }
    }
  }

  void _setInitialStatus(String status) {
     final exists = _validColumns.any((col) => col['status']?.toString() == status);
     if (exists) {
       _status = status;
     } else {
       _validColumns = List.from(_validColumns)..add({
         'title': status[0].toUpperCase() + status.substring(1), 
         'status': status
       });
       _status = status;
     }
  }

  String _getColumnTitle(String status) {
    final col = _validColumns.firstWhere((c) => c['status'].toString() == status, orElse: () => {'title': status});
    return col['title']?.toString() ?? status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final initialDate = isStart ? (_startDate ?? DateTime.now()) : (_dueDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final tags = _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final task = Task(
        id: widget.task?.id ?? '', 
        projectId: widget.projectId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        status: _status,
        priority: _priority,
        assignee: _assignee, 
        startDate: _startDate,
        dueDate: _dueDate,
        tags: tags,
      );

      await _projectService.saveTask(task);
      
      if (mounted) {
        Navigator.pop(context, true); 
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving task: $e')));
        setState(() => _isLoading = false);
      }
    }
  }
  
  // Helper for member display in dropdown
  String _getMemberName(dynamic member) {
      if (member == null) return 'Unassigned';
      if (member is Map) return member['name'] ?? member['email'] ?? 'Unknown';
      return member.toString();
  }
  
  dynamic _getMemberId(dynamic member) {
      if (member == null) return null;
      if (member is Map) return member['id'] ?? member['userid'];
      return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(''), // Empty title for clean look
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          TextButton(
             onPressed: _isLoading ? null : _saveTask,
             child: Text(_isLoading ? 'Saving...' : 'Save', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          if (widget.task != null)
             IconButton(icon: const HeroIcon(HeroIcons.trash, color: Colors.red), onPressed: () {
                // Delete logic (TODO)
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Delete not implemented in this screen yet")));
             }),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // 1. Header Section
                   TextFormField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      hintText: 'Task Title',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter a title' : null,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                       Text("in list ", style: TextStyle(color: Colors.grey.shade600)),
                       DropdownButton<String>(
                         value: _status,
                         isDense: true,
                         underline: const SizedBox(),
                         style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                         items: _validColumns.map<DropdownMenuItem<String>>((col) {
                             return DropdownMenuItem<String>(
                               value: col['status']?.toString(),
                               child: Text(col['title']?.toString() ?? 'Unknown'),
                             );
                          }).toList(),
                         onChanged: (val) => setState(() => _status = val!),
                       )
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // 2. Main Content & Sidebar (Responsive Wrap)
                  // For mobile, we stack: Sidebar info -> Description -> Extra
                  _buildSectionLabel('CARD DETAILS'),
                  _buildDetailsCard(),
                  
                  const SizedBox(height: 24),
                  _buildSectionLabel('Description', icon: HeroIcons.bars3BottomLeft),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        hintText: 'Add a more detailed description...',
                        border: InputBorder.none,
                      ),
                      maxLines: 6,
                      minLines: 3,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionLabel('Attachments', icon: HeroIcons.paperClip, action: '+ Add'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('No attachments yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                  ),

                  const SizedBox(height: 24),
                  _buildSectionLabel('Time Tracking', icon: HeroIcons.clock, action: '+ Add Entry'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('No time entries yet.', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionLabel('Activity', icon: HeroIcons.listBullet),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                       const CircleAvatar(radius: 16, backgroundColor: Colors.grey, child: Icon(Icons.person, color: Colors.white, size: 20)),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Container(
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                           decoration: BoxDecoration(
                             border: Border.all(color: Colors.grey.shade300),
                             borderRadius: BorderRadius.circular(20),
                           ),
                           child: const Text('Write a comment...', style: TextStyle(color: Colors.grey)),
                         ),
                       )
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildDetailsCard() {
    return Container(
       padding: const EdgeInsets.all(16),
       decoration: BoxDecoration(
         color: Colors.grey.shade50,
         borderRadius: BorderRadius.circular(8),
         border: Border.all(color: Colors.grey.shade200),
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            _buildDetailRow('Priority', 
              DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), filled: true, fillColor: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                  ],
                  onChanged: (val) => setState(() => _priority = val!),
                )
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Assignee', 
               DropdownButtonFormField<dynamic>(
                  value: _assignee,
                  decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), filled: true, fillColor: Colors.white),
                  items: [
                     const DropdownMenuItem(value: null, child: Text('Unassigned')),
                     ..._validMembers.map((m) {
                        final mId = _getMemberId(m)?.toString();
                        return DropdownMenuItem(
                           value: mId, 
                           child: Text(_getMemberName(m))
                        );
                     }),
                  ],
                  onChanged: (val) => setState(() => _assignee = val),
               )
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Labels', 
               TextFormField(
                 controller: _tagsController,
                 decoration: const InputDecoration(isDense: true, border: OutlineInputBorder(), hintText: 'tag1, tag2', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8), filled: true, fillColor: Colors.white),
               )
            ),
             const SizedBox(height: 12),
             Row(
               children: [
                  Expanded(child: _buildDetailRow('Start Date', 
                     InkWell(
                       onTap: () => _selectDate(context, true),
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                         decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4), color: Colors.white),
                         child: Row(children: [const Icon(Icons.calendar_today, size: 16), const SizedBox(width: 8), Text(_startDate != null ? DateFormat('MM/dd/yy').format(_startDate!) : '')]),
                       ),
                     )
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _buildDetailRow('End Date', 
                     InkWell(
                       onTap: () => _selectDate(context, false),
                       child: Container(
                         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                         decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4), color: Colors.white),
                         child: Row(children: [const Icon(Icons.calendar_today, size: 16), const SizedBox(width: 8), Text(_dueDate != null ? DateFormat('MM/dd/yy').format(_dueDate!) : '')]),
                       ),
                     )
                  )),
               ],
             )
         ],
       ),
    );
  }

  Widget _buildDetailRow(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey)),
        const SizedBox(height: 4),
        child,
      ],
    );
  }

  Widget _buildSectionLabel(String text, {HeroIcons? icon, String? action}) {
     return Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         Row(
           children: [
             if (icon != null) ...[HeroIcon(icon, size: 18, color: Colors.grey.shade700), const SizedBox(width: 8)],
             Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
           ],
         ),
         if (action != null)
           TextButton(onPressed: (){}, child: Text(action, style: const TextStyle(color: Colors.grey))),
       ],
     );
  }
}
