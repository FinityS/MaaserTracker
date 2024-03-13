import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maaserTracker/expenses.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Initialize Firebase
 // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((value) => runApp(
            MaterialApp(
              theme: ThemeData(useMaterial3: true),
              home: const Expenses(),
            ),
          ));
}
