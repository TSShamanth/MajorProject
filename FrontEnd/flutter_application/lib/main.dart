import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'config/router.dart';
import 'firebase_options.dart';
import 'providers/institution_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InstitutionProvider()),
      ],
      child: Consumer<InstitutionProvider>(
        builder: (context, provider, _) {
          debugPrint('MyApp: Theme color is ${provider.primaryColor}');
          return MaterialApp.router(
            routerConfig: router,
            title: 'Acadexa',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: provider.primaryColor,
                primary: provider.primaryColor,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: const Color(0xFFF8F9FA),
            ),
          );
        },
      ),
    );
  }
}
