
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    runApp(const NeighborChatApp());
  } catch (e) {
    runApp(StartupErrorApp(error: e.toString()));
  }
}

class StartupErrorApp extends StatelessWidget {
  final String error;

  const StartupErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'تعذر الاتصال بإعدادات Firebase.\n'
              'تحقق من ملف google-services.json '
              'وإعدادات المشروع.\n\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class NeighborChatApp extends StatefulWidget {
  const NeighborChatApp({super.key});

  @override
  State<NeighborChatApp> createState() => _NeighborChatAppState();
}

class _NeighborChatAppState extends State<NeighborChatApp> {
  ThemeMode themeMode = ThemeMode.dark;

  void changeTheme(bool dark) {
    setState(() {
      themeMode = dark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF397A72);

    return MaterialApp(
      title: 'جيران',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF6F8F7),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF101614),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      home: AuthGate(
        onThemeChanged: changeTheme,
        isDark: themeMode == ThemeMode.dark,
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  final ValueChanged<bool> onThemeChanged;
  final bool isDark;

  const AuthGate({
    super.key,
    required this.onThemeChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return HomeScreen(
            onThemeChanged: onThemeChanged,
            isDark: isDark,
          );
        }

        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool registering = false;
  bool loading = false;
  bool hidePassword = true;

  Future<void> submit() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      message('أدخل البريد الإلكتروني وكلمة المرور.');
      return;
    }

    if (password.length < 6) {
      message('يجب ألا تقل كلمة المرور عن 6 أحرف.');
      return;
    }

    setState(() => loading = true);

    try {
      if (registering) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (e) {
      message(authError(e.code));
    } catch (_) {
      message('حدث خطأ. تحقق من اتصال الإنترنت وإعدادات Firebase.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String authError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'هذا البريد مسجل بالفعل.';
      case 'invalid-email':
        return 'صيغة البريد الإلكتروني غير صحيحة.';
      case 'weak-password':
        return 'كلمة المرور ضعيفة.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'بيانات تسجيل الدخول غير صحيحة.';
      case 'network-request-failed':
        return 'تعذر الاتصال بالإنترنت.';
      case 'too-many-requests':
        return 'محاولات كثيرة. حاول لاحقًا.';
      case 'operation-not-allowed':
        return 'فعّل تسجيل البريد وكلمة المرور في Firebase.';
      default:
        return 'تعذر إكمال العملية: $code';
    }
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.forum_rounded,
                    size: 76,
                    color: colors.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'جيران',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تواصل عبر الإنترنت أو بالقرب منك',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 36),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'البريد الإلكتروني',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: hidePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => hidePassword = !hidePassword);
                        },
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => submit(),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: loading ? null : submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(registering ? 'إنشاء حساب' : 'تسجيل الدخول'),
                  ),
                  TextButton(
                    onPressed: loading
                        ? null
                        : () {
                            setState(() => registering = !registering);
                          },
                    child: Text(
                      registering
                          ? 'لديك حساب؟ تسجيل الدخول'
                          : 'مستخدم جديد؟ أنشئ حسابًا',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'لا توجد إعلانات داخل التطبيق.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;
  final bool isDark;

  const HomeScreen({
    super.key,
    required this.onThemeChanged,
    required this.isDark,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  static const titles = [
    'المحادثات',
    'الحالات',
    'الجيران القريبون',
    'الإعدادات',
  ];

  @override
  Widget build(BuildContext context) {
    final pages = [
      const ChatsPage(),
      const StatusPage(),
      const NearbyPage(),
      SettingsPage(
        onThemeChanged: widget.onThemeChanged,
        isDark: widget.isDark,
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'جيران',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 16),
              child: Center(
                child: Text(
                  titles[selectedIndex],
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: IndexedStack(
          index: selectedIndex,
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            setState(() => selectedIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'الدردشة',
            ),
            NavigationDestination(
              icon: Icon(Icons.circle_outlined),
              selectedIcon: Icon(Icons.circle),
              label: 'الحالات',
            ),
            NavigationDestination(
              icon: Icon(Icons.bluetooth_searching),
              selectedIcon: Icon(Icons.bluetooth_connected),
              label: 'قريبون',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'الإعدادات',
            ),
          ],
        ),
      ),
    );
  }
}

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptySection(
      icon: Icons.forum_outlined,
      title: 'ابدأ محادثاتك',
      description:
          'ستظهر هنا المحادثات الفردية والجماعية بعد إضافة نظام '
          'جهات الاتصال والرسائل.',
      buttonText: 'قريبًا: محادثة جديدة',
    );
  }
}

class StatusPage extends StatelessWidget {
  const StatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptySection(
      icon: Icons.photo_camera_back_outlined,
      title: 'الحالات والقصص',
      description:
          'سيكون بإمكانك نشر صورة أو نص ومشاهدة حالات جهات اتصالك '
          'بعد تفعيل تخزين الحالات.',
      buttonText: 'قريبًا: إنشاء حالة',
    );
  }
}

class NearbyPage extends StatelessWidget {
  const NearbyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return EmptySection(
      icon: Icons.bluetooth_searching,
      title: 'التواصل مع الجيران',
      description:
          'هذا القسم يحتاج إلى تفعيل البلوتوث والاتصال المحلي '
          'وصلاحيات أندرويد. لم يتم تفعيل اكتشاف الأجهزة بعد.',
      buttonText: 'الاتصال المحلي غير مفعّل بعد',
    );
  }
}

class EmptySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;

  const EmptySection({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 66, color: colors.primary),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 1.6,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            OutlinedButton(
              onPressed: null,
              child: Text(buttonText),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatelessWidget {
  final ValueChanged<bool> onThemeChanged;
  final bool isDark;

  const SettingsPage({
    super.key,
    required this.onThemeChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        const ListTile(
          leading: Icon(Icons.person_outline),
          title: Text('الحساب'),
          subtitle: Text('إدارة بيانات حسابك'),
        ),
        ListTile(
          leading: const Icon(Icons.email_outlined),
          title: const Text('البريد الإلكتروني'),
          subtitle: Text(user?.email ?? 'غير مسجل'),
        ),
        const Divider(),
        SwitchListTile(
          secondary: const Icon(Icons.dark_mode_outlined),
          title: const Text('الوضع الداكن'),
          subtitle: const Text('تغيير مظهر التطبيق'),
          value: isDark,
          onChanged: onThemeChanged,
        ),
        const ListTile(
          leading: Icon(Icons.notifications_none),
          title: Text('الإشعارات'),
          subtitle: Text('سيتم إعدادها في مرحلة لاحقة'),
        ),
        const ListTile(
          leading: Icon(Icons.privacy_tip_outlined),
          title: Text('الخصوصية'),
          subtitle: Text('ستضاف إعدادات الحظر والأمان لاحقًا'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('حول التطبيق'),
          subtitle: const Text('جيران — الإصدار 1.0.0'),
        ),
        const SizedBox(height: 16),
        FilledButton.tonalIcon(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
          },
          icon: const Icon(Icons.logout),
          label: const Text('تسجيل الخروج'),
        ),
      ],
    );
  }
}