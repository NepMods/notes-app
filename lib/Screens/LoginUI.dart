import 'package:flutter/material.dart';
import 'package:notes/Screens/RegisterUI.dart';
import 'package:notes/Screens/DasboardUI.dart';
import 'package:notes/Api/api.dart';
import 'package:notes/Screens/Components/AccountPrompt.dart';
import 'package:notes/Screens/Components/ButtonView.dart';
import 'package:notes/Screens/Components/EmailInput.dart';
import 'package:notes/Screens/Components/HeroImage.dart';
import 'package:notes/Screens/Components/PasswordInput.dart';
import 'package:notes/Screens/Components/TitleView.dart';
import 'package:notes/EncryptedDatabase/EncryptedDatabase.dart';

import 'package:sonner_flutter/sonner_flutter.dart';

class LoginUI extends StatefulWidget {
  LoginUI({Key? key}) : super(key: key);

  @override
  _LoginUIState createState() => _LoginUIState();
}

class _LoginUIState extends State<LoginUI> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  bool obscureText = true;

  @override
  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      final registerSuccess = await login(
        _emailController.text,
        _passwordController.text,
      );

      if (registerSuccess.status) {
        EncryptedDatabase.instance.write(
          "token",
          registerSuccess.data["token"],
        );
        EncryptedDatabase.instance.write("isLoginDone", true);
        Toast.success(context, "Login Successful");
        Navigator.pushNamed(
          context,
          "/notes"
        );
      } else {
        Toast.error(context, registerSuccess.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              // Hero iMAGE / Lottie assets
              HeroImage(),

              // Title and subtitle
              TitleView(
                title: "Welcome Back",
                subtitle: "Please login to continue",
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.03),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    //Email Field
                    EmailInput(emailController: _emailController),

                    SizedBox(height: MediaQuery.of(context).size.height * 0.03),

                    //Password Input
                    Passwordinput(
                      text: "Password",
                      obText: obscureText,
                      passwordController: _passwordController,
                      suffixIcon: GestureDetector(
                        onTap: () {
                          setState(() {
                            obscureText = !obscureText;
                          });
                        },
                        child: () {
                          if (obscureText) {
                            return const Icon(Icons.visibility_outlined);
                          } else {
                            return const Icon(Icons.visibility_off_outlined);
                          }
                        }(),
                      ),
                      validatorFunc: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        } else if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.025),

              //Sign up button
              ButtonView(
                onPressed: () async {
                  await _register();
                },
                buttonText: "Login",
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.009),

              AccountPrompt(
                onLoginTap: () => {Navigator.pushNamed(context, '/register')},
                promptText: "Don't have an Account?",
                actionText: "Register",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
