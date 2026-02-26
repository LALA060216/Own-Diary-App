import 'package:diaryapp/services/auth/auth_service.dart';
import 'package:diaryapp/services/auth/pages/welcome_page.dart';
import 'package:flutter/material.dart';
import 'settings/models/settings_model.dart';
import 'ai_summary.dart';
import 'package:diaryapp/pages/home_page/home_page.dart';

class SettingPage extends StatelessWidget{
  SettingPage({super.key});

  final List<SettingsModel> settingOption = SettingsModel.getSettingsOptions();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xffffffff),
        elevation: 0,
        title: Text(
          'Settings', 
          style: TextStyle(
            fontSize: 24,
            fontFamily: 'Lobstertwo',
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      
      ),
      backgroundColor: Color(0xfff5f5f5),
      body: Center(
        child: Column(
          children: [
            ListView.separated(
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: Color(0xffe0e0e0),
              ),
              itemCount: settingOption.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.only(left: 15),
                  height: 55,
                  child: GestureDetector(
                    onTap: () async {
                      // check if user tapped on "Log Out"
                      final selected = settingOption[index];
                      if (selected.name == 'Logout') {
                        clearAiChatState();
                        clearMoodAndAttentionState();
                        await authService.value.signOut();
                        if (!context.mounted) return;
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => WelcomePage()),
                          (route) => false,
                        );
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => settingOption[index].destinationPage)
                      );
                    },
                  child: Container(
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        Icon( 
                          settingOption[index].icon,
                          size: 28,
                          color: Colors.black54,
                        ),
                        SizedBox(width: 20),
                        Text(
                          settingOption[index].name,
                          style: TextStyle(
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                );
              },
              )
          ],

        )
        ),
      );
    
  }
}