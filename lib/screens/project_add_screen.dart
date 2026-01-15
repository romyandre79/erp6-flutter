import 'package:flutter/material.dart';
import '../../core/models/project_model.dart';
import '../../services/project_service.dart';

class ProjectAddScreen extends StatefulWidget {
  final Project? project;
  const ProjectAddScreen({super.key, this.project});

  @override
  State<ProjectAddScreen> createState() => _ProjectAddScreenState();
}

class _ProjectAddScreenState extends State<ProjectAddScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descriptionController = TextEditingController(text: widget.project?.description ?? '');
    if (widget.project != null) {
      _startDate = widget.project!.startDate ?? DateTime.now();
      _endDate = widget.project!.endDate ?? DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final project = Project(
          id: widget.project?.id ?? '', // empty for new
          name: _nameController.text,
          description: _descriptionController.text,
          startDate: _startDate,
          endDate: _endDate,
          color: widget.project?.color ?? '#3b82f6', 
          columns: widget.project?.columns, // preserve columns if editing
        );

        await ProjectService().saveProject(project);
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text(widget.project == null ? 'Project created successfully' : 'Project updated successfully')),
           );
           Navigator.pop(context, true); // Return success
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error: $e')),
           );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.project != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Project' : 'Add Project')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Project Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Start Date'),
                subtitle: Text("${_startDate.toLocal()}".split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _startDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != _startDate) {
                    setState(() => _startDate = picked);
                  }
                },
              ),
               ListTile(
                title: const Text('End Date'),
                subtitle: Text("${_endDate.toLocal()}".split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _endDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null && picked != _endDate) {
                    setState(() => _endDate = picked);
                  }
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : Text(isEditing ? 'Save Changes' : 'Create Project'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
