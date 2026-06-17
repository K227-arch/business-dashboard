import 'frappe_client.dart';

/// High-level typed methods that call specific ERPNext doctypes.
/// All methods return raw decoded JSON — repositories convert to models.
class FrappeApi {
  FrappeApi._();

  // ── Dashboard KPIs ─────────────────────────────────────────────────────

  /// Total billed amount from Sales Invoices for a given date range.
  /// Returns list of {name, grand_total, posting_date, customer, status}.
  static Future<List<dynamic>> getSalesInvoices({
    String? fromDate,
    String? toDate,
    String? status, // "Paid" | "Unpaid" | "Overdue" | "Cancelled"
    int limit = 100,
  }) async {
    final filters = <dynamic>[
      ['docstatus', '=', 1], // submitted only
    ];
    if (fromDate != null) filters.add(['posting_date', '>=', fromDate]);
    if (toDate != null) filters.add(['posting_date', '<=', toDate]);
    if (status != null) filters.add(['status', '=', status]);

    final res = await FrappeClient.getList(
      doctype: 'Sales Invoice',
      fields: [
        'name', 'customer', 'grand_total', 'net_total',
        'posting_date', 'status', 'outstanding_amount',
      ],
      filters: filters,
      orderBy: 'posting_date desc',
      limit: limit,
    );
    return res['data'] as List<dynamic>? ?? [];
  }

  /// Sales Invoice line items — fetched by getting each invoice's items.
  /// Uses parent document approach to avoid 403 on child table direct access.
  static Future<List<dynamic>> getSalesInvoiceItems({
    String? fromDate,
    String? toDate,
    int limit = 500,
  }) async {
    // Fetch parent invoices first
    final filters = <dynamic>[['docstatus', '=', 1]];
    if (fromDate != null) filters.add(['posting_date', '>=', fromDate]);
    if (toDate != null) filters.add(['posting_date', '<=', toDate]);

    final invoices = await FrappeClient.getList(
      doctype: 'Sales Invoice',
      fields: ['name'],
      filters: filters,
      orderBy: 'posting_date desc',
      limit: 200,
    );

    final invoiceList = invoices['data'] as List<dynamic>? ?? [];
    final allItems = <dynamic>[];

    // Fetch items from each invoice (batch to avoid too many requests)
    for (final inv in invoiceList.take(50)) {
      try {
        final doc = await FrappeClient.getDoc(
          doctype: 'Sales Invoice',
          name: inv['name'].toString(),
        );
        final items = doc['data']?['items'] as List<dynamic>? ?? [];
        allItems.addAll(items);
      } catch (_) {}
    }
    return allItems;
  }

  /// Count of customers created in a date range.
  static Future<List<dynamic>> getCustomers({
    String? fromDate,
    String? toDate,
    int limit = 50,
  }) async {
    final filters = <dynamic>[];
    if (fromDate != null) filters.add(['creation', '>=', fromDate]);
    if (toDate != null) filters.add(['creation', '<=', toDate]);
    final res = await FrappeClient.getList(
      doctype: 'Customer',
      fields: ['name', 'customer_name', 'creation'],
      filters: filters,
      orderBy: 'creation desc',
      limit: limit,
    );
    return res['data'] as List<dynamic>? ?? [];
  }

  /// Active Sales Orders (not yet fully delivered/billed).
  static Future<List<dynamic>> getActiveSalesOrders({int limit = 50}) async {
    final res = await FrappeClient.getList(
      doctype: 'Sales Order',
      fields: ['name', 'customer', 'grand_total', 'transaction_date', 'status'],
      filters: [
        ['docstatus', '=', 1],
        ['status', 'in', 'To Deliver and Bill,To Bill,To Deliver'],
      ],
      orderBy: 'transaction_date desc',
      limit: limit,
    );
    return res['data'] as List<dynamic>? ?? [];
  }

  /// Pending (unpaid) Sales Invoices.
  static Future<List<dynamic>> getPendingInvoices({int limit = 50}) async {
    final res = await FrappeClient.getList(
      doctype: 'Sales Invoice',
      fields: ['name', 'customer', 'grand_total', 'posting_date', 'due_date', 'status'],
      filters: [
        ['docstatus', '=', 1],
        ['status', 'in', 'Unpaid,Overdue'],
      ],
      orderBy: 'posting_date desc',
      limit: limit,
    );
    return res['data'] as List<dynamic>? ?? [];
  }

  // ── Transactions (Payment Entries) ─────────────────────────────────────

  /// Payment Entries — maps to the Transactions screen.
  static Future<List<dynamic>> getPaymentEntries({
    String? fromDate,
    String? toDate,
    String? paymentType, // "Receive" | "Pay"
    int limit = 50,
  }) async {
    final filters = <dynamic>[
      ['docstatus', '=', 1],
    ];
    if (fromDate != null) filters.add(['posting_date', '>=', fromDate]);
    if (toDate != null) filters.add(['posting_date', '<=', toDate]);
    if (paymentType != null) filters.add(['payment_type', '=', paymentType]);

    final res = await FrappeClient.getList(
      doctype: 'Payment Entry',
      fields: [
        'name', 'payment_type', 'party', 'party_name',
        'paid_amount', 'posting_date', 'remarks', 'docstatus',
      ],
      filters: filters,
      orderBy: 'posting_date desc',
      limit: limit,
    );
    return res['data'] as List<dynamic>? ?? [];
  }

  // ── Purchases (Purchase Invoices) ─────────────────────────────────────

