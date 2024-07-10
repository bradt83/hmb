import 'dart:io';

import 'package:dcli_core/dcli_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:future_builder_ex/future_builder_ex.dart';
import 'package:go_router/go_router.dart';
import 'package:june/june.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:toastification/toastification.dart';

import 'crud/customer/customer_list_screen.dart';
import 'crud/job/job_list_screen.dart';
import 'crud/supplier/supplier_list_screen.dart';
import 'crud/system/system_edit_screen.dart';
import 'dao/dao_system.dart';
import 'dao/dao_task.dart';
import 'dao/dao_time_entry.dart';
import 'database/management/backup_providers/email/screen.dart';
import 'database/management/database_helper.dart';
import 'firebase_options.dart';
import 'installer/linux/install.dart' if (kIsWeb) 'util/web_stub.dart';
import 'screens/error.dart';
import 'screens/packing.dart';
import 'screens/shopping.dart';
import 'widgets/blocking_ui.dart';
import 'widgets/hmb_start_time_entry.dart';
import 'widgets/hmb_status_bar.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (args.isNotEmpty) {
    print('Got a link $args');
  } else {
    print('no args');
  }

  initAppLinks();

  final blockingUIKey = GlobalKey();

  runApp(ToastificationWrapper(
    child: MaterialApp(
      home: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (context) => JuneBuilder(
                TimeEntryState.new,
                builder: (_) => BlockingUIRunner(
                  key: blockingUIKey,
                  slowAction: () => _initialise(context),
                  label: 'Upgrade your database.',
                  builder: (context) => MaterialApp.router(
                    title: 'Handyman',
                    theme: ThemeData(
                      primarySwatch: Colors.blue,
                      visualDensity: VisualDensity.adaptivePlatformDensity,
                    ),
                    routerConfig: _router,
                  ),
                ),
              ),
            ),
          ),
          const BlockingOverlay(),
        ],
      ),
    ),
  ));
}

void initAppLinks() {
  // Uncomment and implement deep linking if needed
  // final _appLinks = AppLinks(); // AppLinks is singleton

  // Subscribe to all events (initial link and further)
  // _appLinks.uriLinkStream.listen((uri) {
  //   HMBToast.info('Hi from app link');
  //   HMBToast.info('Got a link $uri');
  //   HMBToast.info('deeplink: $uri');
  //   if (uri.path == XeroAuth.redirectPath) {
  //     HMBToast.error('Someone asked for xero');
  //   }
  // });
}

GoRouter get _router => GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              const HomeWithDrawer(initialScreen: JobListScreen()),
          routes: [
            GoRoute(
              path: 'details',
              builder: (_, __) => Scaffold(
                appBar: AppBar(title: const Text('Details Screen')),
              ),
            ),
            GoRoute(
              path: 'error',
              builder: (context, state) {
                final errorMessage = state.extra as String? ?? 'Unknown Error';
                return ErrorScreen(errorMessage: errorMessage);
              },
            ),
            GoRoute(
              path: 'jobs',
              builder: (_, __) =>
                  const HomeWithDrawer(initialScreen: JobListScreen()),
            ),
            GoRoute(
              path: 'customers',
              builder: (_, __) =>
                  const HomeWithDrawer(initialScreen: CustomerListScreen()),
            ),
            GoRoute(
              path: 'suppliers',
              builder: (_, __) =>
                  const HomeWithDrawer(initialScreen: SupplierListScreen()),
            ),
            GoRoute(
              path: 'shopping',
              builder: (_, __) =>
                  const HomeWithDrawer(initialScreen: ShoppingScreen()),
            ),
            GoRoute(
              path: 'packing',
              builder: (_, __) =>
                  const HomeWithDrawer(initialScreen: PackingScreen()),
            ),
            GoRoute(
              path: 'system',
              builder: (_, __) => FutureBuilderEx(
                // ignore: discarded_futures
                future: DaoSystem().getById(1),
                builder: (context, system) => HomeWithDrawer(
                  initialScreen: SystemEditScreen(system: system!),
                ),
              ),
            ),
            GoRoute(
              path: 'backup',
              builder: (_, __) => const HomeWithDrawer(
                  initialScreen: BackupScreen(pathToBackup: '')),
            ),
          ],
        ),
      ],
    );

