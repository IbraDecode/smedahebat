import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/auth_provider.dart';
import '../../common/widgets/empty_state.dart';
import '../../common/widgets/error_state.dart';
import '../../common/widgets/shimmer_loading.dart';
import '../../academic/providers/schedule_provider.dart';
import '../providers/picket_provider.dart';
import '../widgets/picket_member_tile.dart';

class PicketChecklistScreen extends ConsumerStatefulWidget {
  final String? classId;

  const PicketChecklistScreen({super.key, this.classId});

  @override
  ConsumerState<PicketChecklistScreen> createState() => _PicketChecklistScreenState();
}

class _PicketChecklistScreenState extends ConsumerState<PicketChecklistScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(parent: _animController, curve: Curves.elasticOut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      final classId = widget.classId;
      if (classId != null) {
        ref.read(picketProvider.notifier).fetchTodayPicket(classId);
      } else if (auth.role == 'student') {
        ref.read(picketProvider.notifier).fetchMySchedule();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(picketProvider);
    final auth = ref.watch(authProvider);
    final today = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM yyyy', 'id').format(today);
    final dayName = Day.current().label;

    final members = state.todayPicket.isNotEmpty
        ? state.todayPicket
        : state.mySchedule
            .where((d) => d.isToday)
            .expand((d) => d.members)
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Piket Hari Ini')),
      body: state.isLoading && members.isEmpty
          ? _buildShimmer()
          : state.error != null && members.isEmpty
              ? ErrorState(
                  message: state.error!,
                  onRetry: () {
                    if (widget.classId != null) {
                      ref.read(picketProvider.notifier).fetchTodayPicket(widget.classId!);
                    } else {
                      ref.read(picketProvider.notifier).fetchMySchedule();
                    }
                  },
                )
              : _buildContent(context, dateStr, dayName, members, auth),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ShimmerLoading.listItem(height: 72),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    String dateStr,
    String dayName,
    List<PicketMember> members,
    AuthState auth,
  ) {
    if (members.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline,
        title: 'Tidak ada piket hari ini',
        subtitle: 'Kamu tidak memiliki jadwal piket untuk hari ini',
      );
    }

    final myMember = auth.name != null
        ? members.where((m) => m.name.toLowerCase().contains(auth.name!.toLowerCase())).toList()
        : <PicketMember>[];
    final others = members.where((m) => !myMember.contains(m)).toList();
    final sortedMembers = [...myMember, ...others];

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.classId != null) {
          await ref.read(picketProvider.notifier).fetchTodayPicket(widget.classId!);
        } else {
          await ref.read(picketProvider.notifier).fetchMySchedule();
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(context, dateStr, dayName, members),
            const SizedBox(height: 8),
            if (myMember.isNotEmpty) _buildMyCheckin(context, myMember.first),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Anggota Piket',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${members.where((m) => m.isDone).length}/${members.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...sortedMembers.map((m) => PicketMemberTile(
                  member: m,
                  showCheckbox: true,
                  showTime: true,
                  checked: m.isDone,
                  onToggle: m == myMember.firstOrNull
                      ? () => _handleCheckin(m)
                      : null,
                )),
            const SizedBox(height: 24),
            _buildShareButton(context),
            const SizedBox(height: 32),
            if (_showConfetti) _buildConfetti(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String dateStr,
    String dayName,
    List<PicketMember> members,
  ) {
    final doneCount = members.where((m) => m.isDone).length;
    final total = members.length;
    final allDone = doneCount >= total;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: allDone
              ? [AppColors.success, AppColors.success.withValues(alpha: 0.8)]
              : [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              allDone ? Icons.check_circle : Icons.checklist_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Piket Hari Ini',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              dayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem('Total', '$total orang'),
              const SizedBox(width: 24),
              _buildStatItem('Selesai', '$doneCount orang'),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total > 0 ? doneCount / total : 0,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMyCheckin(BuildContext context, PicketMember member) {
    final isCheckedIn = member.isDone;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isCheckedIn
            ? LinearGradient(
                colors: [AppColors.success.withValues(alpha: 0.1), AppColors.success.withValues(alpha: 0.05)],
              )
            : LinearGradient(
                colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.primary.withValues(alpha: 0.05)],
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCheckedIn ? AppColors.success.withValues(alpha: 0.3) : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isCheckedIn
                ? AppColors.success.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.15),
            child: Icon(
              isCheckedIn ? Icons.check_circle : Icons.login_rounded,
              color: isCheckedIn ? AppColors.success : AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCheckedIn ? 'Kamu sudah check-in' : 'Check-in Piket',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: isCheckedIn ? AppColors.success : AppColors.textPrimary,
                  ),
                ),
                if (isCheckedIn && member.doneAt != null)
                  Text(
                    'Pukul ${DateFormat('HH:mm').format(member.doneAt!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (!isCheckedIn)
                  const Text(
                    'Tekan tombol untuk check-in',
                    style: TextStyle(fontSize: 12, color: AppColors.textHint),
                  ),
              ],
            ),
          ),
          if (!isCheckedIn)
            ScaleTransition(
              scale: _scaleAnim,
              child: FilledButton.icon(
                onPressed: () => _handleCheckin(member),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Check-in'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (isCheckedIn)
            const Icon(Icons.check_circle, color: AppColors.success, size: 28),
        ],
      ),
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fitur bagikan akan segera hadir')),
        );
      },
      icon: const Icon(Icons.share, size: 18),
      label: const Text('Bagikan ke Grup'),
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: const BorderSide(color: AppColors.border),
      ),
    );
  }

  Widget _buildConfetti() {
    return Container(
      height: 120,
      alignment: Alignment.center,
      child: const Icon(Icons.celebration, size: 48, color: AppColors.warning),
    );
  }

  Future<void> _handleCheckin(PicketMember member) async {
    final error = await ref.read(picketProvider.notifier).checklist(member.id);
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
      return;
    }
    _animController.forward(from: 0);
    setState(() => _showConfetti = true);
    if (mounted) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showConfetti = false);
      });
    }
  }
}
