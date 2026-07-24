import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../notification/providers/unread_badge_provider.dart';

final _selectedIndexProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(unreadBadgeControllerProvider).startPolling();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    ref.read(unreadBadgeControllerProvider).dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(unreadBadgeControllerProvider).startPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(_selectedIndexProvider);
    final unreadCount = ref.watch(unreadBadgeProvider);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex,
          onTap: (index) {
            ref.read(_selectedIndexProvider.notifier).state = index;
            switch (index) {
              case 0:
                context.go('/');
              case 1:
                context.go('/academic');
              case 2:
                context.go('/activity');
              case 3:
                context.go('/notifications');
                ref.read(unreadBadgeControllerProvider).startPolling();
              case 4:
                context.go('/profile');
            }
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'Academic',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.rocket_launch_outlined),
              activeIcon: Icon(Icons.rocket_launch),
              label: 'Activity',
            ),
            BottomNavigationBarItem(
              icon: unreadCount > 0
                  ? Badge(
                      label: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                      child: const Icon(Icons.notifications_outlined),
                    )
                  : const Icon(Icons.notifications_outlined),
              activeIcon: unreadCount > 0
                  ? Badge(
                      label: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        style: const TextStyle(fontSize: 10),
                      ),
                      child: const Icon(Icons.notifications),
                    )
                  : const Icon(Icons.notifications),
              label: 'Notification',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
