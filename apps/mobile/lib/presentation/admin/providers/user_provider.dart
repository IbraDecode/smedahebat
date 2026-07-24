import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class UserListState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<Map<String, dynamic>> users;
  final int currentPage;
  final bool hasMore;
  final int totalItems;
  final String? search;
  final String? roleFilter;

  const UserListState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.users = const [],
    this.currentPage = 1,
    this.hasMore = false,
    this.totalItems = 0,
    this.search,
    this.roleFilter,
  });

  UserListState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool clearError = false,
    String? error,
    List<Map<String, dynamic>>? users,
    int? currentPage,
    bool? hasMore,
    int? totalItems,
    String? search,
    String? roleFilter,
  }) {
    return UserListState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      users: users ?? this.users,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      totalItems: totalItems ?? this.totalItems,
      search: search ?? this.search,
      roleFilter: roleFilter ?? this.roleFilter,
    );
  }
}

class UserNotifier extends StateNotifier<UserListState> {
  final Dio _dio;

  UserNotifier(this._dio) : super(const UserListState());

  Future<void> fetchUsers({
    int? page,
    String? search,
    String? role,
  }) async {
    final isLoadMore = page != null && page > 1;
    if (isLoadMore) {
      state = state.copyWith(isLoadingMore: true, clearError: true);
    } else {
      state = state.copyWith(
        isLoading: true,
        clearError: true,
        search: search,
        roleFilter: role,
      );
    }

    try {
      final response = await _dio.get(
        ApiEndpoints.users,
        queryParameters: {
          'page': page ?? 1,
          if (search != null) 'search': search,
          if (role != null) 'role': role,
        },
      );
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items =
          data['data'] is List ? data['data'] as List<dynamic> : [];
      final pagination = data['pagination'] is Map
          ? data['pagination'] as Map<String, dynamic>
          : <String, dynamic>{};

      final newUsers = items.cast<Map<String, dynamic>>();
      final totalPages = pagination['totalPages'] as int? ?? 1;
      final currentPage = pagination['page'] as int? ?? 1;

      if (isLoadMore) {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          users: [...state.users, ...newUsers],
          currentPage: currentPage,
          hasMore: currentPage < totalPages,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          users: newUsers,
          currentPage: currentPage,
          hasMore: currentPage < totalPages,
          totalItems: pagination['totalItems'] as int? ?? 0,
        );
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: msg,
      );
    }
  }

  Future<void> refresh() =>
      fetchUsers(search: state.search, role: state.roleFilter);

  Future<String?> createUser(Map<String, dynamic> dto) async {
    try {
      await _dio.post(ApiEndpoints.users, data: dto);
      await refresh();
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }

  Future<String?> updateUser(String id, Map<String, dynamic> dto) async {
    try {
      await _dio.patch('${ApiEndpoints.users}/$id', data: dto);
      await refresh();
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }

  Future<String?> deleteUser(String id) async {
    try {
      await _dio.delete('${ApiEndpoints.users}/$id');
      state = state.copyWith(
        users: state.users.where((u) => u['id'] != id).toList(),
      );
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }

  Future<String?> assignRole(String userId, String role) async {
    try {
      await _dio.patch('${ApiEndpoints.users}/$userId/role',
          data: {'role': role});
      await refresh();
      return null;
    } on DioException catch (e) {
      return e.response?.data?['message']?.toString() ?? e.message;
    }
  }
}

final userProvider =
    StateNotifierProvider<UserNotifier, UserListState>((ref) {
  final dio = ref.watch(dioProvider);
  return UserNotifier(dio);
});
