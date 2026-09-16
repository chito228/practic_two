import 'package:flutter/material.dart';

import '../utils/breakpoints.dart';

class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final List<AdaptiveNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    required this.title,
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= Breakpoints.tablet;

    if (isWide) {
      return Scaffold(
        appBar: AppBar(title: Text(title), actions: actions),
        body: Row(
          children: [
            _SideMenu(
              items: items,
              selectedIndex: selectedIndex,
              onDestinationSelected: onDestinationSelected,
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: body,
      bottomNavigationBar: _BottomTextBar(
        items: items,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Боковое меню: только текст, выровнен по левому краю.
class _SideMenu extends StatelessWidget {
  final List<AdaptiveNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _SideMenu({
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final menuWidth = width >= Breakpoints.desktop ? 220.0 : 180.0;

    return SizedBox(
      width: menuWidth,
      child: Material(
        color: scheme.surfaceContainerLow,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            for (var i = 0; i < items.length; i++)
              _SideMenuItem(
                label: items[i].label,
                selected: i == selectedIndex,
                onTap: () => onDestinationSelected(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _SideMenuItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SideMenuItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        color: selected ? scheme.secondaryContainer : null,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
            color: selected ? scheme.onSecondaryContainer : scheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}

/// Нижняя панель с текстом вместо иконок.
/// Использует горизонтальную прокрутку, если пункты не влезают.
class _BottomTextBar extends StatelessWidget {
  final List<AdaptiveNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const _BottomTextBar({
    required this.items,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _BottomTextItem(
                      label: items[i].label,
                      selected: i == selectedIndex,
                      onTap: () => onDestinationSelected(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomTextItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _BottomTextItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? scheme.secondaryContainer : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? scheme.onSecondaryContainer
                  : scheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }
}

class AdaptiveNavItem {
  final IconData icon;
  final String label;

  const AdaptiveNavItem({required this.icon, required this.label});
}
