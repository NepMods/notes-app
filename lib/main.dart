import 'package:auth_wrapper/auth_wrapper.dart';
import 'package:auth_wrapper/models/AuthRoute.dart';
import 'package:flutter/material.dart';
import 'package:notes/Models/note.dart';
import 'package:notes/Screens/Loading/LoadingService.dart';
import 'package:notes/Screens/LoginUI.dart';
import 'package:notes/Screens/DasboardUI.dart';
import 'package:notes/Screens/Loading/LoadingOverlay.dart';
import 'package:notes/Screens/Components/ThemeProvider.dart';
import 'package:notes/EncryptedDatabase/EncryptedDatabase.dart';
import 'package:notes/Screens/NoteEditUI.dart';
import 'package:notes/Screens/RegisterUI.dart';
import 'package:notes/Screens/SettingsUI.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:sonner_flutter/sonner_flutter.dart';

Future<bool> checkToke() async {
  return EncryptedDatabase.instance.read("isLoginDone") ?? false;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  EncryptedDatabase database = EncryptedDatabase();
  await database.init();
  Get.put<EncryptedDatabase>(database);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final database = EncryptedDatabase.instance;
    return UseAuth(
      publicPages: [
        AuthRoute.static("/login", LoginUI()),
        AuthRoute.static("/register", RegisterUI()),
      ],
      protectedPages: [
        AuthRoute.static("/notes", Dashboard()),
        AuthRoute.builder("/addNotes", (context, args) {
          final note = args as Note?;
          return NoteEdit(editingNote: note ?? null);
        }),
        AuthRoute.static("/settings", ProfileSetting()),
      ],
      noAuth: "/login",
      success: "/notes",
      checkFunc: checkToke,
      showLoading: LoadingService.show,
      hideLoading: LoadingService.hide,
      app: MaterialApp(
        debugShowCheckedModeBanner: false,
        darkTheme: ThemeData.dark(useMaterial3: true),
        navigatorObservers: [routeObserver],

        theme: ThemeData.light(useMaterial3: true),
        themeMode: themeProvider.themeMode,
        builder: (context, child) {
          return Stack(
            children: [
              child!,
              const LoadingOverlay(),

              const Toaster(offset: 38,),
            ],
          );
        },
        // home:NoteEdit()
      ),
    );
  }
}
