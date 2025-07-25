import '../models/invoice.dart';

class InvoiceService {
  // TODO: Replace with actual API calls
  static final List<Invoice> _mockInvoices = [];

  Future<List<Invoice>> getInvoices({
    String? searchTerm,
    InvoiceStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Apply filters
    return _mockInvoices.where((invoice) {
      bool matches = true;

      if (searchTerm != null && searchTerm.isNotEmpty) {
        matches = matches &&
            (invoice.customerName.toLowerCase().contains(searchTerm.toLowerCase()) ||
                invoice.id.toLowerCase().contains(searchTerm.toLowerCase()));
      }

      if (status != null) {
        matches = matches && invoice.status == status;
      }

      if (startDate != null) {
        matches = matches && invoice.issueDate.isAfter(startDate);
      }

      if (endDate != null) {
        matches = matches && invoice.issueDate.isBefore(endDate);
      }

      return matches;
    }).toList();
  }

  Future<Invoice> createInvoice(Invoice invoice) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    _mockInvoices.add(invoice);
    return invoice;
  }

  Future<Invoice> updateInvoice(Invoice invoice) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _mockInvoices.indexWhere((i) => i.id == invoice.id);
    if (index != -1) {
      _mockInvoices[index] = invoice;
      return invoice;
    }
    throw Exception('Invoice not found');
  }

  Future<void> deleteInvoice(String id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    _mockInvoices.removeWhere((invoice) => invoice.id == id);
  }
} 