import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  final AuthProvider auth;
  const LoginScreen({super.key, required this.auth});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _urlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _urlController.text = 'https://clinicplus.techwise.africa/';
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await widget.auth.setBaseUrl(_urlController.text.trim());
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5B5EA6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 80,
                      height: 80,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sales Plus',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your ERPNext instance URL',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Base URL',
                      hintText: 'https://your-erpnext.frappe.cloud',
                      prefixIcon: const Icon(Icons.link_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).cardTheme.color,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter a URL';
                      }
                      if (!v.trim().startsWith('http://') &&
                          !v.trim().startsWith('https://')) {
                        return 'URL must start with http:// or https://';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _connect(),
                  ),
                  const SizedBox(height: 10),
                  // ── Quick-select URL chips ─────────────────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _UrlChip(
                        label: 'Clinic Plus',
                        url: 'https://clinicplus.techwise.africa',
                        controller: _urlController,
                      ),
                      _UrlChip(
                        label: 'Coles',
                        url: 'https://coles.techwise.africa',
                        controller: _urlController,
                      ),
                    ],
                  ),
                  if (widget.auth.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      widget.auth.error!,
                      style: const TextStyle(
                          color: Color(0xFFEA4335), fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _loading ? null : _connect,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Connect',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


// ── URL suggestion chip ─────────────────────────────────────────────────────
class _UrlChip extends StatelessWidget {
  final String label;
  final String url;
  final TextEditingController controller;

  const _UrlChip({
    required this.label,
    required this.url,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = controller.text.trim().replaceAll(RegExp(r'/+$'), '') ==
        url.replaceAll(RegExp(r'/+$'), '');
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => controller.text = url,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? scheme.primary.withValues(alpha: 0.12)
              : scheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? scheme.primary : scheme.onSurface.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}
