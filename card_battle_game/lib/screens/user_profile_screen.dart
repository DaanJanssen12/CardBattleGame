import 'package:card_battle_game/models/user_storage.dart';
import 'package:card_battle_game/screens/main_menu.dart';
import 'package:flutter/material.dart';
import 'dart:io';

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
    _selectedBackground = widget.userData.background; // Set initial background
  }

  void saveName(String name) async {
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text("Saved")),
    // );
    await UserStorage.setName(name);
  }

  void selectBackground(String? newBackground) async {
    setState(() {
      _selectedBackground = newBackground;
    });
    widget.userData.background = newBackground!;
    await UserStorage.setBackground(newBackground);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  'assets/images/$_selectedBackground',
                  fit: BoxFit.cover,
                ),

          // Profile UI
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  "User Profile",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black54,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // Background Selection Dropdown
                DropdownButton<String>(
                  value: _selectedBackground,
                  onChanged: selectBackground,
                  items: <String>[
                    'background1.jpg',
                    'background2.jpg',
                    'background3.jpg'
                  ] // Predefined backgrounds
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  hint: Text("Select Background"),
                ),
                SizedBox(height: 20),

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
                SizedBox(
                  width: 300,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Go back to the main menu
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          textStyle: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: Text("Back"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Handle saving name (you can extend this with local storage)
                          String name = _nameController.text.trim();
                          if (name.isNotEmpty) {
                            saveName(name);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      MainMenu(userData: widget.userData)),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          textStyle: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: Text("Save"),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
