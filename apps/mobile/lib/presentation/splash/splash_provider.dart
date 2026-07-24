import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashState {
  final bool isInitialized;
  final bool isAuthenticated;

  const SplashState({
    this.isInitialized = false,
    this.isAuthenticated = false,
  });

  SplashState copyWith({bool? isInitialized, bool? isAuthenticated}) {
    return SplashState(
      isInitialized: isInitialized ?? this.isInitialized,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class SplashNotifier extends StateNotifier<SplashState> {
  SplashNotifier() : super(const SplashState());

  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(isInitialized: true);
  }

  void setAuthenticated(bool value) {
    state = state.copyWith(isAuthenticated: value);
  }
}

final splashProvider =
    StateNotifierProvider<SplashNotifier, SplashState>((ref) {
  return SplashNotifier();
});
