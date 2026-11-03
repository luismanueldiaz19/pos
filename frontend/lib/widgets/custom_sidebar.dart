import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../palletes/app_colors.dart';
import '../utils/constants.dart';
import '../screens/profile_screen.dart';
import 'fullscreen_toggle_button.dart';

class SidebarItem {
  final String title;
  final IconData icon;
  final List<SidebarSubItem>? subItems;
  final VoidCallback? onTap;
  final String? badge;

  SidebarItem({
    required this.title,
    required this.icon,
    this.subItems,
    this.onTap,
    this.badge,
  });
}

class SidebarSubItem {
  final String title;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isHeader;

  SidebarSubItem({
    required this.title,
    this.onTap,
    this.icon,
    this.isHeader = false,
  });

  /// Constructor de fábrica para encabezados de sección dentro del submenú
  factory SidebarSubItem.header(String title) {
    return SidebarSubItem(title: title, isHeader: true);
  }
}

class CustomSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final List<SidebarItem> items;
  final VoidCallback? onLogout;
  final String userName;

  const CustomSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
    this.onLogout,
    required this.userName,
  });

  @override
  State<CustomSidebar> createState() => _CustomSidebarState();
}

class _CustomSidebarState extends State<CustomSidebar> {
  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 275,
      height: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.azulOscuro,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Branding Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: FadeInDown(
              duration: const Duration(milliseconds: 400),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    appName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Divider(color: Colors.white10, height: 1),

          // 2. Navigation Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = widget.selectedIndex == index;
                final isExpanded = expandedIndex == index;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMainItem(index, item, isSelected, isExpanded),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child:
                          isExpanded &&
                              item.subItems != null &&
                              item.subItems!.isNotEmpty
                          ? Container(
                              margin: const EdgeInsets.only(top: 4, bottom: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: item.subItems!.map((sub) {
                                  return _buildSubItem(sub);
                                }).toList(),
                              ),
                            )
                          : const SizedBox(width: double.infinity, height: 0),
                    ),
                    const SizedBox(height: 4),
                  ],
                );
              },
            ),
          ),

          // 3. Bottom Section (User Profile / Fullscreen / Logout)
          const Divider(color: Colors.white10, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 12.0,
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  borderRadius: BorderRadius.circular(20),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.25,
                        ),
                        child: Text(
                          widget.userName.isNotEmpty
                              ? widget.userName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 105),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent.shade400,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Online',
                                  style: TextStyle(
                                    color: Colors.greenAccent.shade400,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const FullscreenToggleButton(color: Colors.white60, size: 18),
                IconButton(
                  tooltip: 'Salir de la sección',
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white54,
                    size: 18,
                  ),
                  onPressed: widget.onLogout,
                  padding: const EdgeInsets.all(6),
                  constraints: const BoxConstraints(),
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
    final bool hasSubItems = item.subItems != null && item.subItems!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (hasSubItems) {
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
        borderRadius: BorderRadius.circular(10),
        hoverColor: Colors.white.withValues(alpha: 0.05),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.2)
                : (isExpanded
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: isSelected
                    ? AppColors.primary
                    : (isExpanded ? Colors.white : Colors.white70),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isExpanded ? Colors.white : Colors.white70),
                    fontSize: 13,
                    fontWeight: isSelected || isExpanded
                        ? FontWeight.w600
                        : FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (item.badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              if (hasSubItems)
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: isExpanded ? Colors.white70 : Colors.white30,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubItem(SidebarSubItem sub) {
    if (sub.isHeader) {
      return Padding(
        padding: const EdgeInsets.only(left: 18, top: 10, bottom: 4, right: 14),
        child: Row(
          children: [
            Text(
              sub.title.toUpperCase(),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(child: Divider(color: Colors.white10, height: 1)),
          ],
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: sub.onTap,
        borderRadius: BorderRadius.circular(6),
        hoverColor: Colors.white.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7.5),
          child: Row(
            children: [
              if (sub.icon != null) ...[
                Icon(sub.icon, size: 14, color: Colors.white54),
                const SizedBox(width: 10),
              ] else ...[
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  sub.title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
