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

  /// Sales Invoice line items for the Items breakdown.
  /// Note: Sales Invoice Item is a child table without posting_date.
  static Future<List<dynamic>> getSalesInvoiceItems({
    int limit = 500,
  }) async {
    final res = await FrappeClient.getList(
      doctype: 'Sales Invoice Item',
      fields: ['item_code', 'item_name', 'qty', 'amount', 'parent'],
      filters: [['docstatus', '=', 1]],
      orderBy: 'amount desc',
      limit: limit,
    );
    return res['data'] as List<dynamic>? ?? [];
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

  // ── Activity (Communications / Activity Log) ───────────────────────────

  /// Recent Communications — used as the activity feed.
  static Future<List<dynamic>> getRecentActivity({int limit = 10}) async {
    final res = await FrappeClient.getList(
      doctype: 'Communication',
      fields: ['name', 'subject', 'content', 'creation', 'communication_type'],
      filters: [['sent_or_received', '=', 'Received']],
      orderBy: 'creation desc',
      limit: limit,
    );
    return res['data'] as List<dynamic>? ?? [];
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
