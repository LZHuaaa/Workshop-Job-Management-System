import 'package:flutter/material.dart';

class CustomerTag {
  final String name;
  final Color color;
  final IconData icon;

  const CustomerTag({
    required this.name,
    required this.color,
    required this.icon,
  });
}

class CustomerTags {
  // Predefined customer tags
  static const List<CustomerTag> predefinedTags = [
    CustomerTag(
      name: 'VIP',
      color: Color(0xFFFF6B6B), // Red
      icon: Icons.star,
    ),
    CustomerTag(
      name: 'Loyal',
      color: Color(0xFF4ECDC4), // Teal
      icon: Icons.favorite,
    ),
    CustomerTag(
      name: 'High-Value',
      color: Color(0xFFFFD93D), // Yellow
      icon: Icons.attach_money,
    ),
    CustomerTag(
      name: 'Needs Follow-up',
      color: Color(0xFFFF8A80), // Light Red
      icon: Icons.schedule,
    ),
    CustomerTag(
      name: 'Frequent',
      color: Color(0xFF81C784), // Green
      icon: Icons.repeat,
    ),
    CustomerTag(
      name: 'New Customer',
      color: Color(0xFF64B5F6), // Blue
      icon: Icons.fiber_new,
    ),
    CustomerTag(
      name: 'Referral',
      color: Color(0xFFBA68C8), // Purple
      icon: Icons.people,
    ),
    CustomerTag(
      name: 'Corporate',
      color: Color(0xFF90A4AE), // Grey
      icon: Icons.business,
    ),
  ];

  // Get tag by name
  static CustomerTag? getTagByName(String name) {
    try {
      return predefinedTags.firstWhere((tag) => tag.name == name);
    } catch (e) {
      return null;
    }
  }

  // Get all tag names
  static List<String> getAllTagNames() {
    return predefinedTags.map((tag) => tag.name).toList();
  }

  // Get tags for customer (returns CustomerTag objects)
  static List<CustomerTag> getCustomerTags(List<String> tagNames) {
    return tagNames
        .map((name) => getTagByName(name))
        .where((tag) => tag != null)
        .cast<CustomerTag>()
        .toList();
  }

  // Build tag widget
  static Widget buildTagChip(
    String tagName, {
    bool isSelected = false,
    VoidCallback? onTap,
    bool showIcon = true,
    double fontSize = 10,
  }) {
    final tag = getTagByName(tagName);
    if (tag == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? tag.color : tag.color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tag.color,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showIcon) ...[
              Icon(
                tag.icon,
                size: fontSize + 2,
                color: isSelected ? Colors.white : tag.color,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              tag.name,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : tag.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
