import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/di/app_container.dart';

/// نقطه‌ی ورود اپلیکیشن.
///
/// راه‌اندازی (خواندن پیشرفت کاربر، بارگذاری محتوای واژه‌ها و ساخت سرویس‌ها)
/// پیش از رسم نخستین فریم انجام می‌شود تا کاربر پرش تصویری نبیند؛ در این
/// فاصله یک صفحه‌ی راه‌انداز سبک نمایش داده می‌شود.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // نوار وضعیت هم‌رنگ با تم اپ.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(const WordAgentBootstrap());
}

/// صفحه‌ی راه‌انداز که تا آماده شدن کانتینر، نشان اپ را نشان می‌دهد.
class WordAgentBootstrap extends StatefulWidget {
  const WordAgentBootstrap({super.key});

  @override
  State<WordAgentBootstrap> createState() => _WordAgentBootstrapState();
}

class _WordAgentBootstrapState extends State<WordAgentBootstrap> {
  late final Future<AppContainer> _boot = AppContainer.boot();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppContainer>(
      future: _boot,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _BootErrorScreen(
              message: '${snapshot.error}',
              onRetry: () => setState(() {}),
            ),
          );
        }
        final container = snapshot.data;
        if (container == null) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: _BootLoadingScreen(),
          );
        }
        return WordAgentApp(container: container);
      },
    );
  }
}

class _BootLoadingScreen extends StatelessWidget {
  const _BootLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF6C4CF1),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('واژه‌یار', style: TextStyle(color: Colors.white, fontSize: 34)),
            SizedBox(height: 16),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _BootErrorScreen extends StatelessWidget {
  const _BootErrorScreen({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline_rounded, size: 48, color: Color(0xFFF04438)),
              const SizedBox(height: 16),
              const Text('راه‌اندازی اپلیکیشن ناموفق بود'),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextButton(onPressed: onRetry, child: const Text('تلاش دوباره')),
            ],
          ),
        ),
      ),
    );
  }
}
