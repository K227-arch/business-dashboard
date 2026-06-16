import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';

class CredentialsScreen extends StatefulWidget {
  final AuthProvider auth;
  const CredentialsScreen({super.key, required this.auth});

  @override
  State<CredentialsScreen> createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends State<CredentialsScreen> {
  final _usrController = TextEditingController();
  final _pwdController = TextEditingController();
  final _formKey       = GlobalKey<FormState>();
  bool _loading    = false;
  bool _obscurePwd = true;

  @override
  void initState() {
    super.initState();
    if (widget.auth.lastEmail.isNotEmpty) {
      _usrController.text = widget.auth.lastEmail;
    }
  }

  @override
  void dispose() {
    _usrController.dispose();
    _pwdController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await widget.auth.login(
      usr: _usrController.text.trim(),
      pwd: _pwdController.text,
    );
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
                  const SizedBox(height: 24),

                  // ── Icon ─────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.lock_outline_rounded,
                        color: scheme.primary, size: 48),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Sign in',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.auth.baseUrl,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.45),
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 32),

                  // ── Email / Username ─────────────────────────────────
                  TextFormField(
                    controller: _usrController,
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Email or Username',
                      prefixIcon:
                          const Icon(Icons.person_outline_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).cardTheme.color,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter your email or username'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Password ─────────────────────────────────────────
                  TextFormField(
                    controller: _pwdController,
                    obscureText: _obscurePwd,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePwd
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _obscurePwd = !_obscurePwd),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Theme.of(context).cardTheme.color,
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Please enter your password' : null,
                    onFieldSubmitted: (_) => _login(),
                  ),

                  // ── Error ─────────────────────────────────────────────
                  if (widget.auth.error != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEA4335).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFEA4335)
                                .withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Color(0xFFEA4335), size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.auth.error!,
                              style: const TextStyle(
                                  color: Color(0xFFEA4335), fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Login button ─────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _loading ? null : _login,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Login',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),

                  // ── Change URL ────────────────────────────────────────
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => widget.auth.logout(),
                    child: Text(
                      'Change server URL',
                      style: TextStyle(
                          color: scheme.onSurface.withValues(alpha: 0.5),
                          fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
