import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/view_mode_service.dart';

class ViewModeSwitcher extends StatelessWidget {
  final bool useCustomColors;
  
  const ViewModeSwitcher({
    super.key,
    this.useCustomColors = false,
  });

  @override
  Widget build(BuildContext context) {
    final viewModeService = Provider.of<ViewModeService>(context);
    final Color iconColor = useCustomColors ? Colors.white : Theme.of(context).iconTheme.color ?? Colors.grey;
    
    return Tooltip(
      message: 'Change view mode',
      child: PopupMenuButton<ViewMode>(
        tooltip: 'Change view mode',
        icon: Icon(
          viewModeService.isList 
              ? Icons.view_list 
              : viewModeService.isGrid
                  ? Icons.grid_view
                  : viewModeService.isColumn
                      ? Icons.view_column
                      : Icons.view_quilt,
          color: iconColor,
        ),
        offset: const Offset(0, 40),
        onSelected: (ViewMode mode) {
          viewModeService.setViewMode(mode);
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<ViewMode>>[
          const PopupMenuItem<ViewMode>(
            value: ViewMode.list,
            child: Row(
              children: [
                Icon(Icons.view_list),
                SizedBox(width: 8),
                Text('List View'),
              ],
            ),
          ),
          const PopupMenuItem<ViewMode>(
            value: ViewMode.grid,
            child: Row(
              children: [
                Icon(Icons.grid_view),
                SizedBox(width: 8),
                Text('Grid View'),
              ],
            ),
          ),
          const PopupMenuItem<ViewMode>(
            value: ViewMode.column,
            child: Row(
              children: [
                Icon(Icons.view_column),
                SizedBox(width: 8),
                Text('Column View'),
              ],
            ),
          ),
          const PopupMenuItem<ViewMode>(
            value: ViewMode.split,
            child: Row(
              children: [
                Icon(Icons.view_quilt),
                SizedBox(width: 8),
                Text('Split View'),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 