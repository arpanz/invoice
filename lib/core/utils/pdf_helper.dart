import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PdfHelper {
  PdfHelper._();

  static Future<String> getInvoicesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final invoicesDir = Directory('${appDir.path}/invoices');
    if (!await invoicesDir.exists()) {
      await invoicesDir.create(recursive: true);
    }
    return invoicesDir.path;
  }

  static Future<String> savePdf(List<int> bytes, String invoiceNumber) async {
    final dir = await getInvoicesDirectory();
    final sanitized = invoiceNumber.replaceAll(RegExp(r'[^\w-]'), '_');
    final filePath = '$dir/Invoice_$sanitized.pdf';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }

  static Future<bool> deletePdf(String invoiceNumber) async {
    try {
      final dir = await getInvoicesDirectory();
      final sanitized = invoiceNumber.replaceAll(RegExp(r'[^\w-]'), '_');
      final file = File('$dir/Invoice_$sanitized.pdf');
      if (await file.exists()) {
        await file.delete();
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getPdfPath(String invoiceNumber) async {
    final dir = await getInvoicesDirectory();
    final sanitized = invoiceNumber.replaceAll(RegExp(r'[^\w-]'), '_');
    final file = File('$dir/Invoice_$sanitized.pdf');
    if (await file.exists()) {
      return file.path;
    }
    return null;
  }
}
