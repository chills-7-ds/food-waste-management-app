import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final codeController = TextEditingController();
  final newPasswordController = TextEditingController();

  bool showPassword = false;
  bool isResetStep2 = false;

  //////////////////////////////////////////////////////////
  // 🔐 LOGIN (IMPROVED SAFE VERSION)
  //////////////////////////////////////////////////////////
  Future<void> handleLogin() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      _showSnack("Enter email & password");
      return;
    }

    try {
      // ✅ SAFELY SIGN OUT (avoid crash if no session)
      try {
        await Amplify.Auth.signOut();
      } catch (_) {}

      final res = await Amplify.Auth.signIn(
        username: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (res.isSignedIn) {
        _showSnack("Login successful ✅");

        Navigator.pushReplacementNamed(context, "/home");
      } else {
        _showSnack("Please verify your account first");
      }

    } on AuthException catch (e) {
      if (e.message.contains("User does not exist")) {
        _showSnack("Account not found. Please signup.");
      } else if (e.message.contains("Incorrect username or password")) {
        _showSnack("Wrong password");
      } else if (e.message.contains("User is not confirmed")) {
        _showSnack("Please verify your email first");
      } else {
        _showSnack(e.message);
      }
    } catch (e) {
      _showSnack("Login failed. Try again.");
    }
  }

  //////////////////////////////////////////////////////////
  // 🔑 SEND RESET CODE
  //////////////////////////////////////////////////////////
  Future<void> forgotPassword() async {
    if (emailController.text.isEmpty) {
      _showSnack("Enter email first");
      return;
    }

    try {
      await Amplify.Auth.resetPassword(
        username: emailController.text.trim(),
      );

      setState(() {
        isResetStep2 = true;
      });

      _showSnack("Reset code sent to email");

    } on AuthException catch (e) {
      _showSnack(e.message);
    }
  }

  //////////////////////////////////////////////////////////
  // 🔑 CONFIRM RESET
  //////////////////////////////////////////////////////////
  Future<void> confirmResetPassword() async {
    if (codeController.text.isEmpty ||
        newPasswordController.text.isEmpty) {
      _showSnack("Fill all fields");
      return;
    }

    try {
      await Amplify.Auth.confirmResetPassword(
        username: emailController.text.trim(),
        newPassword: newPasswordController.text.trim(),
        confirmationCode: codeController.text.trim(),
      );

      _showSnack("Password reset successful ✅");

      setState(() {
        isResetStep2 = false;
      });

    } on AuthException catch (e) {
      _showSnack(e.message);
    }
  }

  //////////////////////////////////////////////////////////
  // SNACKBAR
  //////////////////////////////////////////////////////////
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textAlign: TextAlign.center)),
    );
  }

  //////////////////////////////////////////////////////////
  // INPUT STYLE
  //////////////////////////////////////////////////////////
  InputDecoration inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  //////////////////////////////////////////////////////////
  // UI
  //////////////////////////////////////////////////////////
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade300, Colors.green.shade800],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Padding(
                  padding: EdgeInsets.all(25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // TITLE
                      Text(
                        isResetStep2
                            ? "Reset Password 🔑"
                            : "Welcome Back 👋",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),

                      SizedBox(height: 20),

                      // EMAIL
                      TextField(
                        controller: emailController,
                        decoration: inputStyle("Email", Icons.email),
                      ),

                      SizedBox(height: 15),

                      // PASSWORD
                      if (!isResetStep2)
                        TextField(
                          controller: passwordController,
                          obscureText: !showPassword,
                          decoration: inputStyle("Password", Icons.lock)
                              .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(showPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () {
                                setState(() {
                                  showPassword = !showPassword;
                                });
                              },
                            ),
                          ),
                        ),

                      // RESET UI
                      if (isResetStep2)
                        Column(
                          children: [
                            TextField(
                              controller: codeController,
                              decoration: inputStyle(
                                  "Enter Code", Icons.verified),
                            ),
                            SizedBox(height: 15),
                            TextField(
                              controller: newPasswordController,
                              obscureText: true,
                              decoration: inputStyle(
                                  "New Password", Icons.lock),
                            ),
                          ],
                        ),

                      SizedBox(height: 20),

                      // BUTTON
                      ElevatedButton(
                        onPressed: isResetStep2
                            ? confirmResetPassword
                            : handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: EdgeInsets.symmetric(
                              vertical: 14, horizontal: 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Text(
                          isResetStep2 ? "Reset Password" : "Login",
                        ),
                      ),

                      // FORGOT PASSWORD
                      if (!isResetStep2)
                        TextButton(
                          onPressed: forgotPassword,
                          child: Text("Forgot Password?"),
                        ),

                      // SIGNUP
                      if (!isResetStep2)
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => SignupScreen()),
                            );
                          },
                          child: Text("Create new account"),
                        ),

                      // BACK
                      if (isResetStep2)
                        TextButton(
                          onPressed: () {
                            setState(() {
                              isResetStep2 = false;
                            });
                          },
                          child: Text("Back to Login"),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}