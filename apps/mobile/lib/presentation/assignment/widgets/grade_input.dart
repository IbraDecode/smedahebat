import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class GradeInput extends StatefulWidget {
  final int maxScore;
  final int? initialScore;
  final String? initialFeedback;
  final ValueChanged<int>? onScoreChanged;
  final ValueChanged<String>? onFeedbackChanged;

  const GradeInput({
    super.key,
    required this.maxScore,
    this.initialScore,
    this.initialFeedback,
    this.onScoreChanged,
    this.onFeedbackChanged,
  });

  @override
  GradeInputState createState() => GradeInputState();
}

class GradeInputState extends State<GradeInput> {
  final _scoreController = TextEditingController();
  final _feedbackController = TextEditingController();
  String? _scoreError;

  @override
  void initState() {
    super.initState();
    if (widget.initialScore != null) {
      _scoreController.text = widget.initialScore.toString();
    }
    if (widget.initialFeedback != null) {
      _feedbackController.text = widget.initialFeedback!;
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _setScore(int value) {
    final clamped = value.clamp(0, widget.maxScore);
    _scoreController.text = clamped.toString();
    _scoreError = null;
    widget.onScoreChanged?.call(clamped);
    setState(() {});
  }

  bool validate() {
    final text = _scoreController.text.trim();
    if (text.isEmpty) {
      setState(() => _scoreError = 'Nilai harus diisi');
      return false;
    }
    final score = int.tryParse(text);
    if (score == null || score < 0 || score > widget.maxScore) {
      setState(() => _scoreError = 'Nilai harus 0 - ${widget.maxScore}');
      return false;
    }
    _scoreError = null;
    return true;
  }

  int? get score {
    return int.tryParse(_scoreController.text.trim());
  }

  String get feedback => _feedbackController.text.trim();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nilai',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _scoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0 - ${widget.maxScore}',
                  errorText: _scoreError,
                  suffixText: '/ ${widget.maxScore}',
                  suffixStyle: TextStyle(color: AppColors.textHint, fontSize: 14),
                ),
                onChanged: (value) {
                  _scoreError = null;
                  setState(() {});
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [80, 90, 100]
              .where((v) => v <= widget.maxScore)
              .map((v) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: OutlinedButton(
                      onPressed: () => _setScore(v),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: _scoreController.text == v.toString()
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text('$v', style: const TextStyle(fontSize: 14)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        Text(
          'Umpan Balik',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _feedbackController,
          maxLines: 4,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Tulis umpan balik untuk siswa...',
            alignLabelWithHint: true,
          ),
          onChanged: widget.onFeedbackChanged,
        ),
      ],
    );
  }
}
