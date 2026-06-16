import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../domain/entities/bill_entity.dart';

class OcrService {
  final _recognizer = TextRecognizer();

  Future<OcrExtractedData> extractFromImage(String imagePath) async {
    final inputImage = InputImage.fromFile(File(imagePath));
    final recognized = await _recognizer.processImage(inputImage);
    final rawText = recognized.text;

    return _parseText(rawText);
  }

  Future<OcrExtractedData> extractFromText(String rawText) async {
    return _parseText(rawText);
  }

  OcrExtractedData _parseText(String rawText) {
    final lines = rawText.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    final lower = rawText.toLowerCase();

    return OcrExtractedData(
      productName: _extractProductName(lines),
      billNumber: _extractBillNumber(rawText),
      purchaseDate: _extractDate(rawText),
      purchaseAmount: _extractAmount(rawText),
      taxAmount: _extractTaxAmount(rawText),
      gstNumber: _extractGst(rawText),
      storeName: _extractStoreName(lines),
      serialNumber: _extractSerial(rawText),
      imeiNumber: _extractImei(rawText),
      warrantyMonths: _extractWarranty(lower),
      rawText: rawText,
      confidence: _calculateConfidence(rawText),
    );
  }

  String? _extractProductName(List<String> lines) {
    // Take the first non-trivial line as product name (heuristic)
    for (final line in lines.take(5)) {
      if (line.length > 5 && !RegExp(r'^\d').hasMatch(line)) {
        return line;
      }
    }
    return null;
  }

  String? _extractBillNumber(String text) {
    final patterns = [
      RegExp(r'(?:invoice|bill|receipt|inv)\s*[#:no.]*\s*([A-Z0-9/-]+)', caseSensitive: false),
      RegExp(r'(?:order|ref)\s*[#:no.]*\s*([A-Z0-9/-]+)', caseSensitive: false),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) return m.group(1);
    }
    return null;
  }

  DateTime? _extractDate(String text) {
    final patterns = [
      RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{4})'),
      RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})'),
      RegExp(r'(\d{1,2})\s+(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+(\d{4})', caseSensitive: false),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        try {
          if (m.groupCount == 3) {
            final g1 = int.parse(m.group(1)!);
            final g2 = int.parse(m.group(2)!);
            final g3 = int.parse(m.group(3)!);
            if (g1 > 1000) return DateTime(g1, g2, g3);
            return DateTime(g3, g2, g1);
          }
        } catch (_) {}
      }
    }
    return null;
  }

  double? _extractAmount(String text) {
    final patterns = [
      RegExp(r'(?:total|amount|grand total|payable)[:\s]*[₹Rs.]*\s*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'[₹Rs.]\s*([\d,]+\.?\d{2})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) {
        final cleaned = m.group(1)!.replaceAll(',', '');
        return double.tryParse(cleaned);
      }
    }
    return null;
  }

  double? _extractTaxAmount(String text) {
    final p = RegExp(r'(?:gst|tax|cgst|sgst|igst)[:\s]*[₹Rs.]*\s*([\d,]+\.?\d*)', caseSensitive: false);
    final m = p.firstMatch(text);
    if (m != null) {
      return double.tryParse(m.group(1)!.replaceAll(',', ''));
    }
    return null;
  }

  String? _extractGst(String text) {
    final p = RegExp(r'[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}');
    return p.firstMatch(text)?.group(0);
  }

  String? _extractStoreName(List<String> lines) {
    // Usually the first prominent line is the store name
    if (lines.isNotEmpty && lines.first.length > 3) return lines.first;
    return null;
  }

  String? _extractSerial(String text) {
    final p = RegExp(r'(?:serial|s/n|s\.n\.)[:\s]*([A-Z0-9]{8,})', caseSensitive: false);
    return p.firstMatch(text)?.group(1);
  }

  String? _extractImei(String text) {
    final p = RegExp(r'IMEI[:\s]*(\d{15})');
    return p.firstMatch(text)?.group(1);
  }

  int? _extractWarranty(String lowerText) {
    final patterns = [
      RegExp(r'(\d+)\s*year\s*warrant', caseSensitive: false),
      RegExp(r'(\d+)\s*month\s*warrant', caseSensitive: false),
    ];

    for (int i = 0; i < patterns.length; i++) {
      final m = patterns[i].firstMatch(lowerText);
      if (m != null) {
        final val = int.tryParse(m.group(1)!);
        if (val != null) return i == 0 ? val * 12 : val;
      }
    }
    return null;
  }

  double _calculateConfidence(String text) {
    int score = 0;
    if (text.contains(RegExp(r'[₹Rs.]'))) score += 20;
    if (text.contains(RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{4}'))) score += 20;
    if (text.toLowerCase().contains('invoice') || text.toLowerCase().contains('bill')) score += 20;
    if (text.contains(RegExp(r'[0-9]{2}[A-Z]{5}[0-9]{4}'))) score += 20;
    if (text.toLowerCase().contains('total') || text.toLowerCase().contains('amount')) score += 20;
    return score.toDouble();
  }

  void dispose() {
    _recognizer.close();
  }
}
