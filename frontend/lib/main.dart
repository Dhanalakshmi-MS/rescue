import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'providers/app_state.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final user = await AuthService.loadUserSession();
  runApp(RescueLensApp(initialUser: user));
}

class RescueLensApp extends StatelessWidget {
  final UserModel? initialUser;

  const RescueLensApp({super.key, this.initialUser});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) {
          final state = AppState();
          if (initialUser != null) {
            state.setCurrentUser(initialUser);
          }
          return state;
        }),
      ],
      child: MaterialApp(
        title: 'RescueLens XR',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: initialUser != null ? const MainNavigationShell() : const LoginScreen(),
      ),
    );
  }
}
