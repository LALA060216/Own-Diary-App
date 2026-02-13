
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';

class BottomMenu extends StatefulWidget{
  const BottomMenu({super.key});

  @override
  State<BottomMenu> createState() => _Bottommenustate();
}

class _Bottommenustate extends State<BottomMenu>{
  int cindex = 0;
  final _pages = [
    Homepage(),
    Container(color: Colors.blue),
    Container(color: Colors.red),
    ProfilePage()
  ];


  Widget _navbutton({
    required int index,
    required IconData icon,
    required IconData activeIcon,
  }){
    final bool isActive = cindex == index;

    return IconButton(
      onPressed:() {
        setState(() {
          cindex = index;
        });
      }, 
      icon: Icon(
        isActive ? activeIcon : icon,
        size: isActive ? 30 : 32,
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _pages[cindex],
      floatingActionButton: FloatingActionButton(
        onPressed: null,
        backgroundColor: Color(0xffF9F6EE),
        elevation: 2,
        shape: CircleBorder(),
        child: Icon(Icons.camera ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: 
            BottomAppBar(
              elevation: 15,
              shape: const CircularNotchedRectangle(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              height: 75,
              
              color: Color(0xfffffaf0),
             
              notchMargin: 6,
              child: Row(

                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                mainAxisSize: MainAxisSize.max,
                children: [
                  _navbutton(
                    index: 0,
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home
                  ),
                  _navbutton(
                    index: 1,
                    icon: Icons.data_exploration_outlined,
                    activeIcon: Icons.data_exploration
                  ),
                  SizedBox(width: 20), //space for the floating button
                  _navbutton(
                    index: 2, 
                    icon: Icons.note_alt_outlined,
                    activeIcon: Icons.note_alt
                  ),

                  _navbutton(
                    index: 3,
                    icon: Icons.person_outlined,
                    activeIcon: Icons.person
                  ),
                ],
              
            ),
      
    ),
    );
    
  }
}

