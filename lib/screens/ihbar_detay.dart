import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class IhbarDetayPage extends StatefulWidget {
  final String ihbarId;
  final Map<String, dynamic> ihbarData;

  const IhbarDetayPage({
    super.key,
    required this.ihbarId,
    required this.ihbarData,
  });

  @override
  State<IhbarDetayPage> createState() => _IhbarDetayPageState();
}

class _IhbarDetayPageState extends State<IhbarDetayPage> {
  final List<String> _durumOptions = [
    'İhbar Alındı',
    'Tedavi Bekliyor',
    'Tedavi Sürecinde',
    'Tedavi Bitti - Geri Dönmeyi Bekliyor',
    'Süreç Tamamlandı',
    'Hayvan Kurtarılamadı'
  ];

  final TextEditingController _adminNoteController = TextEditingController();
  bool _isEditingNote = false;

  @override
  void initState() {
    super.initState();
    _adminNoteController.text = widget.ihbarData['adminNote'] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final Timestamp timestamp = widget.ihbarData['olusturulmaTarihi'];
    final date = timestamp.toDate();
    final formattedDate = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";

    // debug 
    print('Location data: ${widget.ihbarData['konum']}');
    print('Is location valid: ${_isValidLocation(widget.ihbarData['konum'])}');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'İhbar #${widget.ihbarData['ihbarKodu']}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.ihbarData['fotografUrl'] != null)
              Image.network(
                widget.ihbarData['fotografUrl'],
                height: 300,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusSection(),
                  const Divider(height: 32),
                  _buildInfoSection(formattedDate),
                  const Divider(height: 32),
                  _buildAdminNoteSection(),
                  const Divider(height: 32),
                  if (widget.ihbarData['konum'] != null && 
                      _isValidLocation(widget.ihbarData['konum']))
                    _buildMapSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Durum',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: widget.ihbarData['durum'],
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _durumOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                _updateIhbarStatus(newValue);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String formattedDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('İhbarı Yapan', widget.ihbarData['adSoyad']),
        _buildInfoRow('Telefon', widget.ihbarData['telefon'], isPhone: true),
        _buildInfoRow('Hayvan Türü', widget.ihbarData['hayvanTuru']),
        _buildInfoRow('Tarih', formattedDate),
        _buildInfoRow('Açıklama', widget.ihbarData['aciklama']),
      ],
    );
  }

  Widget _buildAdminNoteSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Yetkili Notu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(_isEditingNote ? Icons.save : Icons.edit),
                onPressed: () {
                  if (_isEditingNote) {
                    _saveAdminNote();
                  } else {
                    setState(() => _isEditingNote = true);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isEditingNote)
            TextField(
              controller: _adminNoteController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'İhbar hakkında not ekleyin...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                widget.ihbarData['adminNote'] ?? 'Henüz not eklenmemiş',
                style: TextStyle(
                  color: widget.ihbarData['adminNote'] == null 
                      ? Colors.grey 
                      : Colors.black,
                ),
              ),
            ),
          if (widget.ihbarData['adminNoteDate'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Son güncelleme: ${_formatDate(widget.ihbarData['adminNoteDate'])}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Widget _buildMapSection() {
    final location = _getLatLngFromString(widget.ihbarData['konum']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Konum',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.directions),
              label: const Text('Yol Tarifi Al'),
              onPressed: () => _openMaps(location),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: location,
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: MarkerId(widget.ihbarData['ihbarKodu']),
                  position: location,
                  infoWindow: InfoWindow(
                    title: 'İhbar Konumu',
                    snippet: widget.ihbarData['hayvanTuru'],
                  ),
                ),
              },
              mapType: MapType.normal,
              zoomControlsEnabled: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: isPhone
                ? GestureDetector(
                    onTap: () => _makePhoneCall(value),
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: const TextStyle(fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateIhbarStatus(String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('ihbarlar')
          .doc(widget.ihbarId)
          .update({'durum': newStatus});

      setState(() {
        widget.ihbarData['durum'] = newStatus;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Durum güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveAdminNote() async {
    try {
      await FirebaseFirestore.instance
          .collection('ihbarlar')
          .doc(widget.ihbarId)
          .update({
        'adminNote': _adminNoteController.text,
        'adminNoteDate': FieldValue.serverTimestamp(),
      });

      setState(() {
        widget.ihbarData['adminNote'] = _adminNoteController.text;
        _isEditingNote = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not kaydedildi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> _openMaps(LatLng location) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('İhbarı Sil'),
        content: const Text('Bu ihbarı silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteIhbar();
            },
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteIhbar() async {
    try {
      await FirebaseFirestore.instance
          .collection('ihbarlar')
          .doc(widget.ihbarId)
          .delete();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İhbar başarıyla silindi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silme işlemi başarısız: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  LatLng _getLatLngFromString(String? locationString) {
    if (locationString == null) {
      return const LatLng(38.375670, 27.172400);
    }

    try {
      
      final parts = locationString.split(',');
      if (parts.length != 2) return const LatLng(38.375670, 27.172400);

      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);

      if (lat == null || lng == null) return const LatLng(38.375670, 27.172400);

      return LatLng(lat, lng);
    } catch (e) {
      return const LatLng(38.375670, 27.172400);
    }
  }

  bool _isValidLocation(String? location) {
    if (location == null) return false;
    try {
      final parts = location.split(',');
      if (parts.length != 2) return false;

      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);

      return lat != null && lng != null;
    } catch (e) {
      return false;
    }
  }
}