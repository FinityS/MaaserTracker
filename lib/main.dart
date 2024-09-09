import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maaserTracker/providers/cash_flow_provider.dart';
import 'package:maaserTracker/widgets/expenses_list.dart';
import 'package:maaserTracker/widgets/user_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/transaction_type.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
    // ... other providers
  ]);

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((value) => runApp(
            ChangeNotifierProvider(
              create: (context) => CashFlowProvider()..loadCashFlows(),
              child: MaterialApp(
                routes: {
                  '/expenses': (context) => const UserAuth(),
                  '/income': (context) =>
                      ExpensesList(transactionType: TransactionType.income),
                  '/maaser': (context) =>
                      ExpensesList(transactionType: TransactionType.maaser),
                  '/deduction': (context) =>
                      ExpensesList(transactionType: TransactionType.deductions),
                },
                theme: ThemeData(useMaterial3: true),
                home: const UserAuth(),
              ),
            ),
          ));
}
