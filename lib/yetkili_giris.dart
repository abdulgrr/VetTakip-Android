import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_panel.dart';

class YetkiliGirisPage extends StatefulWidget {
  const YetkiliGirisPage({super.key});

  @override
  State<YetkiliGirisPage> createState() => _YetkiliGirisPageState();
}

class _YetkiliGirisPageState extends State<YetkiliGirisPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('Giriş denemesi başladı: ${_emailController.text}');
      
     
      final auth = FirebaseAuth.instance;
      
      // Kullanıcı durumu
      auth.authStateChanges().listen((User? user) {
        if (user != null) {
          print('Giriş başarılı: ${user.email}');
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AdminPanel()),
              (route) => false,
            );
          }
        }
      });

      // Kullanıcı girişi deneme
      await auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ).catchError((error) {
        print('Giriş hatası: $error');
        if (error is FirebaseAuthException) {
          String errorMessage;
          switch (error.code) {
            case 'user-not-found':
              errorMessage = 'Kullanıcı bulunamadı';
              break;
            case 'wrong-password':
              errorMessage = 'Yanlış şifre';
              break;
            case 'invalid-email':
              errorMessage = 'Geçersiz email formatı';
              break;
            case 'user-disabled':
              errorMessage = 'Bu hesap devre dışı bırakılmış';
              break;
            case 'too-many-requests':
              errorMessage = 'Çok fazla başarısız giriş denemesi. Lütfen daha sonra tekrar deneyin.';
              break;
            default:
              errorMessage = 'Giriş yapılamadı: ${error.message}';
          }
          setState(() {
            _errorMessage = errorMessage;
          });
        } else {
          setState(() {
            _errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.';
          });
        }
      });
    } catch (e) {
      print('Beklenmeyen hata: $e');
      setState(() {
        _errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yetkili Giriş',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'E-posta gerekli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Şifre',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre gerekli';
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Giriş Yap',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}