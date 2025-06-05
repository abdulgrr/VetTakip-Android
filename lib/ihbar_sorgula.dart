import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/ihbar_sonuc.dart';

class IhbarSorgulaPage extends StatefulWidget {
  const IhbarSorgulaPage({super.key});

  @override
  State<IhbarSorgulaPage> createState() => _IhbarSorgulaPageState();
}

class _IhbarSorgulaPageState extends State<IhbarSorgulaPage> {
  final _formKey = GlobalKey<FormState>();
  final _ihbarKoduController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sorgulaIhbar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('ihbarlar')
          .where('ihbarKodu', isEqualTo: _ihbarKoduController.text.toUpperCase())
          .get();

      if (querySnapshot.docs.isEmpty) {
        _showError('İhbar bulunamadı');
      } else {
        final ihbarData = querySnapshot.docs.first.data();
        
        
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IhbarSonucPage(ihbarData: ihbarData),
          ),
        );
      }
    } catch (e) {
      _showError('Bir hata oluştu: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('lib/bucalogo.png'),
        ),
        title: const Text('İhbar Sorgula',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            )),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.search,
                                size: 40,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'İhbar Kodunuzu Girin',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'İhbar durumunuzu öğrenmek için ihbar kodunuzu girin',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _ihbarKoduController,
                          decoration: InputDecoration(
                            labelText: 'İhbar Kodu',
                            hintText: 'Örn: ABC123',
                            prefixIcon: const Icon(Icons.numbers),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'İhbar kodu gerekli';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _sorgulaIhbar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 3,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'Sorgula',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ihbarKoduController.dispose();
    super.dispose();
  }
}