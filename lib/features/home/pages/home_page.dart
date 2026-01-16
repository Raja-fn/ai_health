import 'package:ai_health/features/auth/pages/login_page.dart';
import 'package:ai_health/features/form/pages/form_page.dart';
import 'package:ai_health/services/profile_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ProfileService _profileService;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService(supabaseClient: Supabase.instance.client);
    _checkProfileCompletion();
  }

  /// Check if profile is completed, redirect to form if not
  Future<void> _checkProfileCompletion() async {
    try {
      final isProfileCompleted = await _profileService.isProfileCompleted();

      if (!mounted) return;

      if (!isProfileCompleted) {
        // Redirect to form page if profile is not completed
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const FormPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error checking profile: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          actions: <Widget>[
            IconButton(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              },
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: const Column(children: [Text("Home Page")]),
      ),
    );
  }
}
