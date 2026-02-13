import 'package:diaryapp/pages/settings/account_setting/change_password.dart';
import 'package:diaryapp/pages/settings/account_setting/delete_acc.dart';
import 'package:flutter/material.dart';
import 'package:diaryapp/pages/settings/account_settingPage.dart';
import 'package:diaryapp/pages/settings/account_setting/change_usernamePage.dart';


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
      destinationPage: AccountSettingPage(),
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
  
class AccountSettingsModel {
  String name;
  IconData icon;
  Widget destinationPage;
  

  AccountSettingsModel({
    required this.name, 
    required this.icon,
    required this.destinationPage,
  });


  static List<AccountSettingsModel> getAccountSettingsOptions() {
    List<AccountSettingsModel> accountSettingsOptions = [];

    accountSettingsOptions.add(AccountSettingsModel(
      name: "Change Username",
      icon: Icons.edit_outlined,
      destinationPage: ChangeUsernamePage(),
    ));

    accountSettingsOptions.add(AccountSettingsModel(
      name: "Change Password",
      icon: Icons.lock_outline,
      destinationPage: ChangePasswordPage(),
    ));

    accountSettingsOptions.add(AccountSettingsModel(
      name: "Delete Account",
      icon: Icons.delete_outline,
      destinationPage: DeleteAcc()
    ));

    return accountSettingsOptions;
  }

}
