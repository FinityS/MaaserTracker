import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/transaction_type.dart';

class Destination {
  const Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final Widget icon;
  final Widget selectedIcon;
}

class MaaserDrawer extends StatelessWidget {
  const MaaserDrawer({super.key, required this.selectedIndex});

  final int selectedIndex;

  static const List<Destination> destinations = <Destination>[
    Destination('Expenses', Icon(Icons.home_outlined), Icon(Icons.home)),
    Destination('Activity', Icon(Icons.list_alt_outlined), Icon(Icons.list_alt)),
    Destination('Income', Icon(Icons.attach_money_outlined), Icon(Icons.attach_money)),
    Destination('Maaser', Icon(Icons.volunteer_activism_outlined),
        Icon(Icons.volunteer_activism)),
    Destination(
        'Maaser Deductions', Icon(Icons.money_off_outlined), Icon(Icons.money_off)),
  ];


  void handleScreenChanged(BuildContext context, int selectedScreen) {
    if (selectedScreen == destinations.length) {
      FirebaseAuth.instance.signOut();
      return;
    }

    String? routeName;
    Object? arguments;

    if (selectedScreen == 0) {
      routeName = '/';
    } else if (selectedScreen == 1) {
      routeName = '/activity';
    } else if (selectedScreen == 2) {
      routeName = '/activity';
      arguments = TransactionType.income;
    } else if (selectedScreen == 3) {
      routeName = '/activity';
      arguments = TransactionType.maaser;
    } else if (selectedScreen == 4) {
      routeName = '/activity';
      arguments = TransactionType.deductions;
    }


    if (routeName == null) {
      return;
    }

    Navigator.of(context).pop();
    Navigator.of(context)
        .pushReplacementNamed(routeName, arguments: arguments);
  }

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      onDestinationSelected: (int index) =>
          handleScreenChanged(context, index),
      selectedIndex: selectedIndex,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Text(
            'Maaser Tracker',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ...destinations.map(
          (Destination destination) {
            return NavigationDrawerDestination(
              label: Text(destination.label),
              icon: destination.icon,
              selectedIcon: destination.selectedIcon,
            );
          },
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 16, 28, 10),
          child: Divider(),
        ),
        const NavigationDrawerDestination(
          label: Text('Logout'),
          icon: Icon(Icons.logout),
          selectedIcon: Icon(Icons.logout),
        ),
      ],
    );
  }
}