class DrawerItem {
  DrawerItem({required this.title, required this.route});
  final String title;
  final String route;
}

class MyDrawer extends StatelessWidget {
  MyDrawer({super.key});

  final List<DrawerItem> drawerItems = [
    DrawerItem(title: 'Jobs', route: '/jobs'),
    DrawerItem(title: 'Customers', route: '/customers'),
    DrawerItem(title: 'Suppliers', route: '/suppliers'),
    DrawerItem(title: 'Shopping', route: '/shopping'),
    DrawerItem(title: 'Packing', route: '/packing'),
    DrawerItem(title: 'System', route: '/system'),
    DrawerItem(title: 'Backup', route: '/backup'),
  ];

  @override
  Widget build(BuildContext context) => Drawer(
        child: ListView.builder(
          itemCount: drawerItems.length,
          itemBuilder: (context, index) => ListTile(
            title: Text(drawerItems[index].title),
            onTap: () {
              Navigator.pop(context); // Close the drawer
              context.go(drawerItems[index].route);
            },
          ),
        ),
      );
}

class HomeWithDrawer extends StatelessWidget {
  const HomeWithDrawer({required this.initialScreen, super.key});
  final Widget initialScreen;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Handyman'),
        ),
        drawer: MyDrawer(),
        body: Column(
          children: [
            JuneBuilder<TimeEntryState>(
              TimeEntryState.new,
              builder: (context) {
                final state = June.getState<TimeEntryState>(TimeEntryState.new);
                if (state.activeTimeEntry != null) {
                  return HMBStatusBar(
                    activeTimeEntry: state.activeTimeEntry,
                    task: state.task,
                    onTimeEntryEnded: state.clearActiveTimeEntry,
                  );
                }
                return Container();
              },
            ),
            Expanded(child: initialScreen),
          ],
        ),
      );
}

bool initialised = false;
Future<void> _initialise(BuildContext context) async {
  if (!initialised) {
    try {
      initialised = true;
      await _checkInstall();
      await _initFirebase();
      await _initDb();
      await _initializeTimeEntryState(refresh: false);
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      if (context.mounted) {
        await showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => FullScreenDialog(
                  content: ErrorScreen(errorMessage: e.toString()),
                  title: 'Database Error',
                ));
        // context.go('/error',
        //     extra: 'An error occurred while processing your request.');
      }
      rethrow;
    }
  }
}

Future<void> _initFirebase() async {
  if (!Platform.isLinux) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

Future<void> _initDb() async {
  await DatabaseHelper().initDatabase();
  print('Database located at: ${await DatabaseHelper().pathToDatabase()}');
}

Future<void> _checkInstall() async {
  if (kIsWeb) {
    return;
  }

  final pathToHmbFirstRun = join(await pathToHmbFiles, 'firstrun.txt');
  print('checking firstRun: $pathToHmbFirstRun');

  if (!exists(await pathToHmbFiles)) {
    createDir(await pathToHmbFiles, recursive: true);
  }

  if (!exists(pathToHmbFirstRun)) {
    await _install();
    touch(pathToHmbFirstRun, create: true);
  }
}

Future<void> _install() async {
  if (Platform.isLinux) {
    await linuxInstaller();
  }
}

Future<void> _initializeTimeEntryState({required bool refresh}) async {
  final timeEntryState = June.getState<TimeEntryState>(TimeEntryState.new);
  final activeEntry = await DaoTimeEntry().getActiveEntry();
  if (activeEntry != null) {
    final task = await DaoTask().getById(activeEntry.taskId);
    timeEntryState.setActiveTimeEntry(activeEntry, task, doRefresh: refresh);
  }
}

Future<String> get pathToHmbFiles async =>
    join((await getApplicationSupportDirectory()).path, 'hmb');
