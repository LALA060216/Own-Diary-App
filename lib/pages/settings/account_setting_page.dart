import 'package:flutter/material.dart';
import 'models/settings_model.dart';

class AccountSettingPage extends StatelessWidget {
  AccountSettingPage({super.key});

  final List<AccountSettingsModel> accountSettingsOptions = AccountSettingsModel.getAccountSettingsOptions();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xffffffff),
        elevation: 0,
        title: Text(
          'Account Settings', 
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
              itemCount: accountSettingsOptions.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.only(left: 15),
                  height: 55,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => accountSettingsOptions[index].destinationPage),
                      );
                    },
                  child: Container(
                    color: Colors.transparent,
                    child: Row(
                      children: [
                        Icon( 
                          accountSettingsOptions[index].icon,
                          size: 28,
                          color: Colors.black54,
                        ),
                        SizedBox(width: 20),
                        Text(
                          accountSettingsOptions[index].name,
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