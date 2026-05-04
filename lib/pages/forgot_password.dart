import 'package:flutter/material.dart';

import '../color/color_scheme.dart';
import '../services/auth_api.dart';
import '../config/env.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _otpSent = false;
  bool _isLoading = false;

  final _api = AuthApi(baseUrl: Env.apiBaseUrl);

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final res = await _api.sendOtp(email: _emailController.text.trim());
      setState(() => _otpSent = true);
      _showMessage(
        res.devOtp == null ? 'OTP sent to your email.' : 'DEV OTP: ${res.devOtp}',
      );
    } on AuthApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _api.resetPassword(
        email: _emailController.text.trim(),
        otp: _otpController.text.trim(),
        newPassword: _newPasswordController.text,
      );
      _showMessage('Password updated. You can login now.');
      if (mounted) Navigator.pop(context);
    } on AuthApiException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: ColorTheme.mainGradient),
        ),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              "StreamPlay",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "Experience the pulse of sound",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: ColorTheme.mainGradient),
        child: Center(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Forgot Password",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _otpSent
                        ? "Enter the OTP sent to your email and choose a new password."
                        : "Enter your email and we'll send you an OTP.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildField(
                          "Email",
                          _emailController,
                          enabled: !_otpSent && !_isLoading,
                          validator: (value) {
                            final v = (value ?? '').trim();
                            if (v.isEmpty) return "Please enter email";
                            final emailLike = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
                            if (!emailLike.hasMatch(v)) return "Enter a valid email";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_otpSent) ...[
                          _buildField(
                            "OTP",
                            _otpController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              final v = (value ?? '').trim();
                              if (v.isEmpty) return "Enter OTP";
                              if (!RegExp(r'^\d{6}$').hasMatch(v)) {
                                return "OTP must be 6 digits";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            "New Password",
                            _newPasswordController,
                            isPassword: true,
                            validator: (value) {
                              final v = value ?? '';
                              if (v.isEmpty) return "Enter new password";
                              if (v.length < 8) return "Minimum 8 characters";
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            "Confirm Password",
                            _confirmPasswordController,
                            isPassword: true,
                            validator: (value) {
                              final v = value ?? '';
                              if (v.isEmpty) return "Confirm your password";
                              if (v != _newPasswordController.text) {
                                return "Passwords do not match";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
                        _gradientButton(
                          label: _otpSent ? "Reset Password" : "Send OTP",
                          onPressed:
                              _isLoading ? null : (_otpSent ? _resetPassword : _sendOtp),
                        ),
                        const SizedBox(height: 12),
                        if (_otpSent)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Didn't get it? ",
                                style: TextStyle(color: Colors.white),
                              ),
                              GestureDetector(
                                onTap: _isLoading ? null : _sendOtp,
                                child: const Text(
                                  "Resend OTP",
                                  style: TextStyle(
                                    color: Color(0xFF00F0FF),
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00F0FF), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA855F7).withValues(alpha: 0.6),
            blurRadius: 20,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.6),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
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
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      width: 300,
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        enabled: enabled,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [ColorTheme.neonLabelGlow],
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: ColorTheme.neonLabelColor,
            fontWeight: FontWeight.bold,
            shadows: [ColorTheme.neonLabelGlow],
          ),
          filled: true,
          fillColor: Colors.black,
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: ColorTheme.neonLabelColor,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: ColorTheme.neonLabelColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          disabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: ColorTheme.neonLabelColor.withValues(alpha: 0.35),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        validator: validator ?? (value) => value!.isEmpty ? "Enter $label" : null,
      ),
    );
  }
}

