import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/job_appointment.dart';
import '../theme/app_colors.dart';
import '../widgets/dashboard_card.dart';

class InvoicePreviewScreen extends StatelessWidget {
  final JobAppointment job;

  const InvoicePreviewScreen({
    super.key,
    required this.job,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Invoice Preview',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf, color: AppColors.primaryPink),
            onPressed: () => _exportToPDF(context),
            tooltip: 'Export as PDF',
          ),
          IconButton(
            icon: Icon(Icons.print, color: AppColors.primaryPink),
            onPressed: () => _printInvoice(context),
            tooltip: 'Print Invoice',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice Header
            DashboardCard(
              title: 'Invoice Details',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INVOICE',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryPink,
                            ),
                          ),
                          Text(
                            'Job #${job.id.substring(0, 8).toUpperCase()}',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Date',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d, y').format(job.startTime),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  // Customer & Service Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CUSTOMER',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              job.customerName,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VEHICLE',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              job.vehicleInfo,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Service Details
            DashboardCard(
              title: 'Service Details',
              child: Column(
                children: [
                  _buildServiceDetailRow(
                    'Service Type',
                    job.serviceType,
                  ),
                  const Divider(height: 24),
                  _buildServiceDetailRow(
                    'Mechanic',
                    job.mechanicName,
                  ),
                  const Divider(height: 24),
                  _buildServiceDetailRow(
                    'Service Duration',
                    '${DateFormat('h:mm a').format(job.startTime)} - ${DateFormat('h:mm a').format(job.endTime)}',
                  ),
                  if (job.notes != null) ...[
                    const Divider(height: 24),
                    _buildServiceDetailRow(
                      'Notes',
                      job.notes!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Cost Summary
            if (job.estimatedCost != null)
              DashboardCard(
                title: 'Cost Summary',
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Service Cost',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'RM ${job.estimatedCost!.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          'RM ${job.estimatedCost!.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryPink,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Terms and Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.softPink,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terms & Conditions',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Payment is due upon completion of service. We accept cash, credit cards, and bank transfers.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToPDF(BuildContext context) async {
    try {
      // Create PDF document
      final pdf = pw.Document();

      // Add content to PDF
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'INVOICE',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          'Job #${job.id.substring(0, 8).toUpperCase()}',
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Date',
                          style: const pw.TextStyle(fontSize: 14),
                        ),
                        pw.Text(
                          DateFormat('MMM d, y').format(job.startTime),
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Divider(height: 32),

                // Customer & Service Info
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'CUSTOMER',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            job.customerName,
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'VEHICLE',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Text(
                            job.vehicleInfo,
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Service Details
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Service Details',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 16),
                      _buildPDFServiceDetailRow('Service Type', job.serviceType),
                      pw.Divider(),
                      _buildPDFServiceDetailRow('Mechanic', job.mechanicName),
                      pw.Divider(),
                      _buildPDFServiceDetailRow(
                        'Service Duration',
                        '${DateFormat('h:mm a').format(job.startTime)} - ${DateFormat('h:mm a').format(job.endTime)}',
                      ),
                      if (job.notes != null) ...[
                        pw.Divider(),
                        _buildPDFServiceDetailRow('Notes', job.notes!),
                      ],
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Cost Summary
                if (job.estimatedCost != null)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(16),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Service Cost'),
                            pw.Text(
                              'RM ${job.estimatedCost!.toStringAsFixed(2)}',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        ),
                        pw.Divider(),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Total',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                            pw.Text(
                              'RM ${job.estimatedCost!.toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                pw.SizedBox(height: 32),

                // Terms and Footer
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Terms & Conditions',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Payment is due upon completion of service. We accept cash, credit cards, and bank transfers.',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Get directory for saving file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/invoice_${job.id}.pdf');

      // Save PDF file
      await file.writeAsBytes(await pdf.save());

      // Share the PDF file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Invoice for ${job.customerName}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to export PDF: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  Future<void> _printInvoice(BuildContext context) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) async {
          // Create PDF document
          final pdf = pw.Document();

          // Add content to PDF
          pdf.addPage(
            pw.Page(
              pageFormat: format,
              build: (pw.Context context) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Header
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'INVOICE',
                                style: pw.TextStyle(
                                  fontSize: 24,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.Text(
                                'Job #${job.id.substring(0, 8).toUpperCase()}',
                                style: const pw.TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                'Date',
                                style: const pw.TextStyle(fontSize: 14),
                              ),
                              pw.Text(
                                DateFormat('MMM d, y').format(job.startTime),
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 20),

                      // Customer & Vehicle Info
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'CUSTOMER',
                                  style: const pw.TextStyle(
                                    fontSize: 12,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                                pw.SizedBox(height: 8),
                                pw.Text(
                                  job.customerName,
                                  style: pw.TextStyle(
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  'VEHICLE',
                                  style: const pw.TextStyle(
                                    fontSize: 12,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                                pw.SizedBox(height: 8),
                                pw.Text(
                                  job.vehicleInfo,
                                  style: pw.TextStyle(
                                    fontSize: 16,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 30),

                      // Service Details
                      pw.Container(
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: PdfColors.grey300),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Service Details',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 16),
                            _buildPDFServiceDetailRow('Service Type', job.serviceType),
                            pw.Divider(),
                            _buildPDFServiceDetailRow('Mechanic', job.mechanicName),
                            pw.Divider(),
                            _buildPDFServiceDetailRow(
                              'Service Duration',
                              '${DateFormat('h:mm a').format(job.startTime)} - ${DateFormat('h:mm a').format(job.endTime)}',
                            ),
                            if (job.notes != null) ...[
                              pw.Divider(),
                              _buildPDFServiceDetailRow('Notes', job.notes!),
                            ],
                          ],
                        ),
                      ),
                      pw.SizedBox(height: 20),

                      // Cost Summary
                      if (job.estimatedCost != null)
                        pw.Container(
                          padding: const pw.EdgeInsets.all(16),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: PdfColors.grey300),
                            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                          ),
                          child: pw.Column(
                            children: [
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text('Service Cost'),
                                  pw.Text(
                                    'RM ${job.estimatedCost!.toStringAsFixed(2)}',
                                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                                  ),
                                ],
                              ),
                              pw.Divider(),
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(
                                    'Total',
                                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.Text(
                                    'RM ${job.estimatedCost!.toStringAsFixed(2)}',
                                    style: pw.TextStyle(
                                      fontSize: 18,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                      pw.SizedBox(height: 30),

                      // Terms and Footer
                      pw.Container(
                        padding: const pw.EdgeInsets.all(16),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.grey100,
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Terms & Conditions',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 8),
                            pw.Text(
                              'Payment is due upon completion of service. We accept cash, credit cards, and bank transfers.',
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
          return pdf.save();
        },
        name: 'Invoice_${job.id}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to print: ${e.toString()}',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  pw.Widget _buildPDFServiceDetailRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 120,
          child: pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 14),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textDark,
            ),
          ),
        ),
      ],
    );
  }
}
