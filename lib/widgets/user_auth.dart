import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:maaserTracker/expenses.dart';



class UserAuth extends StatelessWidget {
  const UserAuth({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SignInScreen(
            providers: [
              EmailAuthProvider()
            ],
            subtitleBuilder:  (context, action) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: action == AuthAction.signIn
                    ? const Text('Welcome to Maaser Tracker, please sign in!')
                    : const Text('Welcome to Maaser Tracker, please sign up!'),
              );
            },
          );
        }
        if (snapshot.data?.metadata.creationTime == snapshot.data?.metadata.lastSignInTime) {
          snapshot.data?.sendEmailVerification();

        }

        return const Expenses();
      },
    );
  }
}