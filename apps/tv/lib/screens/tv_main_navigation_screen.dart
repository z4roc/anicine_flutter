import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../home.dart';
import 'tv_search_screen.dart';
import 'tv_watchlist_screen.dart';
import 'tv_watch_history_screen.dart';

class TVMainNavigationScreen extends StatefulWidget {
  const TVMainNavigationScreen({super.key});

  @override
  State<TVMainNavigationScreen> createState() => _TVMainNavigationScreenState();
}

class _TVMainNavigationScreenState extends State<TVMainNavigationScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> _screens = [
    const TVHomeScreen(),
    const TVSearchScreen(),
    const TVWatchlistScreen(),
    const TVWatchHistoryScreen(),
  ];

  final List<_NavItem> _navItems = [
    _NavItem(icon: Icons.home, label: 'Home'),
    _NavItem(icon: Icons.search, label: 'Search'),
    _NavItem(icon: Icons.favorite, label: 'Watchlist'),
    _NavItem(icon: Icons.history, label: 'Recently Watched'),
  ];

  void _openDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _closeDrawer() {
    _scaffoldKey.currentState?.closeEndDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          _screens[_selectedIndex],
          // Menu button overlay
          Positioned(
            top: 40,
            right: 40,
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.select) {
                  _openDrawer();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Builder(
                builder: (context) {
                  final isFocused = Focus.of(context).hasFocus;
                  return InkWell(
                    onTap: _openDrawer,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isFocused
                            ? Colors.purple.withOpacity(0.9)
                            : Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: isFocused
                            ? Border.all(color: Colors.white, width: 3)
                            : Border.all(
                                color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.menu, color: Colors.white, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'Menu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      endDrawer: _buildDrawer(),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: 400,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade900,
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Row(
                  children: [
                    const Icon(Icons.tv, color: Colors.purple, size: 48),
                    const SizedBox(width: 16),
                    const Text(
                      'AniCine TV',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    Focus(
                      autofocus: true,
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.select) {
                          _closeDrawer();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: Builder(
                        builder: (context) {
                          final isFocused = Focus.of(context).hasFocus;
                          return InkWell(
                            onTap: _closeDrawer,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isFocused
                                    ? Colors.white.withOpacity(0.3)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: isFocused
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, thickness: 1),
              // Navigation Items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  itemCount: _navItems.length,
                  itemBuilder: (context, index) {
                    return _buildNavItem(index);
                  },
                ),
              ),
              // App Info
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final item = _navItems[index];
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.select) {
            setState(() {
              _selectedIndex = index;
            });
            _closeDrawer();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: Builder(
          builder: (context) {
            final isFocused = Focus.of(context).hasFocus;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedIndex = index;
                });
                _closeDrawer();
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.purple.withOpacity(0.5)
                      : isFocused
                          ? Colors.white.withOpacity(0.2)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isFocused
                      ? Border.all(color: Colors.white, width: 3)
                      : isSelected
                          ? Border.all(
                              color: Colors.purple.shade300, width: 2)
                          : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withOpacity(0.7),
                      size: 32,
                    ),
                    const SizedBox(width: 20),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : Colors.white.withOpacity(0.7),
                      ),
                    ),
                    if (isSelected) ...[
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 28,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  _NavItem({required this.icon, required this.label});
}
