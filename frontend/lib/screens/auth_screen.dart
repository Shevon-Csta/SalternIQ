import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../theme.dart';

// ── Login Screen ──────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  Future<void> _login() async {
    setState(() => _error = null);
    try {
      await context.read<AuthProvider>().login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.accent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.water_drop_rounded,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 20),
                    Text('SalternIQ',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 36, fontWeight: FontWeight.w800,
                          color: Colors.white,
                        )),
                    const SizedBox(height: 8),
                    Text('Sri Lanka Salt Intelligence Platform',
                        style: GoogleFonts.dmSans(
                          fontSize: 15, color: Colors.white70,
                        )),
                  ],
                ),
              ),
            ),

            // ── Form card ───────────────────────────────────
            Expanded(
              flex: 3,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.all(28),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back',
                          style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 4),
                      Text('Sign in to your account',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 28),

                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.notViable.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.notViable.withOpacity(0.3)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.error_outline, color: AppTheme.notViable, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!,
                                style: const TextStyle(color: AppTheme.notViable, fontSize: 13))),
                          ]),
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        onSubmitted: (_) => _login(),
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _login,
                        child: auth.isLoading
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                            : const Text('Sign In'),
                      ),
                      const SizedBox(height: 16),

                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text("Don't have an account? ",
                            style: Theme.of(context).textTheme.bodyMedium),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen())),
                          child: Text('Register',
                              style: GoogleFonts.dmSans(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              )),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Register Screen ───────────────────────────────────────────
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _farmCtrl     = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  Future<void> _register() async {
    if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty ||
        _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill in all required fields');
      return;
    }
    setState(() => _error = null);
    try {
      await context.read<AuthProvider>().register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        farmName: _farmCtrl.text.trim().isEmpty ? null : _farmCtrl.text.trim(),
        location: _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 20),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Text('Create Account',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22, color: Colors.white, fontWeight: FontWeight.w700,
                    )),
              ]),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                padding: const EdgeInsets.all(28),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Join SalternIQ',
                          style: Theme.of(context).textTheme.displayMedium),
                      const SizedBox(height: 4),
                      Text('Set up your saltern profile',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 24),

                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.notViable.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_error!,
                              style: const TextStyle(color: AppTheme.notViable)),
                        ),
                        const SizedBox(height: 14),
                      ],

                      _SectionLabel('Personal Details'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: _obscure,
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                      _SectionLabel('Farm Details (Optional)'),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _farmCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Farm / Saltern Name',
                          prefixIcon: Icon(Icons.agriculture_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _locationCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Region (e.g. Puttalam)',
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),

                      const SizedBox(height: 28),
                      ElevatedButton(
                        onPressed: auth.isLoading ? null : _register,
                        child: auth.isLoading
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                            : const Text('Create Account'),
                      ),
                      const SizedBox(height: 16),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Already have an account? ',
                            style: Theme.of(context).textTheme.bodyMedium),
                        GestureDetector(
                          onTap: () => Navigator.pushReplacement(context,
                              MaterialPageRoute(builder: (_) => const LoginScreen())),
                          child: Text('Sign In',
                              style: GoogleFonts.dmSans(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700, fontSize: 14,
                              )),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w700,
        color: AppTheme.textLight, letterSpacing: 1.2,
      ).copyWith(color: AppTheme.textLight));
}
