import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_dialog.dart';

class CustomerSelectionWidget extends StatefulWidget {
  final Customer? selectedCustomer;
  final Function(Customer?) onCustomerSelected;
  final Function() onCreateNewCustomer;
  final bool showCreateButton;

  const CustomerSelectionWidget({
    Key? key,
    this.selectedCustomer,
    required this.onCustomerSelected,
    required this.onCreateNewCustomer,
    this.showCreateButton = true,
  }) : super(key: key);

  @override
  State<CustomerSelectionWidget> createState() => _CustomerSelectionWidgetState();
}

class _CustomerSelectionWidgetState extends State<CustomerSelectionWidget> {
  final TextEditingController _searchController = TextEditingController();
  final CustomerService _customerService = CustomerService();
  
  List<Customer> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // If there's a selected customer, populate the search field
    if (widget.selectedCustomer != null) {
      _searchController.text = widget.selectedCustomer!.fullName;
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _showResults = false;
        _searchResults = [];
        _errorMessage = '';
      });
      return;
    }

    if (query.length < 2) {
      setState(() {
        _showResults = false;
        _searchResults = [];
        _errorMessage = '';
      });
      return;
    }

    _performSearch(query);
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });

    try {
      final results = await _customerService.searchCustomers(query);
      
      setState(() {
        _searchResults = results;
        _showResults = true;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to search customers: ${e.toString()}';
        _isSearching = false;
        _showResults = false;
      });
    }
  }

  void _selectCustomer(Customer customer) {
    setState(() {
      _searchController.text = customer.fullName;
      _showResults = false;
    });
    widget.onCustomerSelected(customer);
  }

  void _clearSelection() {
    setState(() {
      _searchController.clear();
      _showResults = false;
      _searchResults = [];
    });
    widget.onCustomerSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(
              Icons.person_search,
              color: AppColors.primaryPink,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Customer Selection',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        Text(
          'Search for an existing customer or create a new one',
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        
        const SizedBox(height: 20),

        // Search Field
        CustomTextField(
          label: 'Search Customer',
          hint: 'Enter name, phone, or email...',
          controller: _searchController,
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: AppColors.textSecondary),
                  onPressed: _clearSelection,
                )
              : null,
        ),

        // Loading Indicator
        if (_isSearching)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryPink,
                strokeWidth: 2,
              ),
            ),
          ),

        // Error Message
        if (_errorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.errorRed.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: AppColors.errorRed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.errorRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Search Results
        if (_showResults && _searchResults.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Found ${_searchResults.length} customer${_searchResults.length == 1 ? '' : 's'}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ...List.generate(_searchResults.length, (index) {
                    final customer = _searchResults[index];
                    final isSelected = widget.selectedCustomer?.id == customer.id;
                    
                    return InkWell(
                      onTap: () => _selectCustomer(customer),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.primaryPink.withOpacity(0.1)
                              : Colors.transparent,
                          border: index < _searchResults.length - 1
                              ? Border(bottom: BorderSide(color: AppColors.borderColor))
                              : null,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primaryPink.withOpacity(0.2),
                              child: Text(
                                customer.firstName.isNotEmpty 
                                    ? customer.firstName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryPink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.fullName,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    customer.phone,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (customer.email.isNotEmpty)
                                    Text(
                                      customer.email,
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: AppColors.primaryPink,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

        // No Results Message
        if (_showResults && _searchResults.isEmpty && !_isSearching)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.person_off,
                    color: AppColors.textSecondary,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No customers found',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try a different search term or create a new customer',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

        // Create New Customer Button
        if (widget.showCreateButton)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onCreateNewCustomer,
                icon: Icon(Icons.person_add, color: AppColors.primaryPink),
                label: Text(
                  'Create New Customer',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryPink,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppColors.primaryPink, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
