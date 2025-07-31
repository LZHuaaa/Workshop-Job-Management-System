import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../services/notification_service_factory.dart';

class NotificationBadge extends StatelessWidget {
  final VoidCallback onTap;
  final double iconSize;
  final Color? iconColor;

  const NotificationBadge({
    super.key,
    required this.onTap,
    this.iconSize = 24,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationServiceFactory.getService();

    return StreamBuilder<int>(
      stream: notificationService.getUnreadNotificationsCount(),
      builder: (context, snapshot) {
        print('🔔 NotificationBadge StreamBuilder: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, data=${snapshot.data}');

        // Handle errors gracefully
        if (snapshot.hasError) {
          print('❌ Notification badge error: ${snapshot.error}');
        }

        final unreadCount = snapshot.data ?? 0;
        print('🔔 NotificationBadge: Displaying count=$unreadCount');

        return Stack(
          children: [
            IconButton(
              onPressed: onTap,
              icon: Icon(
                Icons.notifications_outlined,
                color: iconColor ?? AppColors.textDark,
                size: iconSize,
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
