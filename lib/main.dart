import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/bloc/auth_bloc.dart' as auth_bloc;
import 'features/auth/pages/login_page.dart';
import 'features/auth/pages/signup_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://pwpqkqxbzkinycrstkkt.supabase.co',
    anonKey: 'sb_publishable_drUfi5zzXLXTwI9MGUGwVg_2Ws20Y9d',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          auth_bloc.AuthBloc(supabase: Supabase.instance.client),
      child: MaterialApp(
        title: 'AI Health',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapper();
}

class _AuthWrapper extends State<AuthWrapper> {
  String _currentAuthPage = 'login';

  void _navigateAuthPage(String page) {
    setState(() {
      _currentAuthPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<auth_bloc.AuthBloc, auth_bloc.AuthState>(
      builder: (context, state) {
        // Show loading while checking auth status
        if (state is auth_bloc.AuthLoading || state is auth_bloc.AuthInitial) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is authenticated
        if (state is auth_bloc.AuthAuthenticated) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Home'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    context.read<auth_bloc.AuthBloc>().add(
                      auth_bloc.AuthSignOut(),
                    );
                  },
                ),
              ],
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Welcome ${state.user?.email}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  const Text('Logged in successfully!'),
                ],
              ),
            ),
          );
        }

        // User is not authenticated - show login/signup pages
        return _currentAuthPage == 'login'
            ? LoginPage(onNavigate: _navigateAuthPage)
            : SignupPage(onNavigate: _navigateAuthPage);
      },
    );
  }
}
