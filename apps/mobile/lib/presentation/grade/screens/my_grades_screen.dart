import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../providers/grade_provider.dart';
import '../widgets/grade_badge.dart';

class MyGradesScreen extends ConsumerStatefulWidget {
  const MyGradesScreen({super.key});

  @override
  ConsumerState<MyGradesScreen> createState() => _MyGradesScreenState();
}

class _MyGradesScreenState extends ConsumerState<MyGradesScreen> {
  String? _selectedSubject;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gradeProvider.notifier).fetchMyScores();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gradeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nilai Saya')),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(GradeState state) {
    if (state.isLoading && state.myScores == null) {
      return _buildShimmer();
    }

    if (state.error != null && state.myScores == null) {
      return ErrorState(
        message: state.error!,
        onRetry: () => ref.read(gradeProvider.notifier).fetchMyScores(),
      );
    }

    final myScores = state.myScores;
    if (myScores == null || myScores.subjects.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.grade_outlined, size: 64, color: AppColors.textHint),
            SizedBox(height: 16),
            Text('Belum ada nilai', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final subjects = myScores.subjects.entries.toList();
    final subjectNames = subjects.map((e) => e.key).toList();

    return Column(
      children: [
        _buildSummaryCard(myScores),
        _buildSubjectTabs(subjectNames),
        Expanded(child: _buildSubjectDetail(subjects)),
      ],
    );
  }

  Widget _buildSummaryCard(StudentScores myScores) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          GradeBadge(score: myScores.average, size: 56),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rata-rata Nilai',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                myScores.average.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                '${myScores.total}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Total',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectTabs(List<String> subjects) {
    if (subjects.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: subjects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isSelected = _selectedSubject == subjects[i];
          return ChoiceChip(
            label: Text(subjects[i]),
            selected: isSelected || (_selectedSubject == null && i == 0),
            onSelected: (_) => setState(() => _selectedSubject = subjects[i]),
          );
        },
      ),
    );
  }

  Widget _buildSubjectDetail(List<MapEntry<String, List<ScoreItem>>> subjects) {
    final filtered = _selectedSubject != null
        ? subjects.where((e) => e.key == _selectedSubject).toList()
        : subjects;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final entry = filtered[i];
        final scores = entry.value;
        final total = scores.fold<int>(0, (sum, s) => sum + (s.score ?? 0));
        final maxTotal = scores.fold<int>(0, (sum, s) => sum + s.maxScore);
        final avg = scores.isNotEmpty
            ? scores.fold<double>(0, (sum, s) => sum + (s.score ?? 0).toDouble()) / scores.length
            : 0.0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.book, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                    GradeBadge(score: avg, size: 32),
                  ],
                ),
                const SizedBox(height: 8),
                ...scores.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(s.componentName)),
                          Text(
                            '${s.score ?? '-'} / ${s.maxScore}',
                            style: TextStyle(
                              color: s.score != null
                                  ? _scoreColor(s.score!)
                                  : AppColors.textHint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: $total / $maxTotal',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      'Rata-rata: ${avg.toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: gradeColor(avg),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _scoreColor(int score) {
    if (score >= 90) return AppColors.success;
    if (score >= 75) return AppColors.info;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerLoading.listItem(height: 120),
      ),
    );
  }
}
