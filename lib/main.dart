import 'package:flutter/material.dart';
import 'package:maaser_tracker/expenses.dart';
import 'package:flutter/services.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp]
  ).then((value) => runApp( MaterialApp(
    theme: ThemeData(useMaterial3: true),
    home: const Expenses(),
  ),));

}


 