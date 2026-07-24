import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class GradeScoreInput extends StatefulWidget {
  final String studentName;
  final String studentNis;
  final int? initialScore;
  final int maxScore;
  final ValueChanged<int?> onChanged;

  const GradeScoreInput({
    super.key,
    required this.studentName,
    required this.studentNis,
    this.initialScore,
    required this.maxScore,
    required this.onChanged,
  });

  @override
  State<GradeScoreInput> createState() => _GradeScoreInputState();
}

class _GradeScoreInputState extends State<GradeScoreInput> {
  late TextEditingController _controller;
  bool _isOverMax = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialScore?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(GradeScoreInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialScore != oldWidget.initialScore) {
      _controller.text = widget.initialScore?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      setState(() => _isOverMax = false);
      widget.onChanged(null);
      return;
    }
    final score = int.tryParse(text);
    if (score == null) return;
    setState(() => _isOverMax = score > widget.maxScore);
    widget.onChanged(score);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.studentName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'NIS: ${widget.studentNis}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                suffixText: '/${widget.maxScore}',
                suffixStyle: TextStyle(
                  fontSize: 11,
                  color: _isOverMax ? AppColors.error : AppColors.textHint,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _isOverMax ? AppColors.error : AppColors.border,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _isOverMax ? AppColors.error : AppColors.border,
                  ),
                ),
              ),
              onChanged: _onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
