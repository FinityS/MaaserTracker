import 'package:flutter/material.dart';

class Destination {
  const Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final Widget icon;
  final Widget selectedIcon;
}

class MaaserDrawer extends StatelessWidget {
  final Function(int) onDestinationSelected;
  final int selectedIndex;

  const MaaserDrawer({super.key,
    required this.onDestinationSelected,
    required this.selectedIndex
  });

  static const List<Destination> destinations = <Destination>[
    Destination('Home', Icon(Icons.home_outlined), Icon(Icons.home)),
    Destination(
        'Income', Icon(Icons.attach_money_outlined), Icon(Icons.attach_money)),
    Destination('Maaser', Icon(Icons.volunteer_activism_outlined),
        Icon(Icons.volunteer_activism)),
  ];

  @override
  Widget build(BuildContext context) {
   return NavigationDrawer(
     onDestinationSelected: onDestinationSelected,
     selectedIndex: selectedIndex,
     children: <Widget>[
       Padding(
           padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
           child: Text(
             'Header',
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
     ],
   );
  }
}