import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Destination {
  const Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final Widget icon;
  final Widget selectedIcon;
}

class MaaserDrawer extends StatelessWidget {
  final int selectedIndex;

  const MaaserDrawer({super.key,
    required this.selectedIndex
  });



  static const List<Destination> destinations = <Destination>[
    Destination('Expenses', Icon(Icons.home_outlined), Icon(Icons.home)),
    Destination('Income', Icon(Icons.attach_money_outlined), Icon(Icons.attach_money)),
    Destination('Maaser', Icon(Icons.volunteer_activism_outlined),
        Icon(Icons.volunteer_activism)),
    Destination('Maaser Deductions', Icon(Icons.money_off_outlined), Icon(Icons.money_off)),
    // Profile page
  ];


  void handleScreenChanged(BuildContext context, int selectedScreen) {

    if (selectedScreen == 4) {
      FirebaseAuth.instance.signOut();
      return;
    }

    String? routeName;

    if (selectedScreen == 0) {
      routeName = '/';
    } else if (selectedScreen == 1) {
      routeName = '/income';
    } else if (selectedScreen == 2) {
      routeName = '/maaser';
    } else if (selectedScreen == 3) {
      routeName = '/deduction';
    }


    if (routeName != null) {
      Navigator.of(context).pop();
      Navigator.of(context).pushReplacementNamed(routeName);
    }
  }

  @override
  Widget build(BuildContext context) {




   return NavigationDrawer(
     onDestinationSelected: (int selectedScreen) => handleScreenChanged(context, selectedScreen),
     selectedIndex: selectedIndex,
     children: <Widget>[
       Padding(
           padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
           child: Text(
             'Maaser Tracker',
             style: Theme.of(context).textTheme.titleSmall,
           )),
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
       // Add a logout button
        const NavigationDrawerDestination(
          label: Text('Logout'),
          icon: Icon(Icons.logout),
          selectedIcon: Icon(Icons.logout),
        ),
     ],
   );


  }
}