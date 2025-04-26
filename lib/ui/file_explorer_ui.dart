import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/file_item.dart';
import '../states/file_explorer_state.dart';
import '../viewmodels/file_explorer_viewmodel.dart';
import 'file_grid_view.dart';
import 'breadcrumb_bar.dart';
import 'bookmark_sidebar.dart';
import 'loading_indicator.dart';

class FileExplorerUI extends StatelessWidget {
  const FileExplorerUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FileExplorerState>(
      builder: (context, state, child) {
        final viewModel = context.read<FileExplorerViewModel>();
        
        return Scaffold(
          body: Row(
            children: [
              if (state.showBookmarkSidebar)
                BookmarkSidebar(
                  bookmarks: state.bookmarks,
                  onBookmarkSelected: (path) => viewModel.loadDirectory(path),
                  onBookmarkRemoved: (path) => state.removeBookmark(path),
                  isVisible: state.showBookmarkSidebar,
                ),
              Expanded(
                child: Column(
                  children: [
                    BreadcrumbBar(
                      currentPath: state.currentPath,
                      onPathSelected: (path) => viewModel.loadDirectory(path),
                      onBack: viewModel.events.onNavigateBack,
                      onForward: viewModel.events.onNavigateForward,
                    ),
                    Expanded(
                      child: StreamBuilder<List<FileItem>>(
                        stream: viewModel.directoryStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return FileGridView(
                              items: snapshot.data!,
                              selectedItems: state.selectedItemsPaths,
                              onItemTap: (item) => viewModel.events.onItemTap(item),
                              onItemDoubleTap: (item) => viewModel.events.onItemDoubleTap(item),
                              onItemLongPress: (item) => viewModel.events.onItemLongPress(item),
                            );
                          }
                          return const LoadingIndicator();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 