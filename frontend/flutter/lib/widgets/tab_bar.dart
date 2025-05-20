import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import '../services/tab_manager_service.dart';

class FileExplorerTabBar extends StatefulWidget {
  const FileExplorerTabBar({super.key});

  @override
  State<FileExplorerTabBar> createState() => _FileExplorerTabBarState();
}

class _FileExplorerTabBarState extends State<FileExplorerTabBar> with WindowListener {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabManager = Provider.of<TabManagerService>(context);
    final theme = Theme.of(context);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.keyT &&
            HardwareKeyboard.instance.isControlPressed) {
          _handleNewTab(tabManager);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onPanStart: (_) => windowManager.startDragging(),
        child: Container(
          height: 32,
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
                child: tabManager.tabs.isEmpty
                    ? Center(
                        child: Text(
                          'No tabs open',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withAlpha(153),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: tabManager.tabs.length,
                        itemBuilder: (context, index) {
                          final tab = tabManager.tabs[index];
                          final isSelected = index == tabManager.currentTabIndex;

                          return GestureDetector(
                            onTap: () => tabManager.switchTab(index),
                            child: Container(
                              margin: const EdgeInsets.only(left: 4, top: 4, bottom: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(6),
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
                                      fontSize: 13,
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
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () => _handleNewTab(tabManager),
                  tooltip: 'New Tab (Ctrl+T)',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNewTab(TabManagerService tabManager) {
    final currentTab = tabManager.currentTab;
    if (currentTab != null) {
      tabManager.addTab(currentTab.path);
    } else {
      // If no current tab, create a new one with home directory
      tabManager.addTab('/home');
    }
  }
} 