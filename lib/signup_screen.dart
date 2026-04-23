import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final pincodeController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final codeController = TextEditingController();

  File? documentFile;

  bool showPassword = false;
  bool isVerifying = false;

  //////////////////////////////////////////////////////////
  // 📄 PICK DOCUMENT
  //////////////////////////////////////////////////////////
  Future<void> pickDocument() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        documentFile = File(picked.path);
      });
    }
  }

  //////////////////////////////////////////////////////////
  // ☁️ UPLOAD DOCUMENT
  //////////////////////////////////////////////////////////
  Future<void> uploadDocument(File file) async {
    final key = "documents/${DateTime.now().millisecondsSinceEpoch}.jpg";

    await Amplify.Storage.uploadFile(
      localFile: AWSFile.fromPath(file.path),
      key: key,
    ).result;
  }

  //////////////////////////////////////////////////////////
  // ✅ VALIDATION
  //////////////////////////////////////////////////////////
  bool validate() {
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        phoneController.text.length != 10 ||
        addressController.text.isEmpty ||
        pincodeController.text.length != 6 ||
        emailController.text.isEmpty ||
        passwordController.text.length < 6 ||
        documentFile == null) {
      _showSnack("Fill all fields correctly");
      return false;
    }
    return true;
  }

  //////////////////////////////////////////////////////////
  // 🚀 SIGNUP
  //////////////////////////////////////////////////////////
  Future<void> handleSignup() async {
    if (!validate()) return;

    try {
      await Amplify.Auth.signUp(
        username: emailController.text.trim(),
        password: passwordController.text.trim(),
        options: SignUpOptions(userAttributes: {
          CognitoUserAttributeKey.email: emailController.text.trim(),
          CognitoUserAttributeKey.name:
              "${firstNameController.text} ${lastNameController.text}",
          CognitoUserAttributeKey.phoneNumber:
              "+91${phoneController.text}",
        }),
      );

      setState(() {
        isVerifying = true;
      });

      _showSnack("Verification code sent");
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains("exists")) {
        _showSnack("Account already exists. Please login.");
        Navigator.pop(context);
      } else {
        _showSnack(e.message);
      }
    }
  }

  //////////////////////////////////////////////////////////
  // ✅ VERIFY + LOGIN + UPLOAD
  //////////////////////////////////////////////////////////
  Future<void> confirmUser() async {
    try {
      await Amplify.Auth.confirmSignUp(
        username: emailController.text.trim(),
        confirmationCode: codeController.text.trim(),
      );

      _showSnack("Account verified ✅");

      await Amplify.Auth.signIn(
        username: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (documentFile != null) {
        await uploadDocument(documentFile!);
      }

      Navigator.pushReplacementNamed(context, "/home");

    } on AuthException catch (e) {
      if (e.message.contains("confirmed")) {
        _showSnack("Already verified. Please login.");
        Navigator.pop(context);
      } else {
        _showSnack("Invalid code");
      }
    }
  }

  //////////////////////////////////////////////////////////
  // 🔁 RESEND CODE
  //////////////////////////////////////////////////////////
  Future<void> resendCode() async {
    try {
      await Amplify.Auth.resendSignUpCode(
        username: emailController.text.trim(),
      );
      _showSnack("Code resent");
    } catch (e) {
      _showSnack("Error resending code");
    }
  }

  //////////////////////////////////////////////////////////
  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, textAlign: TextAlign.center)),
    );
  }

  InputDecoration inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),

                  //////////////////////////////////////////////////////////
                  // VERIFY SCREEN
                  //////////////////////////////////////////////////////////
                  child: isVerifying
                      ? Column(
                          children: [
                            Text("Verify Account 🔐",
                                style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),

                            SizedBox(height: 20),

                            TextField(
                              controller: codeController,
                              decoration:
                                  inputStyle("Enter Code", Icons.lock),
                            ),

                            SizedBox(height: 20),

                            ElevatedButton(
                              onPressed: confirmUser,
                              child: Text("Verify"),
                            ),

                            TextButton(
                              onPressed: resendCode,
                              child: Text("Resend Code"),
                            ),

                            // ✅ BACK TO LOGIN
                            TextButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: Icon(Icons.arrow_back),
                              label: Text("Back to Login"),
                            ),
                          ],
                        )

                      //////////////////////////////////////////////////////////
                      // SIGNUP FORM
                      //////////////////////////////////////////////////////////
                      : Column(
                          children: [
                            Text("Create Account ✨",
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold)),

                            SizedBox(height: 20),

                            TextField(
                              controller: firstNameController,
                              decoration:
                                  inputStyle("First Name", Icons.person),
                            ),
                            SizedBox(height: 12),

                            TextField(
                              controller: lastNameController,
                              decoration:
                                  inputStyle("Last Name", Icons.person),
                            ),
                            SizedBox(height: 12),

                            TextField(
                              controller: phoneController,
                              decoration:
                                  inputStyle("Phone", Icons.phone),
                            ),
                            SizedBox(height: 12),

                            TextField(
                              controller: addressController,
                              decoration:
                                  inputStyle("Address", Icons.location_on),
                            ),
                            SizedBox(height: 12),

                            TextField(
                              controller: pincodeController,
                              decoration:
                                  inputStyle("Pincode", Icons.pin),
                            ),
                            SizedBox(height: 12),

                            TextField(
                              controller: emailController,
                              decoration:
                                  inputStyle("Email", Icons.email),
                            ),
                            SizedBox(height: 12),

                            TextField(
                              controller: passwordController,
                              obscureText: !showPassword,
                              decoration:
                                  inputStyle("Password", Icons.lock).copyWith(
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

                            SizedBox(height: 15),

                            ElevatedButton.icon(
                              onPressed: pickDocument,
                              icon: Icon(Icons.upload_file),
                              label: Text("Upload Documents"),
                            ),

                            if (documentFile != null)
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Image.file(
                                  documentFile!,
                                  height: 120,
                                ),
                              ),

                            SizedBox(height: 20),

                            ElevatedButton(
                              onPressed: handleSignup,
                              child: Text("Register"),
                            ),

                            SizedBox(height: 10),

                            // ✅ BACK TO LOGIN
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text("Already have an account? Login"),
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