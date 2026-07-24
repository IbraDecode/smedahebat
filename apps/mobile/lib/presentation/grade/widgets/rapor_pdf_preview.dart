import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/grade_provider.dart';

class RaporPdfPreview extends StatelessWidget {
  final ReportCard rapor;

  const RaporPdfPreview({super.key, required this.rapor});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context),
          const Divider(thickness: 2, height: 32),
          _buildStudentInfo(context),
          const SizedBox(height: 20),
          _buildSubjectTable(context),
          const SizedBox(height: 20),
          _buildSummary(context),
          if (rapor.notes != null && rapor.notes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildNotes(context),
          ],
          if (rapor.publishedAt != null) ...[
            const SizedBox(height: 16),
            _buildFooter(context),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Text(
          rapor.schoolName.isNotEmpty ? rapor.schoolName : 'LAPORAN HASIL BELAJAR',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'Tahun Ajaran ${rapor.academicYear} - Semester ${rapor.semester}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStudentInfo(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _infoRow(context, 'Nama', rapor.studentName),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _infoRow(context, 'Kelas', rapor.className),
        ),
      ],
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textHint,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }

  Widget _buildSubjectTable(BuildContext context) {
    return Table(
      border: TableBorder.all(color: AppColors.border),
      columnWidths: const {
        0: FlexColumnWidth(3),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: AppColors.surfaceVariant),
          children: [
            _tableCell(context, 'Mata Pelajaran', isHeader: true),
            _tableCell(context, 'Nilai', isHeader: true),
            _tableCell(context, 'Grade', isHeader: true),
            _tableCell(context, 'Keterangan', isHeader: true),
          ],
        ),
        ...rapor.subjects.map(
          (s) => TableRow(
            children: [
              _tableCell(context, s.subjectName),
              _tableCell(context, s.score.toStringAsFixed(0)),
              _tableCell(
                context,
                s.grade.isNotEmpty ? s.grade : gradeLetter(s.score),
                textColor: gradeColor(s.score),
                fontWeight: FontWeight.bold,
              ),
              _tableCell(context, s.description),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tableCell(
    BuildContext context,
    String text, {
    bool isHeader = false,
    Color? textColor,
    FontWeight? fontWeight,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        style: (isHeader
                ? Theme.of(context).textTheme.labelMedium
                : Theme.of(context).textTheme.bodySmall)
            ?.copyWith(
              fontWeight: fontWeight ?? (isHeader ? FontWeight.bold : null),
              color: textColor ?? (isHeader ? AppColors.textPrimary : AppColors.textSecondary),
            ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text('Total', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint)),
                const SizedBox(height: 4),
                Text(
                  rapor.totalScore.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text('Rata-rata', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint)),
                const SizedBox(height: 4),
                Text(
                  rapor.average.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: gradeColor(rapor.average),
                      ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text('Peringkat', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint)),
                const SizedBox(height: 4),
                Text(
                  rapor.rank.toString(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotes(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catatan Wali Kelas',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            rapor.notes!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Icon(Icons.check_circle, size: 14, color: AppColors.success),
        const SizedBox(width: 4),
        Text(
          'Dipublikasikan: ${rapor.publishedAt}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textHint,
              ),
        ),
      ],
    );
  }

  String gradeLetter(double score) {
    if (score >= 90) return 'A';
    if (score >= 75) return 'B';
    if (score >= 60) return 'C';
    if (score >= 50) return 'D';
    return 'E';
  }

  Color gradeColor(double score) {
    if (score >= 90) return AppColors.success;
    if (score >= 75) return AppColors.info;
    if (score >= 60) return AppColors.warning;
    if (score >= 50) return AppColors.warning;
    return AppColors.error;
  }
}
