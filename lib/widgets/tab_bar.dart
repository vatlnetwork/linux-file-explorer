import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/tab_manager_service.dart';

class FileExplorerTabBar extends StatelessWidget {
  const FileExplorerTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    final tabManager = Provider.of<TabManagerService>(context);
    final theme = Theme.of(context);

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabManager.tabs.length,
              itemBuilder: (context, index) {
                final tab = tabManager.tabs[index];
                final isSelected = index == tabManager.currentTabIndex;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Material(
                    elevation: isSelected ? 4 : 2,
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onTap: () => tabManager.switchTab(index),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              tab.title,
                              style: TextStyle(
                                color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => tabManager.removeTab(index),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                final currentTab = tabManager.currentTab;
                if (currentTab != null) {
                  tabManager.addTab(currentTab.path);
                }
              },
              tooltip: 'New Tab',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
} 