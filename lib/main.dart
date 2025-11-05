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
              create: (context) => CashFlowProvider(),
              child: MaterialApp(
                routes: {
                  '/': (context) => const UserAuth(),
                  '/expenses': (context) => const UserAuth(),
                  '/income': (context) => const ExpensesList(
                        initialTransactionType: TransactionType.income,
                      ),
                  '/maaser': (context) => const ExpensesList(
                        initialTransactionType: TransactionType.maaser,
                      ),
                  '/deduction': (context) => const ExpensesList(
                        initialTransactionType: TransactionType.deductions,
                      ),
                },
                onGenerateRoute: (settings) {
                  if (settings.name == '/activity') {
                    final args = settings.arguments;
                    final filter = args is TransactionType ? args : null;
                    return MaterialPageRoute(
                      builder: (_) => ExpensesList(
                        initialTransactionType: filter,
                      ),
                      settings: settings,
                    );
                  }
                  return null;
                },
                theme: ThemeData(useMaterial3: true),
                home: const UserAuth(),
              ),
            ),
          ));
}
