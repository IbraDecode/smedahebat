import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../providers/grade_provider.dart';
import '../widgets/grade_score_input.dart';

class GradeInputScreen extends ConsumerStatefulWidget {
  const GradeInputScreen({super.key});

  @override
  ConsumerState<GradeInputScreen> createState() => _GradeInputScreenState();
}

class _GradeInputScreenState extends ConsumerState<GradeInputScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedClassId;
  String? _selectedSubjectId;
  GradeComponent? _selectedComponent;
  Map<String, int?> _scoreChanges = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gradeProvider.notifier).fetchComponents();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onComponentSelected(GradeComponent c) {
    setState(() {
      _selectedComponent = c;
      _scoreChanges = {};
    });
    ref.read(gradeProvider.notifier).fetchScoresByComponent(c.id);
  }

  Future<void> _saveScores() async {
    if (_selectedComponent == null) return;
    setState(() => _isSaving = true);

    final changes = <Map<String, dynamic>>[];
    _scoreChanges.forEach((studentId, score) {
      if (score != null) {
        changes.add({'studentId': studentId, 'score': score});
      }
    });

    if (changes.isEmpty) {
      setState(() => _isSaving = false);
      return;
    }

    final error = await ref.read(gradeProvider.notifier).inputBulkScores(
      componentId: _selectedComponent!.id,
      scores: changes,
    );

    setState(() => _isSaving = false);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
    } else {
      setState(() => _scoreChanges = {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nilai berhasil disimpan'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gradeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Input Nilai')),
      body: Column(
        children: [
          _buildSelectionBar(state),
          if (_selectedComponent != null)
            _buildScoreArea(state)
          else
            Expanded(
              child: Center(
                child: Text(
                  'Pilih komponen nilai untuk memulai',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textHint,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectionBar(GradeState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          if (state.components.isEmpty && !state.isLoading)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Belum ada komponen. Buat komponen terlebih dahulu.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
            ),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.components.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = state.components[i];
                final isSelected = _selectedComponent?.id == c.id;
                return FilterChip(
                  label: Text(c.name),
                  selected: isSelected,
                  onSelected: (_) => _onComponentSelected(c),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreArea(GradeState state) {
    if (state.isLoading) {
      return const Expanded(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Expanded(
        child: ErrorState(
          message: state.error!,
          onRetry: () => ref.read(gradeProvider.notifier)
              .fetchScoresByComponent(_selectedComponent!.id),
        ),
      );
    }

    final filtered = _searchCtrl.text.isEmpty
        ? state.scores
        : state.scores.where((s) =>
            s.studentName.toLowerCase().contains(_searchCtrl.text.toLowerCase()) ||
            s.studentNis.contains(_searchCtrl.text)).toList();

    if (filtered.isEmpty) {
      return Expanded(
        child: EmptyState(
          icon: Icons.people_outline,
          title: 'Tidak ada data siswa',
          subtitle: 'Pastikan kelas memiliki siswa terdaftar',
        ),
      );
    }

    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Cari siswa...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final item = filtered[i];
                return GradeScoreInput(
                  studentName: item.studentName,
                  studentNis: item.studentNis,
                  initialScore: _scoreChanges[item.studentId] ?? item.score,
                  maxScore: _selectedComponent?.maxScore ?? item.maxScore,
                  onChanged: (score) {
                    setState(() => _scoreChanges[item.studentId] = score);
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_scoreChanges.length} perubahan',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _isSaving || _scoreChanges.isEmpty ? null : _saveScores,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save, size: 18),
                  label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Nilai'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
