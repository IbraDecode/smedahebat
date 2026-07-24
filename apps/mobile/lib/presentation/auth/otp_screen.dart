import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../common/widgets/app_button.dart';
import 'auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _codeControllers = List.generate(6, (_) => TextEditingController());
  final _codeFocusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _codeControllers) {
      c.dispose();
    }
    for (final f in _codeFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      _codeFocusNodes[index + 1].requestFocus();
    }
  }

  void _verifyOtp() {
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length == 6) {
      ref.read(authProvider.notifier).verifyOtp(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    ref.listen(authProvider, (prev, next) {
      if (!next.isLoading && prev?.isLoading == true && next.error == null) {
        context.go('/set-password');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verifikasi'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text(
              'Masukkan Kode Verifikasi',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Kode telah dikirim ke NIS kamu',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 48,
                  child: TextField(
                    controller: _codeControllers[index],
                    focusNode: _codeFocusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onChanged: (value) => _onCodeChanged(value, index),
                  ),
                );
              }),
            ),
            if (authState.error != null) ...[
              const SizedBox(height: 16),
              Text(
                authState.error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 40),
            AppButton(
              label: 'Verifikasi',
              isLoading: authState.isLoading,
              onPressed: _verifyOtp,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Tidak menerima kode?"),
                TextButton(
                  onPressed: () {},
                  child: const Text('Kirim Ulang'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
