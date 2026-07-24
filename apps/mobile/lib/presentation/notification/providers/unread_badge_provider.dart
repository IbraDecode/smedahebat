import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

final unreadBadgeProvider = StateProvider<int>((ref) => 0);

final unreadBadgeControllerProvider = Provider<UnreadBadgeController>((ref) {
  final dio = ref.watch(dioProvider);
  return UnreadBadgeController(ref, dio);
});

class UnreadBadgeController {
  final Ref _ref;
  final Dio _dio;
  Timer? _timer;

  UnreadBadgeController(this._ref, this._dio);

  void startPolling() {
    _fetch();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetch());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _fetch() async {
    try {
      final response = await _dio.get(ApiEndpoints.notificationsUnreadCount);
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final count = (data['data'] is Map
              ? data['data']['count']
              : data['count']) as int? ??
          0;
      _ref.read(unreadBadgeProvider.notifier).state = count;
    } catch (_) {}
  }

  void dispose() {
    stopPolling();
  }
}
