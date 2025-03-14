import 'package:card_battle_game/models/constants.dart';
import 'package:card_battle_game/models/database/user_storage.dart';
import 'package:card_battle_game/providers/sound_settings_provider.dart';
import 'package:card_battle_game/screens/main_menu.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:provider/provider.dart';

class UserProfileScreen extends StatefulWidget {
  final UserData userData;
  const UserProfileScreen({super.key, required this.userData});

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  File? _backgroundImage;
  String? _selectedBackground; // Variable to store selected background

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userData.name;
    _selectedBackground =
        widget.userData.background.split('.')[0]; // Set initial background
  }

  void save() async {
    await UserStorage.setBackground(widget.userData.background);
    String name = _nameController.text.trim();
    if (name.isNotEmpty) {
      widget.userData.name = name;
      await UserStorage.setName(name);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MainMenu(userData: widget.userData),
        ),
      );
    }
  }

  void selectBackground(String? newBackground) async {
    setState(() {
      _selectedBackground = newBackground;
    });
    var fileName = '${newBackground!}.jpg';
    widget.userData.background = fileName;
  }

  @override
  Widget build(BuildContext context) {
    final soundSettings = Provider.of<SoundSettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("User Profile"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          _backgroundImage != null
              ? Image.file(
                  _backgroundImage!,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  'assets/images/$_selectedBackground.jpg',
                  fit: BoxFit.cover,
                ),

          // High Score Badge in Top Right
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(2, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 18),
                  Text(
                    'Highscore: ',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(width: 2),
                  Text(
                    'Stage ${widget.userData.highscore.toString()}',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Profile UI
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name Input Field
                Container(
                  width: 300,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Enter your name",
                      icon: Icon(Icons.person, color: Colors.blue),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Background Selection Dropdown
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          'Background',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: DropdownButton<String>(
                          value: Constants.backgrounds
                                  .contains(_selectedBackground)
                              ? _selectedBackground
                              : Constants.backgrounds.first,
                          onChanged: selectBackground,
                          items: Constants.backgrounds
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          hint: Text("Select Background"),
                        ),
                      )
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero, // Removes default padding
                    title: Align(
                      alignment: Alignment.centerLeft, // Align text to the left
                      child: Text(
                        'Mute Sound Effects',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    value: soundSettings.isMuted,
                    onChanged: (value) => soundSettings.toggleMute(value),
                  ),
                ),
                SizedBox(height: 20),
                // Save Button
                ElevatedButton(
                  onPressed: save,
                  style: ElevatedButton.styleFrom(
                    fixedSize: Size.fromWidth(300),
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    textStyle:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  child: Text("Save"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
