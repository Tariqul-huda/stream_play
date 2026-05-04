import 'package:flutter/material.dart';
import './signup.dart';
import './forgot_password.dart';
import './home_page.dart';
import '../services/auth_api.dart';
import '../config/env.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _api = AuthApi(baseUrl: Env.apiBaseUrl);

  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _api.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } on AuthApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Colors.black,
        appBar: AppBar(
          centerTitle: true,
          // backgroundColor: Colors.transparent,
          // elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F2027), // dark blue
                  Color(0xFF203A43), // teal
                  Color(0xFF2C5364), // bluish
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                "StreamPlay",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              Text(
                "Experience the pulse of sound",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      body:
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F2027), // dark blue
              Color(0xFF203A43), // teal
              Color(0xFF2C5364), // bluish
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      child: Center(
        child: Container(
          width: 350,
          height: 400,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.
            //   )
            // ]
          ),
          child: Column(
            children: [
              SizedBox(height: 20),
              Text(
                "Welcome Back",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                ),
              ),
              SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 300,
                      child: TextFormField(
                        controller: _emailController,
                        style: const TextStyle(
                          color: Colors.white, // input text color
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Color(0xFF00FFFF), // neon cyan glow
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        decoration: InputDecoration(
                          labelText: "Email",
                          labelStyle: const TextStyle(
                            color: Color(0xFF00FFFF), // neon label color
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Color(0xFF00FFFF), blurRadius: 5),
                            ],
                          ),
                          filled: true,
                          fillColor:
                              Colors.black, // background color of input field
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF00FFFF), // neon border color
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF00FFFF),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Please Enter Email" : null,
                      ),
                    ),

                    //gap between field
                    const SizedBox(height: 16),

                    //gap between field
                    SizedBox(
                      width: 300,
                      child: TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(
                          color: Colors.white, // input text color
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Color(0xFF00FFFF), // neon cyan glow
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: const TextStyle(
                            color: Color(0xFF00FFFF), // neon label color
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Color(0xFF00FFFF), blurRadius: 5),
                            ],
                          ),
                          filled: true,
                          fillColor:
                              Colors.black, // background color of input field
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF00FFFF), // neon border color
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF00FFFF),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? "Please Enter Password" : null,
                      ),
                    ),

                    //gap
                    const SizedBox(height: 10),
                    SizedBox(
                      width: 300,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Forgot password?",
                            style: TextStyle(
                              color: Color(0xFF00F0FF),
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    //gap
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00F0FF), Color(0xFFA855F7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFA855F7).withValues(alpha:0.6),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: const Color(0xFF00F0FF).withValues(alpha:0.6),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(200, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.black, // dark text for contrast
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15,),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Colors.white),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) =>  SignUpPage()),
                      );
                    },
                    child: const Text(
                      "Sign up",
                      style: TextStyle(
                        color: Color(0xFF00F0FF), // cyan accent
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              )

            ],
          ),
        ),
      ),
    )
    );
  }
}
