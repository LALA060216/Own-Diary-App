import 'package:flutter/material.dart';

class SettingsModel {
  String name;
  IconData icon;
  Widget destinationPage;
  

  SettingsModel({
    required this.name, 
    required this.icon,
    required this.destinationPage,
  });

  static List<SettingsModel> getSettingsOptions() {
    List<SettingsModel> settingsOptions = [];

    settingsOptions.add(SettingsModel(
      name: "Account",
      icon: Icons.person_outline,
      destinationPage: Container(color: Colors.amber,)
    ));

    settingsOptions.add(SettingsModel(
      name: "Notifications",
      icon: Icons.notifications_outlined,
      destinationPage: Container(color: Colors.amber,)
    ));

    settingsOptions.add(SettingsModel(
      name: "Privacy",
      icon: Icons.lock_outline,
      destinationPage: Container(color: Colors.amber,)
    ));

    settingsOptions.add(SettingsModel(
      name: "Theme",
      icon: Icons.color_lens_outlined,
      destinationPage: Container(color: Colors.amber,)
    ));

    settingsOptions.add(SettingsModel(
      name: "About",
      icon: Icons.info_outline,
      destinationPage: Container(color: Colors.amber,)
    ));

    settingsOptions.add(SettingsModel(
      name: "Logout",
      icon: Icons.logout,
      destinationPage: Container(color: Colors.amber,)
    ));
   
    return settingsOptions;
  }

}
  

