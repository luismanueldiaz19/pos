import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../palletes/app_colors.dart';
import '../utils/constants.dart';
import 'fullscreen_toggle_button.dart';

class SidebarItem {
  final String title;
  final IconData icon;
  final List<SidebarSubItem>? subItems;
  final VoidCallback? onTap;

  SidebarItem({
    required this.title,
    required this.icon,
    this.subItems,
    this.onTap,
  });
}

class SidebarSubItem {
  final String title;
  final VoidCallback onTap;

  SidebarSubItem({required this.title, required this.onTap});
}

class CustomSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<SidebarItem> items;
  final VoidCallback? onLogout;
  final String userName; // 👈 Nuevo campo

  const CustomSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.onLogout,
    required this.userName, // 👈 Obligatorio
  });

  @override
  State<CustomSidebar> createState() => _CustomSidebarState();
}

class _CustomSidebarState extends State<CustomSidebar> {
  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.azulOscuro,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Branding Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: FadeInDown(
              duration: const Duration(milliseconds: 500),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.home_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Text(
                    appName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = widget.selectedIndex == index;
                final isExpanded = expandedIndex == index;

                return Column(
                  children: [
                    _buildMainItem(index, item, isSelected, isExpanded),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: isExpanded
                          ? Column(
                              children: item.subItems!.map((sub) {
                                return _buildSubItem(sub);
                              }).toList(),
                            )
                          : const SizedBox(width: double.infinity, height: 0),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),

          // Bottom Section (User Profile / Logout)
          const Divider(color: Colors.white10, height: 1),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.person, color: Colors.white70),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Online',
                        style: TextStyle(
                          color: Colors.greenAccent.shade400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const FullscreenToggleButton(
                  color: Colors.white70,
                  size: 20,
                ),
                IconButton(
                  tooltip: 'Salir de la sección',
                  icon: const Icon(
                    Icons.logout,
                    color: Colors.white54,
                    size: 20,
                  ),
                  onPressed: widget.onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainItem(
    int index,
    SidebarItem item,
    bool isSelected,
    bool isExpanded,
  ) {
    return InkWell(
      onTap: () {
        if (item.subItems != null) {
          setState(() {
            expandedIndex = isExpanded ? null : index;
          });
        } else {
          if (item.onTap != null) {
            item.onTap!();
          } else {
            widget.onItemSelected(index);
          }
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              color: isSelected ? AppColors.primary : Colors.white70,
              size: 22,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Text(
                item.title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (item.subItems != null)
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                color: Colors.white30,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubItem(SidebarSubItem sub) {
    return InkWell(
      onTap: sub.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.only(left: 52, top: 12, bottom: 12),
        width: double.infinity,
        child: Text(
          sub.title,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
      ),
    );
  }
}
