import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  _ThemeSettingsScreenState createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  final _storage = const FlutterSecureStorage();
  String? _selectedBackground;

  final List<String> imageNames = [
    'dark_mode_4.jpg',
    'dark_mode_1.jpg',
    'light_mode_1.jpg',
    'dark_mode_2.jpg',
    'light_mode_2.jpg',
    'dark_mode_3.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
  }

  Future<void> _loadBackgroundImage() async {
    final storedBackground = await _storage.read(key: 'chatListBackground');
    setState(() {
      _selectedBackground = storedBackground;
    });
  }

  Future<void> _updateBackgroundImage(String? imagePath) async {
    await _storage.write(key: 'chatListBackground', value: imagePath);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Background updated. Restart the app to see changes.')),
    );
    setState(() {
      _selectedBackground = imagePath;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme Settings')),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: imageNames.length,
        itemBuilder: (context, index) {
          final imagePath = 'assets/backgrounds/${imageNames[index]}';
          return GestureDetector(
            onTap: () => _updateBackgroundImage(imagePath),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _selectedBackground == imagePath
                      ? Colors.blue
                      : Colors.transparent,
                  width: 3.0,
                ),
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
