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

class _FileExplorerTabBarState extends State<FileExplorerTabBar>
    with WindowListener {
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _scrollController.dispose();
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabManager = Provider.of<TabManagerService>(context);
    final theme = Theme.of(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
          height: 40,
          decoration: BoxDecoration(
            color: isDarkMode ? Color(0xFF1E1E1E) : theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withAlpha(26),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child:
                    tabManager.tabs.isEmpty
                        ? Center(
                          child: Text(
                            'No tabs open',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withAlpha(153),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                        : ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                isDarkMode ? Colors.black : Colors.white,
                                Colors.transparent,
                                Colors.transparent,
                                isDarkMode ? Colors.black : Colors.white,
                              ],
                              stops: [0.0, 0.0, 0.98, 1.0],
                            ).createShader(bounds);
                          },
                          blendMode: BlendMode.dstOut,
                          child: ListView.builder(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: tabManager.tabs.length,
                            itemBuilder: (context, index) {
                              final tab = tabManager.tabs[index];
                              final isSelected =
                                  index == tabManager.currentTabIndex;

                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: EdgeInsets.only(
                                    left: 2,
                                    top: 4,
                                    bottom: 4,
                                    right:
                                        index == tabManager.tabs.length - 1
                                            ? 2
                                            : 0,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? (isDarkMode
                                                ? Color(0xFF2D2D2D)
                                                : theme
                                                    .colorScheme
                                                    .primaryContainer)
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? (isDarkMode
                                                  ? Colors.white.withAlpha(26)
                                                  : theme.colorScheme.primary
                                                      .withAlpha(77))
                                              : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () => tabManager.switchTab(index),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.folder_outlined,
                                          size: 16,
                                          color:
                                              isSelected
                                                  ? theme.colorScheme.primary
                                                  : theme.colorScheme.onSurface
                                                      .withAlpha(153),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          tab.title,
                                          style: TextStyle(
                                            color:
                                                isSelected
                                                    ? theme
                                                        .colorScheme
                                                        .onSurface
                                                    : theme
                                                        .colorScheme
                                                        .onSurface
                                                        .withAlpha(153),
                                            fontSize: 13,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.w500
                                                    : FontWeight.normal,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap:
                                                () =>
                                                    tabManager.removeTab(index),
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color:
                                                    isSelected
                                                        ? theme
                                                            .colorScheme
                                                            .onSurface
                                                            .withAlpha(102)
                                                        : Colors.transparent,
                                              ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.close,
                                                  size: 14,
                                                  color:
                                                      isSelected
                                                          ? theme
                                                              .colorScheme
                                                              .onSurface
                                                              .withAlpha(102)
                                                          : theme
                                                              .colorScheme
                                                              .onSurface
                                                              .withAlpha(153),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withAlpha(26),
                    ),
                    child: Icon(
                      Icons.add,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  onPressed: () => _handleNewTab(tabManager),
                  tooltip: 'New Tab (Ctrl+T)',
                  splashRadius: 20,
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
      tabManager.addTab('/home');
    }
  }
}
