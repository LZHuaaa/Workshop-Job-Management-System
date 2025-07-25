import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../dialogs/procurement_dialog.dart';
import '../models/inventory_item.dart';

class InventoryCard extends StatelessWidget {
  final Function(List<ProcurementOrder>)? onOrdersCreated;

  const InventoryCard({
    super.key,
    this.onOrdersCreated,
  });

  void _showProcurementDialog(BuildContext context) {
    // Sample low stock items
    final lowStockItems = [
      InventoryItem(
        id: '1',
        name: 'Brake Pads - Front',
        category: 'Brakes',
        currentStock: 8,
        minStock: 15,
        maxStock: 50,
        unitPrice: 89.99,
        supplier: 'BrakeTech Solutions',
        location: 'B-2-1',
        description: 'Premium ceramic brake pads',
      ),
      InventoryItem(
        id: '2',
        name: 'Air Filter',
        category: 'Filters',
        currentStock: 2,
        minStock: 10,
        maxStock: 40,
        unitPrice: 18.99,
        supplier: 'FilterMax',
        location: 'A-1-4',
        description: 'High-flow air filter for improved performance',
      ),
    ];

    showDialog(
      context: context,
      builder: (context) => ProcurementDialog(
        lowStockItems: lowStockItems,
        onOrdersCreated: (orders) {
          if (onOrdersCreated != null) {
            onOrdersCreated!(orders);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: 'Inventory Control',
      action: ActionButton(
        label: 'Initiate Procurement',
        icon: Icons.shopping_cart,
        onPressed: () => _showProcurementDialog(context),
      ),
      child: Column(
        children: [
          // Donut Chart with Center Text
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4,
                    centerSpaceRadius: 60,
                    sections: [
                      PieChartSectionData(
                        color: AppColors.primaryPink,
                        value: 85,
                        title: '',
                        radius: 25,
                      ),
                      PieChartSectionData(
                        color: AppColors.warningOrange,
                        value: 15,
                        title: '',
                        radius: 25,
                      ),
                    ],
                    pieTouchData: PieTouchData(enabled: false),
                  ),
                ),
                // Center Content
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '1,250',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Parts',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(
                color: AppColors.primaryPink,
                label: 'In Stock',
                value: '1,062 items',
              ),
              _buildLegendItem(
                color: AppColors.warningOrange,
                label: 'Low Stock',
                value: '188 items',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Critical Alert
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warningOrange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.warningOrange.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warningOrange,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '5 parts are critically low',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.warningOrange,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.warningOrange,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
