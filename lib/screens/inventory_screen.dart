import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';
import '../models/inventory_item.dart';
import '../screens/item_details_screen.dart';
import '../dialogs/add_item_dialog.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedSort = 'Name';

  final List<String> _categories = [
    'All',
    'Engine',
    'Brakes',
    'Filters',
    'Fluids',
    'Electrical',
    'Suspension',
  ];

  final List<String> _sortOptions = [
    'Name',
    'Stock Level',
    'Price',
    'Category',
  ];

  // Sample inventory data
  final List<InventoryItem> _allItems = [
    InventoryItem(
      id: '1',
      name: 'Engine Oil Filter',
      category: 'Filters',
      currentStock: 45,
      minStock: 20,
      maxStock: 100,
      unitPrice: 12.99,
      supplier: 'AutoParts Plus',
      location: 'A-1-3',
      description: 'High-quality oil filter for most vehicles',
    ),
    InventoryItem(
      id: '2',
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
      id: '3',
      name: 'Synthetic Motor Oil 5W-30',
      category: 'Fluids',
      currentStock: 120,
      minStock: 50,
      maxStock: 200,
      unitPrice: 24.99,
      supplier: 'Oil Express',
      location: 'C-1-2',
      description: 'Full synthetic motor oil, 5 quart bottle',
    ),
    InventoryItem(
      id: '4',
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
    InventoryItem(
      id: '5',
      name: 'Spark Plugs (Set of 4)',
      category: 'Engine',
      currentStock: 25,
      minStock: 12,
      maxStock: 60,
      unitPrice: 32.99,
      supplier: 'Ignition Pro',
      location: 'D-3-1',
      description: 'Iridium spark plugs for extended life',
    ),
  ];

  List<InventoryItem> get _filteredItems {
    List<InventoryItem> filtered = _allItems;

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered =
          filtered.where((item) => item.category == _selectedCategory).toList();
    }

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered
          .where((item) =>
              item.name.toLowerCase().contains(searchTerm) ||
              item.category.toLowerCase().contains(searchTerm) ||
              item.supplier.toLowerCase().contains(searchTerm))
          .toList();
    }

    // Apply sorting
    switch (_selectedSort) {
      case 'Name':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Stock Level':
        filtered.sort((a, b) => a.currentStock.compareTo(b.currentStock));
        break;
      case 'Price':
        filtered.sort((a, b) => a.unitPrice.compareTo(b.unitPrice));
        break;
      case 'Category':
        filtered.sort((a, b) => a.category.compareTo(b.category));
        break;
    }

    return filtered;
  }

  int get _lowStockCount => _allItems.where((item) => item.isLowStock).length;
  int get _criticalStockCount =>
      _allItems.where((item) => item.isCriticalStock).length;

  void _addItem(InventoryItem item) {
    setState(() {
      _allItems.add(item);
    });
  }

  void _updateItem(InventoryItem updatedItem) {
    setState(() {
      final index = _allItems.indexWhere((item) => item.id == updatedItem.id);
      if (index != -1) {
        _allItems[index] = updatedItem;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Inventory',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAddItemDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          'Add Item',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Stock Status Summary
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusCard(
                          'Total Items',
                          _allItems.length.toString(),
                          AppColors.primaryPink,
                          Icons.inventory_2,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusCard(
                          'Low Stock',
                          _lowStockCount.toString(),
                          AppColors.warningOrange,
                          Icons.warning_amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatusCard(
                          'Critical',
                          _criticalStockCount.toString(),
                          AppColors.errorRed,
                          Icons.error,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search parts, categories, or suppliers...',
                        hintStyle: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Filters and Sort
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            labelStyle: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppColors.textSecondary.withOpacity(0.3),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(
                                category,
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSort,
                          decoration: InputDecoration(
                            labelText: 'Sort by',
                            labelStyle: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: AppColors.textSecondary.withOpacity(0.3),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          items: _sortOptions.map((sort) {
                            return DropdownMenuItem(
                              value: sort,
                              child: Text(
                                sort,
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSort = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Items List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildInventoryCard(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
      String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(InventoryItem item) {
    return GestureDetector(
      onTap: () => _showItemDetails(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.category,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'RM${item.unitPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryPink,
                        ),
                      ),
                      Text(
                        'Location: ${item.location}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Stock Level Indicator
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Stock Level',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '${item.currentStock} / ${item.maxStock}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: item.currentStock / item.maxStock,
                          backgroundColor: AppColors.backgroundLight,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            item.isCriticalStock
                                ? AppColors.errorRed
                                : item.isLowStock
                                    ? AppColors.warningOrange
                                    : AppColors.successGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (item.isCriticalStock || item.isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.isCriticalStock
                            ? AppColors.errorRed
                            : AppColors.warningOrange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.isCriticalStock ? 'CRITICAL' : 'LOW STOCK',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                'Supplier: ${item.supplier}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),

              if (item.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showItemDetails(InventoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemDetailsScreen(
          item: item,
          onItemUpdated: _updateItem,
        ),
      ),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AddItemDialog(
        onItemAdded: _addItem,
      ),
    );
  }
}
