import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'chat_list_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _storage = const FlutterSecureStorage();
  final PageController _pageController = PageController();
  bool _isLoading = false;
  bool _obscureText = true;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
      setState(() {
        _currentPage--;
      });
    }
  }

  Future<void> _submitSignUp() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;

    if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        UserCredential userCredential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await _storage.write(key: 'email', value: email);
        await _storage.write(key: 'name', value: name);

        String? token = await FirebaseMessaging.instance.getToken();
        await _storeDeviceToken(email, token);

        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          await user.updateDisplayName(name);
        }

        final messagingId = '${userCredential.user!.uid}_$email';

        await _updateUsers(name, messagingId, userCredential.user!.uid);

        _proceedToChatScreen(userCredential.user!.uid, name, email);
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Failed to sign up. Please try again. $e');
      }
    }
  }

  Future<void> _storeDeviceToken(String email, String? token) async {
    try {
      await FirebaseFirestore.instance
          .collection('deviceTokens')
          .doc(email)
          .set({
        'token': token,
        'name' : _nameController.text,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Failed to store device token. You might need to log in when you reopen the app.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateUsers(
      String name, String messagingId, String userId) async {
    try {
      final email = await _storage.read(key: 'email');
      if (email != null) {
        await FirebaseFirestore.instance.collection('users').doc(name).set({
          'name': name,
          'chatId': messagingId,
          'userId': userId,
          'profilePictureUrl':
              'https://firebasestorage.googleapis.com/v0/b/chat-room-ba49a.appspot.com/o/profile_media%2Fdefault_male_2.jpg?alt=media&token=82f361f4-171c-4918-b182-15ee98607c09',
          'deviceToken': await FirebaseMessaging.instance.getToken(),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Failed to update users. The app might not work as expected.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _proceedToChatScreen(String userId, String name, String email) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Welcome $name! You have successfully signed up.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => ChatListScreen(
            username: name,
            userId: userId,
            chatId: email,
          ),
        ),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to proceed to chat screen. Please try again.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          children: [
            _buildPage1(),
            _buildPage2(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Enter Your Name and Pick a Nickname',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _nicknameController,
          decoration: const InputDecoration(
            labelText: 'Nickname',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _nextPage,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          ),
          child: const Text(
            'Next',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPage2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Create Your Account',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _passwordController,
          decoration: InputDecoration(
            labelText: 'Password',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility : Icons.visibility_off,
                color: Colors.teal,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ),
          obscureText: _obscureText,
          textInputAction: TextInputAction.done,
        ),
        const Text(
          'Password must be at least 6 characters long',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            if (_currentPage > 0)
              ElevatedButton(
                onPressed: _previousPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                ),
                child: const Text(
                  'Previous',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: _submitSignUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
              ),
              child: Text(
                _isLoading ? 'Signing Up...' : 'Sign Up',
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
