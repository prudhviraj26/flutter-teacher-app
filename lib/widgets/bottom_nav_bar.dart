import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../constants/colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  final String currentRoute;

  const CustomBottomNavBar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFF3F4F6)),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home button
            _buildNavItem(
              context: context,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: appState.translate('home'),
              isActive: currentRoute == '/home',
              onTap: () {
                if (currentRoute != '/home') {
                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                }
              },
            ),
            // Staff Notice button
            _buildNavItem(
              context: context,
              icon: Icons.notifications_none_outlined,
              activeIcon: Icons.notifications,
              label: appState.language == 'mr'
                  ? 'सूचना'
                  : appState.language == 'hi'
                      ? 'नोटिस'
                      : 'Staff Notice',
              isActive: currentRoute == '/staff-notice',
              onTap: () {
                if (currentRoute != '/staff-notice') {
                  Navigator.pushNamed(context, '/staff-notice');
                }
              },
            ),
            // Profile button
            _buildNavItem(
              context: context,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              label: appState.translate('profile'),
              isActive: currentRoute == '/profile',
              onTap: () {
                if (currentRoute != '/profile') {
                  Navigator.pushNamed(context, '/profile');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final activeColor = AppColors.primary;
    final inactiveColor = const Color(0xFF9CA3AF);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : inactiveColor,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
