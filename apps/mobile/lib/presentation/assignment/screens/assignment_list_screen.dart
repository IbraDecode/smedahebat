import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_provider.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../providers/assignment_provider.dart';
import '../widgets/assignment_card.dart';

class AssignmentListScreen extends ConsumerStatefulWidget {
  const AssignmentListScreen({super.key});

  @override
  ConsumerState<AssignmentListScreen> createState() => _AssignmentListScreenState();
}

class _AssignmentListScreenState extends ConsumerState<AssignmentListScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String? _selectedSubject;
  SubmissionStatus? _selectedStatus;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assignmentProvider.notifier).fetchAssignments(refresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(assignmentProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assignmentProvider);
    final auth = ref.watch(authProvider);
    final isTeacher = auth.role == 'teacher';

    return Scaffold(
      appBar: AppBar(
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Cari tugas...',
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : const Text('Tugas'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () => setState(() => _showSearch = !_showSearch),
          ),
          if (!_showSearch)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (value) {
                if (value == 'subject') {
                  _showSubjectFilter();
                } else if (value == 'status') {
                  _showStatusFilter();
                } else {
                  setState(() {
                    _selectedSubject = null;
                    _selectedStatus = null;
                  });
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'subject', child: Text('Filter Mapel')),
                const PopupMenuItem(value: 'status', child: Text('Filter Status')),
                const PopupMenuItem(value: 'clear', child: Text('Hapus Filter')),
              ],
            ),
        ],
      ),
      body: _buildBody(state),
      floatingActionButton: isTeacher
          ? FloatingActionButton(
              onPressed: () => context.push('/assignments/create'),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> _showSubjectFilter() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _SubjectFilterDialog(),
    );
    if (result != null) {
      setState(() => _selectedSubject = result);
    }
  }

  Future<void> _showStatusFilter() async {
    final result = await showDialog<SubmissionStatus>(
      context: context,
      builder: (context) => _StatusFilterDialog(current: _selectedStatus),
    );
    setState(() => _selectedStatus = result);
  }

  List<AssignmentItem> _filteredList(AssignmentState state) {
    var list = state.assignments;
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      list = list.where((a) => a.title.toLowerCase().contains(query)).toList();
    }
    if (_selectedSubject != null) {
      list = list.where((a) => a.subjectName == _selectedSubject).toList();
    }
    if (_selectedStatus != null) {
      list = list.where((a) => a.myStatus == _selectedStatus).toList();
    }
    return list;
  }

  Widget _buildBody(AssignmentState state) {
    if (state.isLoading && state.assignments.isEmpty) {
      return _buildShimmer();
    }

    if (state.error != null && state.assignments.isEmpty) {
      return ErrorState(
        message: state.error!,
        onRetry: () => ref.read(assignmentProvider.notifier).fetchAssignments(refresh: true),
      );
    }

    final filtered = _filteredList(state);

    if (filtered.isEmpty && !state.isLoading) {
      if (_searchController.text.isNotEmpty || _selectedSubject != null || _selectedStatus != null) {
        return EmptyState(
          icon: Icons.search_off,
          title: 'Tugas tidak ditemukan',
          subtitle: 'Coba ubah kata kunci pencarian',
        );
      }
      return EmptyState(
        icon: Icons.assignment_outlined,
        title: 'Belum ada tugas',
        subtitle: 'Belum ada tugas yang diberikan',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(assignmentProvider.notifier).fetchAssignments(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= filtered.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final item = filtered[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: AssignmentCard(
              item: item,
              onTap: () => context.push('/assignments/${item.id}'),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerLoading.listItem(height: 120),
      ),
    );
  }
}

class _SubjectFilterDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assignmentProvider);
    final subjects = state.assignments
        .map((a) => a.subjectName)
        .toSet()
        .where((s) => s.isNotEmpty)
        .toList()
      ..sort();

    return SimpleDialog(
      title: const Text('Filter Mapel'),
      children: [
        ...subjects.map(
          (s) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, s),
            child: Text(s),
          ),
        ),
        if (subjects.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Tidak ada mapel'),
          ),
      ],
    );
  }
}

class _StatusFilterDialog extends StatelessWidget {
  final SubmissionStatus? current;

  const _StatusFilterDialog({this.current});

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: const Text('Filter Status'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, null),
          child: Text('Semua', style: TextStyle(fontWeight: current == null ? FontWeight.bold : FontWeight.normal)),
        ),
        ...SubmissionStatus.values.map(
          (s) => SimpleDialogOption(
            onPressed: () => Navigator.pop(context, s),
            child: Text(_statusLabel(s), style: TextStyle(fontWeight: current == s ? FontWeight.bold : FontWeight.normal)),
          ),
        ),
      ],
    );
  }

  String _statusLabel(SubmissionStatus s) {
    switch (s) {
      case SubmissionStatus.pending:
        return 'Belum Dikumpulkan';
      case SubmissionStatus.submitted:
        return 'Terkirim';
      case SubmissionStatus.late:
        return 'Terlambat';
      case SubmissionStatus.graded:
        return 'Dinilai';
    }
  }
}
