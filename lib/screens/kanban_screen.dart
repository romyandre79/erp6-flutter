import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import 'package:intl/intl.dart';
import '../../core/models/project_model.dart';
import '../../core/models/task_model.dart';
import '../../services/project_service.dart';
import '../../widgets/kanban/kanban_board.dart';
import '../../widgets/member_avatar_list.dart';
import '../../widgets/kanban/kanban_list_view.dart';
import '../../widgets/kanban/kanban_calendar_view.dart';
import '../../widgets/kanban/kanban_gantt_view.dart';
import 'project_add_screen.dart';
import 'task_add_edit_screen.dart';

class KanbanScreen extends StatefulWidget {
  const KanbanScreen({super.key});

  @override
  State<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends State<KanbanScreen> {
  final ProjectService _projectService = ProjectService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<Project> _projects = [];
  Project? _selectedProject;
  List<Task> _tasks = [];
  bool _isLoading = true;
  bool _isTasksLoading = false;
  String _currentView = 'kanban'; // kanban, list, calendar, gantt
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final projects = await _projectService.fetchProjects();
      if (mounted) {
        setState(() {
          _projects = projects;
          // If we had a selected project, try to keep it selected (by ID)
          if (_selectedProject != null) {
            final found = projects.where((p) => p.id == _selectedProject!.id).firstOrNull;
            if (found != null) {
              _selectedProject = found; // Update object but keep selection
            } else if (projects.isNotEmpty) {
               _selectProject(projects.first);
            } else {
               _selectedProject = null;
            }
          } else if (projects.isNotEmpty) {
            _selectProject(projects.first);
          } else {
             _isLoading = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading projects: $e')));
      }
    }
  }

  Future<void> _selectProject(Project project) async {
    setState(() {
      _selectedProject = project;
      _isTasksLoading = true;
      _isLoading = false;
    });
    // Close drawer if open
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.pop(context);
    }
    
    try {
      final tasks = await _projectService.fetchTasks(project.id);
      final members = await _projectService.fetchProjectMembers(project.id);
      
      if (mounted) {
        setState(() {
          _tasks = tasks;
          // Update the selected project with fetched members
          _selectedProject = Project(
             id: project.id,
             name: project.name,
             description: project.description,
             color: project.color,
             archived: project.archived,
             startDate: project.startDate,
             endDate: project.endDate,
             columns: project.columns,
             members: members,
          );
          _isTasksLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTasksLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading tasks: $e')));
      }
    }
  }


  void _showAddProject() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProjectAddScreen()),
    );
    if (result == true) {
      _loadProjects();
    }
  }

  void _showEditProject() async {
    if (_selectedProject == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProjectAddScreen(project: _selectedProject)),
    );
    if (result == true) {
      _loadProjects(); // Reload to get updated project details
    }
  }

  void _confirmDeleteProject() async {
    if (_selectedProject == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${_selectedProject!.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
             onPressed: () => Navigator.pop(ctx, true), 
             style: TextButton.styleFrom(foregroundColor: Colors.red),
             child: const Text('Delete')
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _projectService.deleteProject(_selectedProject!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project deleted')));
          _selectedProject = null;
          _loadProjects();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting project: $e')));
        }
      }
    }
  }

  void _showAddTask([Task? task, String? status]) async {
    if (_selectedProject == null) return;
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskAddEditScreen(
        task: task, 
        projectId: _selectedProject!.id,
        initialStatus: status,
        columns: _selectedProject!.columns ?? [], // Pass project columns
        members: _selectedProject!.members ?? [], // Pass project members
      )),
    );
    if (result == true) {
      _selectProject(_selectedProject!); // Reload tasks
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM d, y').format(date);
  }

  void _onCardTap(Task task) {
    _showAddTask(task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_selectedProject?.name ?? 'Kanban Board'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const HeroIcon(HeroIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const HeroIcon(HeroIcons.queueList),
            tooltip: 'Switch Project',
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          if (_selectedProject != null)
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') _showEditProject();
                if (val == 'delete') _confirmDeleteProject();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Project')),
                const PopupMenuItem(value: 'delete', child: Text('Delete Project', style: TextStyle(color: Colors.red))),
              ],
            ),
          IconButton(
            icon: const HeroIcon(HeroIcons.plus),
            onPressed: () => _showAddTask(),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              if (_selectedProject != null) ...[
                _buildProjectHeader(),
                const Divider(height: 1),
                _buildViewSwitcher(),
                const Divider(height: 1),
                Expanded(child: _buildMainContent()),
              ] else 
                 const Expanded(child: Center(child: Text('Please select a project from the menu'))),
            ],
          ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
             decoration: BoxDecoration(color: Colors.blue.shade50),
             child: const Center(
               child: Text('Projects', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
             ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: _showAddProject, 
              icon: const HeroIcon(HeroIcons.plus, size: 18), 
              label: const Text('New Project'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            )
          else if (_projects.isEmpty && !_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'No projects found. Create one to get started.',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _projects.length,
                itemBuilder: (context, index) {
                  final project = _projects[index];
                  final isSelected = project.id == _selectedProject?.id;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.primaries[index % Colors.primaries.length],
                      radius: 6,
                    ),
                    title: Text(project.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    selected: isSelected,
                    selectedTileColor: Colors.blue.shade50,
                    onTap: () => _selectProject(project),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _selectedProject!.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Use the reusable MemberAvatarList widget here
              // Mocking members for now as Project model might not have them populated yet
              MemberAvatarList(
                members: const [
                  {'name': 'Alice', 'photo': ''},
                  {'name': 'Bob', 'photo': ''},
                  {'name': 'Charlie', 'photo': ''}
                ], 
                size: 28,
              ),
            ],
          ),
          const SizedBox(height: 4),
          if ((_selectedProject!.description ?? '').isNotEmpty)
            Text(
              _selectedProject!.description!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              HeroIcon(HeroIcons.calendar, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                "${_formatDate(_selectedProject!.startDate)} - ${_formatDate(_selectedProject!.endDate)}",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildViewSwitcher() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildViewTab('Kanban', 'kanban'),
          _buildViewTab('List', 'list'),
          _buildViewTab('Calendar', 'calendar'),
          _buildViewTab('Gantt', 'gantt'),
        ],
      ),
    );
  }

  Widget _buildViewTab(String label, String viewId) {
    final isSelected = _currentView == viewId;
    return GestureDetector(
      onTap: () => setState(() => _currentView = viewId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: Colors.blue.shade200) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isTasksLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_currentView) {
      case 'kanban':
        return KanbanBoard(
           tasks: _tasks,
           columns: _selectedProject?.columns ?? [],
           onTaskStatusChanged: (task, newStatus) async {
             // Optimistic update
             final oldStatus = task.status;
             setState(() {
               task.status = newStatus;
             });
             
             try {
               await _projectService.updateTaskStatus(task, newStatus);
             } catch (e) {
               // Revert on failure
               setState(() {
                 task.status = oldStatus;
               });
               if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
               }
             }
           },
           onAddTap: (status) {
              _showAddTask(null, status);
           },
           onCardTap: _onCardTap,
        );
      case 'list':
        return KanbanListView(tasks: _tasks, onCardTap: _onCardTap);
      case 'calendar':
        return KanbanCalendarView(tasks: _tasks, onCardTap: _onCardTap);
      case 'gantt':
        return KanbanGanttView(tasks: _tasks, onCardTap: _onCardTap);
      default:
        return const SizedBox();
    }
  }
}
