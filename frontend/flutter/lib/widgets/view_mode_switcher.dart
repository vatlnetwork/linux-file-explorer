import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/view_mode_service.dart';

class ViewModeSwitcher extends StatelessWidget {
  final bool useCustomColors;

  const ViewModeSwitcher({super.key, this.useCustomColors = false});

  @override
  Widget build(BuildContext context) {
    final viewModeService = Provider.of<ViewModeService>(context);
    final Color iconColor =
        useCustomColors
            ? Colors.white
            : Theme.of(context).iconTheme.color ?? Colors.grey;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<ViewMode>(
      tooltip: 'View Options',
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      color: isDarkMode ? Color(0xFF2C2C2C) : Colors.white,
      elevation: 3,
      onSelected: (ViewMode mode) {
        viewModeService.setViewMode(mode);
      },
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<ViewMode>>[
            PopupMenuItem<ViewMode>(
              value: ViewMode.list,
              child: _buildMenuItem(
                icon: Icons.view_list,
                label: 'List View',
                isSelected: viewModeService.isList,
                isDarkMode: isDarkMode,
              ),
            ),
            PopupMenuItem<ViewMode>(
              value: ViewMode.grid,
              child: _buildMenuItem(
                icon: Icons.grid_view,
                label: 'Grid View',
                isSelected: viewModeService.isGrid,
                isDarkMode: isDarkMode,
              ),
            ),
            PopupMenuItem<ViewMode>(
              value: ViewMode.column,
              child: _buildMenuItem(
                icon: Icons.view_column,
                label: 'Column View',
                isSelected: viewModeService.isColumn,
                isDarkMode: isDarkMode,
              ),
            ),
            PopupMenuItem<ViewMode>(
              value: ViewMode.split,
              child: _buildMenuItem(
                icon: Icons.view_quilt,
                label: 'Details View',
                isSelected: viewModeService.isSplit,
                isDarkMode: isDarkMode,
              ),
            ),
          ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color:
                isSelected
                    ? (isDarkMode ? Colors.blue : Colors.blue.shade700)
                    : isDarkMode
                    ? Colors.grey.shade300
                    : Colors.grey.shade800,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color:
                  isSelected
                      ? (isDarkMode ? Colors.blue : Colors.blue.shade700)
                      : isDarkMode
                      ? Colors.grey.shade300
                      : Colors.grey.shade800,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(
              Icons.check,
              size: 16,
              color: isDarkMode ? Colors.blue : Colors.blue.shade700,
            ),
          ],
        ],
      ),
    );
  }
}
