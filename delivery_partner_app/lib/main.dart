import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/api_config.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/duty_provider.dart';
import 'providers/delivery_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.init();

  final authProvider = AuthProvider();
  await authProvider.initSession();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<DutyProvider>(create: (_) => DutyProvider()),
        ChangeNotifierProvider<DeliveryProvider>(create: (_) => DeliveryProvider()),
      ],
      child: const DeliveryPartnerApp(),
    ),
  );
}

class DeliveryPartnerApp extends StatelessWidget {
  const DeliveryPartnerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProv, child) {
        return MaterialApp(
          title: 'Delivery Partner',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: authProv.isAuthenticated ? const HomeScreen() : const LoginScreen(),
        );
      },
    );
  }
}
