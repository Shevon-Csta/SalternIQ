import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..loadUserFromStorage(),
      child: const SalternIQApp(),
    ),
  );
}

class SalternIQApp extends StatelessWidget {
  const SalternIQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SalternIQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _RootRouter(),
    );
  }
}

class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isAuthenticated) return const DashboardScreen();
    return const LoginScreen();
  }
}
