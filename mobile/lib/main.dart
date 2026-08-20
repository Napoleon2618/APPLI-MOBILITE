import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/env.dart';
import 'core/offline/local_database.dart';
import 'core/offline/sync_queue.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'data/repositories/daily_formula_repository.dart';
import 'data/repositories/session_log_repository.dart';
import 'features/auth/auth_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    publishableKey: Env.supabaseAnonKey,
  );

  final prefs = await SharedPreferences.getInstance();
  final localDatabase = LocalDatabase();

  runApp(
    MultiProvider(
      providers: [
        Provider<SupabaseClient>.value(value: Supabase.instance.client),
        Provider<LocalDatabase>.value(value: localDatabase),
        Provider<SyncQueue>(create: (_) => SyncQueue(localDatabase)),
        Provider<DailyFormulaRepository>(
          create: (ctx) => DailyFormulaRepository(
            supabase: ctx.read(),
            localDatabase: ctx.read(),
          ),
        ),
        Provider<SessionLogRepository>(
          create: (ctx) => SessionLogRepository(
            supabase: ctx.read(),
            localDatabase: ctx.read(),
            syncQueueEnqueue: ctx.read<SyncQueue>().enqueue,
          ),
        ),
        ChangeNotifierProvider<AppAuthState>(
          create: (_) => AppAuthState(Supabase.instance.client),
        ),
        ChangeNotifierProvider<ThemeController>(
          create: (_) => ThemeController(prefs),
        ),
      ],
      child: const AppliMobiliteApp(),
    ),
  );
}

class AppliMobiliteApp extends StatefulWidget {
  const AppliMobiliteApp({super.key});

  @override
  State<AppliMobiliteApp> createState() => _AppliMobiliteAppState();
}

class _AppliMobiliteAppState extends State<AppliMobiliteApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildAppRouter(context.read<AppAuthState>());
    // Best-effort sync of anything queued while offline (Principle IV) —
    // failures are swallowed inside SyncQueue and retried later.
    context.read<SyncQueue>().syncPending(context.read<SupabaseClient>());
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();

    return MaterialApp.router(
      title: 'Appli Mobilité',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeController.mode,
      routerConfig: _router,
    );
  }
}
