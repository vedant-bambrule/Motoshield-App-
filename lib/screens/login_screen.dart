import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_isSignUp) {
        await _auth.signUp(name: _nameCtrl.text.trim(), email: _emailCtrl.text.trim(), password: _passCtrl.text);
      } else {
        await _auth.signIn(email: _emailCtrl.text.trim(), password: _passCtrl.text);
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const HomeShell()));
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: AppColors.orangeDim, borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.shield_outlined, color: AppColors.orange, size: 26),
              ),
              const SizedBox(height: 22),
              const Text('MOTOSHIELD', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.text)),
              const SizedBox(height: 10),
              Text(_isSignUp ? 'Create your rider account.' : 'Welcome back.', style: const TextStyle(color: AppColors.textDim)),
              const SizedBox(height: 32),

              if (_isSignUp) ...[
                _field('Full name', _nameCtrl),
                const SizedBox(height: 12),
              ],
              _field('Email', _emailCtrl, keyboard: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _field('Password', _passCtrl, obscure: true),

              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : Text(_isSignUp ? 'Create account' : 'Log in', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(
                  _isSignUp ? 'Already have an account? Log in' : "New rider? Create an account",
                  style: const TextStyle(color: AppColors.orange),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {bool obscure = false, TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(label),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          keyboardType: keyboard,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lineStrong)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lineStrong)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
