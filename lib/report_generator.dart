// lib/report_generator.dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class RestaurantReputationReport {
  final String restaurantName;
  final String location;
  final double avgNPS;
  final double avgCSAT;
  final double avgCES;
  final String analysis;
  final List<Map<String, dynamic>> feedbackList;

  RestaurantReputationReport({
    required this.restaurantName,
    required this.location,
    required this.avgNPS,
    required this.avgCSAT,
    required this.avgCES,
    required this.analysis,
    required this.feedbackList,
  });

  Future<File> generatePdf() async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(now);

    // Title Section
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text("CX Tracker", style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text("Restaurant Reputation Report", style: pw.TextStyle(fontSize: 16, color: PdfColors.grey)),
                  pw.Text(formattedDate, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(),
          pw.SizedBox(height: 20),

          // Restaurant Info
          pw.Text("Restaurant: $restaurantName", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Text("Location: $location", style: pw.TextStyle(fontSize: 14, color: PdfColors.grey)),
          pw.SizedBox(height: 25),

          // Metrics Summary
          pw.Text("Performance Summary", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
          pw.SizedBox(height: 10),
          _buildMetricRow("Net Promoter Score (NPS)", avgNPS, context),
          _buildMetricRow("Customer Satisfaction (CSAT)", avgCSAT, context),
          _buildMetricRow("Customer Effort Score (CES)", avgCES, context),
          pw.SizedBox(height: 25),

          // Analysis
          pw.Text("AI-Powered Insights", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
          pw.SizedBox(height: 8),
          pw.Text(analysis, style: pw.TextStyle(fontSize: 12, color: PdfColors.black)),
          pw.SizedBox(height: 25),

          // Feedback
          if (feedbackList.isNotEmpty) ...[
            pw.Text("Recent Customer Feedback", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo)),
            pw.SizedBox(height: 10),
            for (var f in feedbackList.take(5))
              pw.Column(
                children: [
                  pw.Text(f["comment"] ?? "", style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic)),
                  pw.Text("– ${f["user"] ?? "Anonymous"}, ${f["date"].toString().split('T').first}", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  pw.SizedBox(height: 12),
                ],
              ),
          ],
          pw.SizedBox(height: 30),
          pw.Text("Generated via CX Tracker Mobile App", style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        ],
      ),
    );

    // Save to file
    final output = await getApplicationDocumentsDirectory();
    final file = File("${output.path}/${restaurantName.replaceAll(RegExp(r'[^\w\s]'), '')}_Reputation_Report.pdf");
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _buildMetricRow(String label, double value, pw.Context context) {
    String getValueLabel(double v) {
      if (label.contains("NPS")) {
        if (v <= 6) return "Detractor";
        if (v <= 8) return "Passive";
        return "Promoter";
      } else if (label.contains("CSAT") || label.contains("CES")) {
        if (v <= 4) return "Poor";
        if (v <= 7) return "Fair";
        return "Excellent";
      }
      return "";
    }

    final color = value >= 8 ? PdfColors.green : value >= 5 ? PdfColors.orange : PdfColors.red;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 100,
          child: pw.Text(label, style: pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
        ),
        pw.Text("${value.toStringAsFixed(1)}/10", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(width: 10),
        pw.Text(getValueLabel(value), style: pw.TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}