// lib/core/services/report_pdf.dart
// Builds simple tabular PDF reports and opens the platform print/share
// sheet (save as PDF, print, AirDrop, email…) on every platform.
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportSection {
  final String heading;
  final List<String> columns;
  final List<List<String>> rows;

  /// Free text shown under the heading (used when [columns] is empty).
  final String? text;

  const ReportSection(this.heading,
      {this.columns = const [], this.rows = const [], this.text});
}

class ReportPdf {
  ReportPdf._();

  static Future<void> share({
    required String title,
    String? subtitle,
    required List<ReportSection> sections,
    String? fileName,
  }) async {
    final doc =
        pw.Document(title: title, author: 'Ray of Hope Center for Autism');
    final now = DateTime.now();
    final stamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    const purple = PdfColor.fromInt(0xFF7B2FBE);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (ctx) => pw.Container(
        padding: const pw.EdgeInsets.only(bottom: 8),
        decoration: const pw.BoxDecoration(
            border:
                pw.Border(bottom: pw.BorderSide(color: purple, width: 1.5))),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Ray of Hope Center for Autism',
                style: pw.TextStyle(
                    color: purple, fontWeight: pw.FontWeight.bold)),
            pw.Text('Generated $stamp', style: const pw.TextStyle(fontSize: 9)),
          ],
        ),
      ),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9)),
      ),
      build: (ctx) => [
        pw.SizedBox(height: 12),
        pw.Text(title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        if (subtitle != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(subtitle, style: const pw.TextStyle(fontSize: 11)),
        ],
        for (final s in sections) ...[
          pw.SizedBox(height: 18),
          pw.Text(s.heading,
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold, color: purple)),
          pw.SizedBox(height: 6),
          if (s.text != null)
            pw.Text(s.text!, style: const pw.TextStyle(fontSize: 10)),
          if (s.columns.isNotEmpty)
            s.rows.isEmpty
                ? pw.Text('No records.',
                    style: const pw.TextStyle(fontSize: 10))
                : pw.TableHelper.fromTextArray(
                    headers: s.columns,
                    data: s.rows,
                    headerStyle: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white),
                    headerDecoration: const pw.BoxDecoration(color: purple),
                    cellStyle: const pw.TextStyle(fontSize: 9),
                    cellPadding: const pw.EdgeInsets.symmetric(
                        horizontal: 4, vertical: 3),
                    oddRowDecoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFFF5F0FA)),
                  ),
        ],
      ],
    ));

    final bytes = await doc.save();
    final name = fileName ??
        '${title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}_$stamp.pdf';
    await Printing.sharePdf(bytes: bytes, filename: name);
  }
}
