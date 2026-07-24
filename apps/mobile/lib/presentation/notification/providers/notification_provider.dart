import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

enum AnnouncementTarget { all, siswa, guru, waliKelas, kelas }

enum NotificationType { announcement, task, grade, attendance, system }

class AnnouncementItem {
  final String id;
  final String title;
  final String content;
  final String authorName;
  final String authorRole;
  final String authorId;
  final DateTime createdAt;
  final AnnouncementTarget target;
  final String? targetClass;
  final bool isPinned;
  final bool isRead;
  final List<String> attachments;

  const AnnouncementItem({
    required this.id,
    required this.title,
    this.content = '',
    this.authorName = '',
    this.authorRole = '',
    this.authorId = '',
    required this.createdAt,
    this.target = AnnouncementTarget.all,
    this.targetClass,
    this.isPinned = false,
    this.isRead = false,
    this.attachments = const [],
  });

  factory AnnouncementItem.fromJson(Map<String, dynamic> json) {
    return AnnouncementItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? json['body'] as String? ?? '',
      authorName: json['authorName'] as String? ?? json['author']?['name'] as String? ?? '',
      authorRole: json['authorRole'] as String? ?? json['author']?['role'] as String? ?? '',
      authorId: json['authorId'] as String? ?? json['author']?['id']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      target: _parseTarget(json['target'] as String?),
      targetClass: json['targetClass'] as String?,
      isPinned: json['isPinned'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? false,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  static AnnouncementTarget _parseTarget(String? value) {
    switch (value?.toLowerCase()) {
      case 'siswa':
        return AnnouncementTarget.siswa;
      case 'guru':
        return AnnouncementTarget.guru;
      case 'wali_kelas':
      case 'walikelas':
        return AnnouncementTarget.waliKelas;
      case 'kelas':
        return AnnouncementTarget.kelas;
      default:
        return AnnouncementTarget.all;
    }
  }
}

class NotificationItem {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedId;
  final String? relatedType;

  const NotificationItem({
    required this.id,
    this.type = NotificationType.system,
    this.title = '',
    this.body = '',
    required this.createdAt,
    this.isRead = false,
    this.relatedId,
    this.relatedType,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? '',
      type: _parseType(json['type'] as String?),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      relatedId: json['relatedId']?.toString(),
      relatedType: json['relatedType'] as String?,
    );
  }

  static NotificationType _parseType(String? value) {
    switch (value?.toLowerCase()) {
      case 'announcement':
        return NotificationType.announcement;
      case 'task':
        return NotificationType.task;
      case 'grade':
        return NotificationType.grade;
      case 'attendance':
        return NotificationType.attendance;
      default:
        return NotificationType.system;
    }
  }
}

class NotificationState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<AnnouncementItem> announcements;
  final List<NotificationItem> notifications;
  final int unreadCount;
  final bool hasMore;
  final int page;
  final AnnouncementTarget? filterTarget;
  final bool filterPenting;
  final AnnouncementItem? selectedAnnouncement;

  const NotificationState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.announcements = const [],
    this.notifications = const [],
    this.unreadCount = 0,
    this.hasMore = true,
    this.page = 1,
    this.filterTarget,
    this.filterPenting = false,
    this.selectedAnnouncement,
  });

  NotificationState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
    List<AnnouncementItem>? announcements,
    List<NotificationItem>? notifications,
    int? unreadCount,
    bool? hasMore,
    int? page,
    AnnouncementTarget? filterTarget,
    bool clearFilterTarget = false,
    bool? filterPenting,
    AnnouncementItem? selectedAnnouncement,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      announcements: announcements ?? this.announcements,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      filterTarget: clearFilterTarget ? null : (filterTarget ?? this.filterTarget),
      filterPenting: filterPenting ?? this.filterPenting,
      selectedAnnouncement: selectedAnnouncement ?? this.selectedAnnouncement,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final Dio _dio;

  NotificationNotifier(this._dio) : super(const NotificationState());

  Future<void> fetchAnnouncements({int page = 1, AnnouncementTarget? target}) async {
    if (page == 1) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': 20};
      if (target != null && target != AnnouncementTarget.all) {
        queryParams['target'] = target.name;
      }

      final response = await _dio.get(
        ApiEndpoints.announcements,
        queryParameters: queryParams,
      );
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items = data['data'] is List ? data['data'] as List<dynamic> : [];
      final parsed = items
          .map((e) => AnnouncementItem.fromJson(e as Map<String, dynamic>))
          .toList();

      final pinned = parsed.where((a) => a.isPinned).toList();
      final unpinned = parsed.where((a) => !a.isPinned).toList();

      if (page == 1) {
        state = state.copyWith(
          isLoading: false,
          announcements: [...pinned, ...unpinned],
          hasMore: parsed.length >= 20,
          page: page,
        );
      } else {
        state = state.copyWith(
          isLoadingMore: false,
          announcements: [...state.announcements, ...parsed],
          hasMore: parsed.length >= 20,
          page: page,
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

  Future<void> fetchAnnouncementDetail(String id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _dio.get('${ApiEndpoints.announcements}/$id');
      final data = response.data is Map
          ? response.data['data'] as Map<String, dynamic>?
          : null;
      if (data != null) {
        state = state.copyWith(
          isLoading: false,
          selectedAnnouncement: AnnouncementItem.fromJson(data),
        );
      } else {
        state = state.copyWith(isLoading: false, error: 'Data tidak ditemukan');
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<void> createAnnouncement(Map<String, dynamic> dto) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _dio.post(ApiEndpoints.announcements, data: dto);
      state = state.copyWith(isLoading: false);
      await fetchAnnouncements();
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(isLoading: false, error: msg);
      rethrow;
    }
  }

  Future<void> deleteAnnouncement(String id) async {
    try {
      await _dio.delete('${ApiEndpoints.announcements}/$id');
      state = state.copyWith(
        announcements: state.announcements.where((a) => a.id != id).toList(),
        selectedAnnouncement: null,
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(error: msg);
    }
  }

  Future<void> togglePin(String id, bool isPinned) async {
    try {
      await _dio.patch(
        '${ApiEndpoints.announcements}/$id',
        data: {'isPinned': isPinned},
      );
      state = state.copyWith(
        announcements: state.announcements.map((a) {
          if (a.id == id) {
            return AnnouncementItem(
              id: a.id,
              title: a.title,
              content: a.content,
              authorName: a.authorName,
              authorRole: a.authorRole,
              authorId: a.authorId,
              createdAt: a.createdAt,
              target: a.target,
              targetClass: a.targetClass,
              isPinned: isPinned,
              isRead: a.isRead,
              attachments: a.attachments,
            );
          }
          return a;
        }).toList(),
      );
    } on DioException catch (e) {
      final msg = e.response?.data?['message']?.toString() ?? e.message;
      state = state.copyWith(error: msg);
    }
  }

  Future<void> fetchNotifications({int page = 1}) async {
    if (page == 1) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isLoadingMore: true);
    }

    try {
      final response = await _dio.get(
        ApiEndpoints.notifications,
        queryParameters: {'page': page, 'limit': 20},
      );
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final List<dynamic> items = data['data'] is List ? data['data'] as List<dynamic> : [];
      final parsed = items
          .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
          .toList();

      if (page == 1) {
        state = state.copyWith(
          isLoading: false,
          notifications: parsed,
          hasMore: parsed.length >= 20,
          page: page,
        );
      } else {
        state = state.copyWith(
          isLoadingMore: false,
          notifications: [...state.notifications, ...parsed],
          hasMore: parsed.length >= 20,
          page: page,
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

  Future<void> markRead(String id) async {
    try {
      await _dio.patch('${ApiEndpoints.notifications}/$id/read');
      state = state.copyWith(
        notifications: state.notifications.map((n) {
          if (n.id == id) return NotificationItem(id: n.id, type: n.type, title: n.title, body: n.body, createdAt: n.createdAt, isRead: true, relatedId: n.relatedId, relatedType: n.relatedType);
          return n;
        }).toList(),
        unreadCount: (state.unreadCount - 1).clamp(0, state.unreadCount),
      );
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _dio.patch(ApiEndpoints.notificationsReadAll);
      state = state.copyWith(
        notifications: state.notifications.map((n) => NotificationItem(id: n.id, type: n.type, title: n.title, body: n.body, createdAt: n.createdAt, isRead: true, relatedId: n.relatedId, relatedType: n.relatedType)).toList(),
        unreadCount: 0,
      );
    } catch (_) {}
  }

  Future<void> fetchUnreadCount() async {
    try {
      final response = await _dio.get(ApiEndpoints.notificationsUnreadCount);
      final data = response.data is Map
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      final count = (data['data'] is Map
              ? data['data']['count']
              : data['count']) as int? ??
          0;
      state = state.copyWith(unreadCount: count);
    } catch (_) {}
  }

  void markAnnouncementRead(String id) {
    state = state.copyWith(
      announcements: state.announcements.map((a) {
        if (a.id == id) {
          return AnnouncementItem(
            id: a.id,
            title: a.title,
            content: a.content,
            authorName: a.authorName,
            authorRole: a.authorRole,
            authorId: a.authorId,
            createdAt: a.createdAt,
            target: a.target,
            targetClass: a.targetClass,
            isPinned: a.isPinned,
            isRead: true,
            attachments: a.attachments,
          );
        }
        return a;
      }).toList(),
    );
  }

  void setFilter(AnnouncementTarget? target, {bool? penting}) {
    state = state.copyWith(
      filterTarget: target,
      clearFilterTarget: target == null,
      filterPenting: penting ?? state.filterPenting,
    );
  }

  void clearSelectedAnnouncement() {
    state = state.copyWith(selectedAnnouncement: null);
  }
}

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationNotifier(dio);
});