  /// Purchase Invoices — maps to the Purchases screen.
  /// ERPNext doctype: Purchase Invoice (submitted, not cancelled).
  static Future<List<dynamic>> getPurchaseInvoices({
    String? fromDate,
    String? toDate,
    int limit = 50,
  }) async {
    final filters = <dynamic>[
      ['docstatus', '=', 1],
    ];
    if (fromDate != null) filters.add(['posting_date', '>=', fromDate]);
    if (toDate != null) filters.add(['posting_date', '<=', toDate]);

    final res = await FrappeClient.getList(
      doctype: 'Purchase Invoice',
      fields: [
        'name', 'supplier', 'supplier_name', 'total',
        'grand_total', 'posting_date', 'status', 'docstatus',
      ],
      filters: filters,
      orderBy: 'posting_date desc',
      limit: limit,
    );
    return res['data'] as List<dynamic>? ?? [];
  }

  /// Purchase Receipts — Stock > Purchase Receipt (submitted).
  static Future<List<dynamic>> getPurchaseReceipts({
    String? fromDate,
    String? toDate,
    int limit = 200,
  }) async {
    final filters = <dynamic>[['docstatus', '=', 1]];
    if (fromDate != null) filters.add(['posting_date', '>=', fromDate]);
    if (toDate != null) filters.add(['posting_date', '<=', toDate]);

    final res = await FrappeClient.getList(
      doctype: 'Purchase Receipt',
      fields: ['name', 'supplier', 'total', 'grand_total', 'posting_date', 'status'],
      filters: filters,
      orderBy: 'posting_date desc',
      limit: limit,
    );
    return res['data'] as List<dynamic>? ?? [];
  }

  /// Purchase Invoice line items for the Items breakdown.
  static Future<List<dynamic>> getPurchaseInvoiceItems({
    String? fromDate,
    String? toDate,
    int limit = 500,
  }) async {
    final filters = <dynamic>[
      ['docstatus', '=', 1],
    ];
    final res = await FrappeClient.getList(
      doctype: 'Purchase Invoice Item',
      fields: ['item_code', 'item_name', 'qty', 'amount', 'parent'],
      filters: filters,
      orderBy: 'amount desc',
      limit: limit,
    );
    return res['data'] as List<dynamic>? ?? [];
  }

  /// Purchase Receipt Items — from Stock > Purchase Receipt.
  /// Uses parent document approach to avoid 403 on child table direct access.
  static Future<List<dynamic>> getPurchaseReceiptItems({
    String? fromDate,
    String? toDate,
    int limit = 500,
  }) async {
    final filters = <dynamic>[['docstatus', '=', 1]];
    if (fromDate != null) filters.add(['posting_date', '>=', fromDate]);
    if (toDate != null) filters.add(['posting_date', '<=', toDate]);

    final receipts = await FrappeClient.getList(
      doctype: 'Purchase Receipt',
      fields: ['name'],
      filters: filters,
      orderBy: 'posting_date desc',
      limit: 200,
    );

    final receiptList = receipts['data'] as List<dynamic>? ?? [];
    final allItems = <dynamic>[];

    for (final receipt in receiptList.take(50)) {
      try {
        final doc = await FrappeClient.getDoc(
          doctype: 'Purchase Receipt',
          name: receipt['name'].toString(),
        );
        final items = doc['data']?['items'] as List<dynamic>? ?? [];
        allItems.addAll(items);
      } catch (_) {}
    }
    return allItems;
  }

  // ── Activity (Activity Log + Comments) ────────────────────────────────

  /// Recent activity from Activity Log and Comments.
  /// Replaces Communication which requires special permissions.
  static Future<List<dynamic>> getRecentActivity({int limit = 10}) async {
    final activityFuture = FrappeClient.getList(
      doctype: 'Activity Log',
      fields: ['name', 'subject', 'operation', 'reference_doctype', 'user', 'creation'],
      filters: [],
      orderBy: 'creation desc',
      limit: limit,
    );

    final commentFuture = FrappeClient.getList(
      doctype: 'Comment',
      fields: ['name', 'content', 'comment_type', 'reference_doctype', 'reference_name', 'owner', 'creation'],
      filters: [['comment_type', 'in', 'Comment,Info,Label']],
      orderBy: 'creation desc',
      limit: limit,
    );

    final results = await Future.wait([activityFuture, commentFuture]);
    final activities = results[0]['data'] as List<dynamic>? ?? [];
    final comments   = results[1]['data'] as List<dynamic>? ?? [];

    // Merge and tag source
    final merged = [
      ...activities.map((a) => {...(a as Map<String, dynamic>), '_source': 'activity'}),
      ...comments.map((c)  => {...(c as Map<String, dynamic>), '_source': 'comment'}),
    ];

    // Sort by creation desc
    merged.sort((a, b) {
      final da = DateTime.tryParse(a['creation']?.toString() ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b['creation']?.toString() ?? '') ?? DateTime(2000);
      return db.compareTo(da);
    });

    return merged.take(limit).toList();
  }

  // ── Sales summary helper ───────────────────────────────────────────────

  /// Fetch the ERPNext "Sales Analytics" report data.
  /// value_type: 'Net Sales' | 'Gross Profit' | 'Quantity'
  static Future<Map<String, dynamic>> getSalesAnalytics({
    String fromFiscalYear = '2026',
    String toFiscalYear = '2026',
    String periodicity = 'Monthly',
    String valueType = 'Net Sales',
  }) async {
    return FrappeClient.callMethod(
      method: 'frappe.desk.query_report.run',
      params: {
        'report_name': 'Sales Analytics',
        'filters': '{"from_fiscal_year":"$fromFiscalYear",'
            '"to_fiscal_year":"$toFiscalYear",'
            '"periodicity":"$periodicity",'
            '"based_on":"Item","value_based_on":"$valueType"}',
      },
    );
  }
}
