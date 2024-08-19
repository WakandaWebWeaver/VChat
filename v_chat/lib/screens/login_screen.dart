import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart'; // Import Google Sign-In
import 'chat_list_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'sign_up_screen.dart';
import 'package:carousel_slider/carousel_slider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = false;
  bool _obscureText = true;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp().then((_) {
      _retrieveSavedLogin();
    });
  }

  void _retrieveSavedLogin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _proceedToChatScreen(
        user.uid,
        user.providerData[0].displayName!,
        user.email!,
      );
    }
  }

  Future<void> _submitLogin() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    if (name.isNotEmpty && email.isNotEmpty && password.isNotEmpty) {
      try {
        UserCredential userCredential;
        try {
          userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );

          await _storage.write(key: 'email', value: email);
          await _storage.write(key: 'name', value: name);

          String? token = await FirebaseMessaging.instance.getToken();
          await _storeDeviceToken(email, token);

          FirebaseAuth.instance.currentUser!.updateDisplayName(name);

          final messagingId = '${userCredential.user!.uid}_$email';

          await _updateusers(name, messagingId, userCredential.user!.uid);

          _proceedToChatScreen(userCredential.user!.uid, name, email);

        } catch (e) {
          setState(() {
            _isLoading = false;
          });

          if (e.toString().contains('user-not-found')) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Error'),
                content: const Text(
                    'Failed to sign in. Do you want to create an account instead?'
                ),
                actions: [
                  TextButton(
                    child: const Text('No'),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Yes'),
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                            (route) => false,
                      );
                    },
                  ),
                ],
              ),
            );
          } else if (e.toString().contains('wrong-password')) {
            _showErrorDialog('Incorrect password. Please try again.');
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(
            'Failed to sign in / create account. Please try again.');
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth =
      await googleUser!.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;
      if (user != null) {
        await _storage.write(key: 'email', value: user.email);
        await _storage.write(key: 'name', value: user.displayName);

        String? token = await FirebaseMessaging.instance.getToken();
        await _storeDeviceToken(user.email!, token);

        final messagingId = '${user.uid}_${user.email}';
        await _updateusers(user.displayName!, messagingId, user.uid);

        setState(() {
          _isLoading = false;
        });

        _proceedToChatScreen(user.uid, user.displayName!, user.email!);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      _showErrorDialog('Could not finish Google Sign-In. Please try again.');
    }
  }

  Future<void> _storeDeviceToken(String email, String? token) async {
    try {
      await FirebaseFirestore.instance
          .collection('deviceTokens')
          .doc(email)
          .set({
        'token': token,
        'name': await _storage.read(key: 'name'),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Fell off while storing device token. You might need to log in when you reopen the app.'
          ),
          backgroundColor: Colors.red,
          elevation: 10,
        ),
      );
    }
  }

  Future<void> _updateusers(
      String name, String messagingId, String userId) async {
    try {
      final email = await _storage.read(key: 'email');
      if (email != null) {
        await FirebaseFirestore.instance.collection('users').doc(name).update({
          'name': name,
          'chatId': messagingId,
          'userId': userId,
          'deviceToken': await FirebaseMessaging.instance.getToken(),
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Fell off while updating active users. The app might not work as expected.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _proceedToChatScreen(String userId, String name, String email) async {
    try {
      FirebaseMessaging.instance.getToken();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hark! $name. You have successfully logged in.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChatListScreen(
            username: name,
            userId: userId,
            chatId: email,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to proceed to chat screen. Please try again.');
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text;

    if (email.isNotEmpty) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent. Check your inbox.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
            Text('Failed to send password reset email. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      _showErrorDialog('Please enter your email address.');
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
        title: const Text('Login'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 5),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  hintText: "Don't forget this :/",
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
              const SizedBox(height: 10),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _submitLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  "Continue",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Row(
                children: [
                  Expanded(
                    child: Divider(),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Account',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                  Expanded(
                    child: Divider(),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  elevation: 0,
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 5),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text(
                  'Create Account',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.grey,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'Or sign in with',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Image.asset(
                      'assets/images/google_logo.png',
                      height: 30,
                    ),
                  ),
                  const SizedBox(height: 10),
                  CarouselSlider(
                    items: const [
                      Text(
                        'Please use your original sign-in method. Email & Password or Google Sign-In.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Your name will be displayed to other users, Please use your real name.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'You will not receive notifications of a chat unless you click on it.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'You can change your profile picture and password in the settings.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 15,
                        ),
                      ),
                    ],
                    options: CarouselOptions(
                      height: 100,
                      autoPlay: true,
                      autoPlayInterval: const Duration(seconds: 3),
                      autoPlayAnimationDuration: const Duration(milliseconds: 800),
                      autoPlayCurve: Curves.fastOutSlowIn,
                      enlargeCenterPage: true,
                      scrollDirection: Axis.horizontal,
                    ),
                  ),
                ],
              ),
              const Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.grey,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      'VChat By Esvin Joshua',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
