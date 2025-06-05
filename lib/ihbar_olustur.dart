import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'services/ihbar_services.dart';
import 'screens/map_picker_screen.dart';
import 'package:flutter/rendering.dart';

class IhbarOlusturPage extends StatefulWidget {
  const IhbarOlusturPage({super.key});

  @override
  State<IhbarOlusturPage> createState() => _IhbarOlusturPageState();
}

class _IhbarOlusturPageState extends State<IhbarOlusturPage> {
  // Controller
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  // servisler
  final IhbarService _ihbarService = IhbarService();
  final ImagePicker _picker = ImagePicker();
  
  
  String _selectedAnimal = 'Kedi';
  final List<String> _animalTypes = ['Kedi', 'Köpek', 'Diğer'];
  String? _selectedImagePath;
  String? _selectedLocation;
  String? _ihbarKodu;
  bool _isLoading = false;
  File? _imageFile;
  bool _isGettingLocation = false;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _getCurrentLocation() async {
    try {
      setState(() => _isGettingLocation = true);
      
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Konum izni reddedildi';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Konum izinleri kalıcı olarak reddedildi. Lütfen ayarlardan izin verin.';
      }

      
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        forceAndroidLocationManager: true,
        timeLimit: const Duration(seconds: 10),
      );

      // türkiye sınırı içinde mi kontrol 
      if (position.latitude < 35.0 || position.latitude > 43.0 ||
          position.longitude < 25.0 || position.longitude > 45.0) {
        // emülatör konumu için 
        position = Position(
          latitude: 38.375733,
          longitude: 27.172433,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }

      setState(() {
        _selectedLocation = '${position.latitude},${position.longitude}';
      });

    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Konum alınamadı: $e'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kamera ile Çek'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galeriden Seç'),
                onTap: () {
                  Navigator.pop(context);
                  _getImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 720,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
          _selectedImagePath = 'Fotoğraf seçildi';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Fotoğraf başarıyla seçildi'),
            backgroundColor: Colors.green.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf seçilirken hata oluştu: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String?> _uploadImage() async {
  if (_imageFile == null) return null;

  try {
    
    final storageRef = FirebaseStorage.instance.ref();
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final imageRef = storageRef.child('ihbar_resimleri/$fileName');
    
    
    final metadata = SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {'picked-file-path': _imageFile!.path}
    );

    
    print('Uploading file: ${_imageFile!.path}');
    await imageRef.putFile(_imageFile!, metadata);
    
    
    final downloadUrl = await imageRef.getDownloadURL();
    print('Upload successful. URL: $downloadUrl');
    
    return downloadUrl;
  } catch (e) {
    print('Upload error: $e');
    if (!mounted) return null;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fotoğraf yüklenirken hata oluştu: $e'),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
    return null;
  }
}

  bool _isValidPhoneNumber(String phone) {
    // Telefon numarası kontrol (05xxxxxxxxx)
    final phoneRegex = RegExp(r'^05[0-9]{9}$');
    return phoneRegex.hasMatch(phone);
  }

  Future<void> _submitReport() async {
    if (_nameController.text.isEmpty || 
        _phoneController.text.isEmpty || 
        _descriptionController.text.isEmpty ||
        _selectedLocation == null ||
        _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen tüm alanları doldurun (Ad Soyad, Telefon, Açıklama, Konum ve Fotoğraf)'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    
    if (!_isValidPhoneNumber(_phoneController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen geçerli bir telefon numarası girin (05xxxxxxxxx)'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? fotografUrl;
      if (_imageFile != null) {
        fotografUrl = await _uploadImage();
        if (fotografUrl == null) {
          setState(() => _isLoading = false);
          return;
        }
      }

      _ihbarKodu = await _ihbarService.createIhbar(
        adSoyad: _nameController.text,
        telefon: _phoneController.text,
        hayvanTuru: _selectedAnimal,
        aciklama: _descriptionController.text,
        fotografUrl: fotografUrl,
        konum: _selectedLocation,
      );
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ),
      );
      print('Ihbar gönderme hatası: $e');
    }
  }

  void _showSuccessDialog() {
    bool isConfirmed = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade400, size: 30),
                  const SizedBox(width: 10),
                  const Text('İhbar Başarılı'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('İhbarınız başarıyla oluşturuldu.'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'İhbar Kodunuz: $_ihbarKodu',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _ihbarKodu ?? ''));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('İhbar kodu kopyalandı'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          tooltip: 'Kopyala',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lütfen ihbar kodunuzu not alın. İhbarınızın durumunu bu kod ile sorgulayabilirsiniz.',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: isConfirmed,
                        onChanged: (value) {
                          setState(() {
                            isConfirmed = value ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'İhbar kodunu not aldım',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isConfirmed
                      ? () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        }
                      : null,
                  child: Text(
                    'Tamam',
                    style: TextStyle(
                      color: isConfirmed ? Theme.of(context).colorScheme.primary : Colors.grey,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MapPickerScreen(),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result['location'];
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('lib/bucalogo.png'),
        ),
        title: const Text('İhbar Oluştur', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          )),
        centerTitle: true,
        elevation: 2,
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
          physics: const BouncingScrollPhysics(),
          child: Padding(
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
                                Icons.add_alert,
                                size: 40,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Yeni İhbar Oluştur',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Lütfen aşağıdaki formu eksiksiz bir şekilde doldurun',
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
                        if (_imageFile != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(
                                _imageFile!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Ad Soyad',
                            hintText: 'Adınızı ve soyadınızı girin',
                            prefixIcon: const Icon(Icons.person),
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
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 11,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(11),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Telefon Numarası',
                            hintText: '05xxxxxxxxx',
                            prefixIcon: const Icon(Icons.phone),
                            counterText: '',
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
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedAnimal,
                          decoration: InputDecoration(
                            labelText: 'Hayvan Türü',
                            prefixIcon: const Icon(Icons.pets),
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
                          items: _animalTypes.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedAnimal = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _descriptionController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Açıklama',
                            hintText: 'Hayvanın durumu hakkında bilgi veriniz...',
                            alignLabelWithHint: true,
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 60),
                              child: Icon(Icons.description),
                            ),
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
                        ),
                        const SizedBox(height: 24),
                        _buildLocationSection(),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isLoading ? null : _pickImage,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 55),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  side: BorderSide(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                icon: const Icon(Icons.photo_camera, size: 24),
                                label: const Text(
                                  'Fotoğraf Seç',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _submitReport,
                                icon: const Icon(Icons.send),
                                label: const Text(
                                  'İhbarı Gönder',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Konum Bilgisi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedLocation != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedLocation!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange.shade400,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Konum seçilmedi',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _getCurrentLocation,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                  icon: const Icon(Icons.my_location, size: 24),
                  label: const Text(
                    'Konumumu Seç',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectLocation,
                  icon: const Icon(Icons.map),
                  label: const Text('Haritadan Seç'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).colorScheme.primary,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}