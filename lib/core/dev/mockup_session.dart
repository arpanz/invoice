import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../database/db_provider.dart';
import '../models/currency_model.dart';

/// Temporary mockup mode for screenshot sessions.
///
/// Set this to false after creating screenshots.
class MockupSession {
  MockupSession._();

  static const bool enabled = true;

  static bool get forceProForSession => enabled;

  static Future<void> bootstrap() async {
    if (!enabled) return;

    await _seedPreferences();
    await _seedDatabaseIfNeeded();
  }

  static Future<void> _seedPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Skip onboarding for screenshot runs.
    await prefs.setBool('onboarding_complete', true);

    // Force USD defaults for this mockup session.
    final usd = SupportedCurrencies.all.firstWhere((c) => c.code == 'USD');
    await prefs.setString('user_currency', jsonEncode(usd.toJson()));

    await prefs.setString('biz_name', 'Northstar Design Studio');
    await prefs.setString(
      'biz_address',
      '245 Market Street, San Francisco, CA 94105',
    );
    await prefs.setString('biz_phone', '+1 (415) 555-0139');
    await prefs.setString('biz_email', 'accounts@northstardesign.com');
    await prefs.remove('biz_gstin');
    await prefs.setString('biz_bank_name', 'Chase Bank');
    await prefs.setString('biz_account', '7894561230');
    await prefs.setString('biz_ifsc', '021000021');
  }

  static Future<void> _seedDatabaseIfNeeded() async {
    final db = await DbProvider.database;

    final now = DateTime.now();
    int daysAgo(int days) =>
        now.subtract(Duration(days: days)).millisecondsSinceEpoch;
    int daysAhead(int days) =>
        now.add(Duration(days: days)).millisecondsSinceEpoch;

    const c1 = 'demo-client-1';
    const c2 = 'demo-client-2';
    const c3 = 'demo-client-3';

    const i1 = 'demo-invoice-1';
    const i2 = 'demo-invoice-2';
    const i3 = 'demo-invoice-3';
    const i4 = 'demo-invoice-4';
    const i5 = 'demo-invoice-5';

    await db.transaction((txn) async {
      // Ensure deterministic demo content for screenshot sessions.
      await txn.delete(
        DbProvider.tableLineItems,
        where: 'invoice_id IN (?, ?, ?, ?, ?)',
        whereArgs: [i1, i2, i3, i4, i5],
      );
      await txn.delete(
        DbProvider.tableInvoices,
        where: 'id IN (?, ?, ?, ?, ?)',
        whereArgs: [i1, i2, i3, i4, i5],
      );
      await txn.delete(
        DbProvider.tableClients,
        where: 'id IN (?, ?, ?)',
        whereArgs: [c1, c2, c3],
      );

      final clients = <Map<String, dynamic>>[
        {
          'id': c1,
          'name': 'Harbor and Pine Interiors',
          'email': 'billing@harborpine.com',
          'phone': '+1 (212) 555-0174',
          'address': '1200 Broadway, New York, NY 10001',
          'gstin': null,
          'created_at': daysAgo(180),
        },
        {
          'id': c2,
          'name': 'Maple Street Cafe',
          'email': 'owner@maplestreetcafe.com',
          'phone': '+1 (206) 555-0132',
          'address': '87 Pine Avenue, Seattle, WA 98101',
          'gstin': null,
          'created_at': daysAgo(150),
        },
        {
          'id': c3,
          'name': 'Summit Tech Labs',
          'email': 'ap@summittechlabs.com',
          'phone': '+1 (512) 555-0198',
          'address': '410 Congress Ave, Austin, TX 78701',
          'gstin': null,
          'created_at': daysAgo(120),
        },
      ];

      for (final client in clients) {
        await txn.insert(
          DbProvider.tableClients,
          client,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final invoices = <Map<String, dynamic>>[
        {
          'id': i1,
          'invoice_number': 'INV-1001',
          'client_id': c1,
          'client_name': 'Harbor and Pine Interiors',
          'client_email': 'billing@harborpine.com',
          'client_phone': '+1 (212) 555-0174',
          'client_address': '1200 Broadway, New York, NY 10001',
          'client_gstin': null,
          'invoice_date': daysAgo(4),
          'due_date': daysAhead(10),
          'subtotal': 4200.0,
          'discount_type': 'none',
          'discount_value': 0.0,
          'discount_amount': 0.0,
          'sgst_rate': 0.0,
          'cgst_rate': 0.0,
          'igst_rate': 0.0,
          'tax_amount': 0.0,
          'grand_total': 4200.0,
          'status': 'paid',
          'notes': 'Thank you for your business.',
          'currency': 'USD',
          'created_at': daysAgo(4),
          'updated_at': daysAgo(1),
        },
        {
          'id': i2,
          'invoice_number': 'INV-1002',
          'client_id': c2,
          'client_name': 'Maple Street Cafe',
          'client_email': 'owner@maplestreetcafe.com',
          'client_phone': '+1 (206) 555-0132',
          'client_address': '87 Pine Avenue, Seattle, WA 98101',
          'client_gstin': null,
          'invoice_date': daysAgo(8),
          'due_date': daysAhead(10),
          'subtotal': 2300.0,
          'discount_type': 'percentage',
          'discount_value': 10.0,
          'discount_amount': 230.0,
          'sgst_rate': 0.0,
          'cgst_rate': 0.0,
          'igst_rate': 0.0,
          'tax_amount': 0.0,
          'grand_total': 2070.0,
          'status': 'unpaid',
          'notes': 'Net terms: payment due in 10 days.',
          'currency': 'USD',
          'created_at': daysAgo(8),
          'updated_at': daysAgo(8),
        },
        {
          'id': i3,
          'invoice_number': 'INV-1003',
          'client_id': c3,
          'client_name': 'Summit Tech Labs',
          'client_email': 'ap@summittechlabs.com',
          'client_phone': '+1 (512) 555-0198',
          'client_address': '410 Congress Ave, Austin, TX 78701',
          'client_gstin': null,
          'invoice_date': daysAgo(21),
          'due_date': daysAgo(6),
          'subtotal': 1850.0,
          'discount_type': 'flat',
          'discount_value': 100.0,
          'discount_amount': 100.0,
          'sgst_rate': 0.0,
          'cgst_rate': 0.0,
          'igst_rate': 0.0,
          'tax_amount': 0.0,
          'grand_total': 1750.0,
          'status': 'overdue',
          'notes': 'Second payment reminder sent by email.',
          'currency': 'USD',
          'created_at': daysAgo(21),
          'updated_at': daysAgo(5),
        },
        {
          'id': i4,
          'invoice_number': 'INV-1004',
          'client_id': c1,
          'client_name': 'Harbor and Pine Interiors',
          'client_email': 'billing@harborpine.com',
          'client_phone': '+1 (212) 555-0174',
          'client_address': '1200 Broadway, New York, NY 10001',
          'client_gstin': null,
          'invoice_date': daysAgo(40),
          'due_date': daysAgo(25),
          'subtotal': 1200.0,
          'discount_type': 'none',
          'discount_value': 0.0,
          'discount_amount': 0.0,
          'sgst_rate': 0.0,
          'cgst_rate': 0.0,
          'igst_rate': 0.0,
          'tax_amount': 0.0,
          'grand_total': 1200.0,
          'status': 'paid',
          'notes': null,
          'currency': 'USD',
          'created_at': daysAgo(40),
          'updated_at': daysAgo(35),
        },
        {
          'id': i5,
          'invoice_number': 'INV-1005',
          'client_id': c3,
          'client_name': 'Summit Tech Labs',
          'client_email': 'ap@summittechlabs.com',
          'client_phone': '+1 (512) 555-0198',
          'client_address': '410 Congress Ave, Austin, TX 78701',
          'client_gstin': null,
          'invoice_date': daysAgo(2),
          'due_date': daysAhead(5),
          'subtotal': 6800.0,
          'discount_type': 'flat',
          'discount_value': 300.0,
          'discount_amount': 300.0,
          'sgst_rate': 0.0,
          'cgst_rate': 0.0,
          'igst_rate': 0.0,
          'tax_amount': 0.0,
          'grand_total': 6500.0,
          'status': 'unpaid',
          'notes': 'Retainer due before final delivery.',
          'currency': 'USD',
          'created_at': daysAgo(2),
          'updated_at': daysAgo(2),
        },
      ];

      for (final invoice in invoices) {
        await txn.insert(
          DbProvider.tableInvoices,
          invoice,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      final lineItems = <Map<String, dynamic>>[
        {
          'id': 'demo-li-1',
          'invoice_id': i1,
          'description': 'Brand Identity Package',
          'quantity': 1.0,
          'unit_price': 1800.0,
          'total': 1800.0,
          'sort_order': 0,
        },
        {
          'id': 'demo-li-2',
          'invoice_id': i1,
          'description': 'Website UI Refresh',
          'quantity': 1.0,
          'unit_price': 2400.0,
          'total': 2400.0,
          'sort_order': 1,
        },
        {
          'id': 'demo-li-3',
          'invoice_id': i2,
          'description': 'Monthly Social Media Management',
          'quantity': 1.0,
          'unit_price': 2000.0,
          'total': 2000.0,
          'sort_order': 0,
        },
        {
          'id': 'demo-li-4',
          'invoice_id': i2,
          'description': 'Photo and Reels Add-ons',
          'quantity': 3.0,
          'unit_price': 100.0,
          'total': 300.0,
          'sort_order': 1,
        },
        {
          'id': 'demo-li-5',
          'invoice_id': i3,
          'description': 'Website Maintenance',
          'quantity': 2.0,
          'unit_price': 600.0,
          'total': 1200.0,
          'sort_order': 0,
        },
        {
          'id': 'demo-li-6',
          'invoice_id': i3,
          'description': 'Cloud Hosting Renewal',
          'quantity': 1.0,
          'unit_price': 650.0,
          'total': 650.0,
          'sort_order': 1,
        },
        {
          'id': 'demo-li-7',
          'invoice_id': i4,
          'description': 'Design Consultation',
          'quantity': 1.0,
          'unit_price': 900.0,
          'total': 900.0,
          'sort_order': 0,
        },
        {
          'id': 'demo-li-8',
          'invoice_id': i4,
          'description': 'Moodboard and Floor Plan',
          'quantity': 1.0,
          'unit_price': 300.0,
          'total': 300.0,
          'sort_order': 1,
        },
        {
          'id': 'demo-li-9',
          'invoice_id': i5,
          'description': 'Mobile App UI Sprint',
          'quantity': 1.0,
          'unit_price': 4500.0,
          'total': 4500.0,
          'sort_order': 0,
        },
        {
          'id': 'demo-li-10',
          'invoice_id': i5,
          'description': 'QA and Launch Support',
          'quantity': 1.0,
          'unit_price': 2300.0,
          'total': 2300.0,
          'sort_order': 1,
        },
      ];

      for (final item in lineItems) {
        await txn.insert(
          DbProvider.tableLineItems,
          item,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
