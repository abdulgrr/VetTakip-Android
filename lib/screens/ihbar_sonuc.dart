import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IhbarSonucPage extends StatefulWidget {
  final Map<String, dynamic> ihbarData;

  const IhbarSonucPage({
    super.key,
    required this.ihbarData,
  });

  @override
  State<IhbarSonucPage> createState() => _IhbarSonucPageState();
}

class _IhbarSonucPageState extends State<IhbarSonucPage> {
  @override
  void initState() {
    super.initState();
    // Eğer durum "Kurtarılamadı" veya "hayvan kurtarılamadı" ise pop-up göster
    final durum = widget.ihbarData['durum'].toString().toLowerCase();
    if (durum.contains('kurtarılamadı')) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showUnsuccessfulDialog();
      });
    }
  }

  void _showUnsuccessfulDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.sentiment_dissatisfied, color: Colors.red.shade400, size: 30),
            const SizedBox(width: 10),
            const Text('Üzgünüz'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tüm çabalarımıza rağmen hayvanı kurtaramadık.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bu durum için çok üzgünüz. Hayvanın son anlarında yanında olmaya çalıştık ve gerekli tüm müdahaleleri yaptık.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Anladım'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'İhbar #${widget.ihbarData['ihbarKodu']}',
          style: const TextStyle(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getDurumColor(widget.ihbarData['durum']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getDurumIcon(widget.ihbarData['durum']),
                              color: _getDurumColor(widget.ihbarData['durum']),
                              size: 30,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'İhbar Durumu',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.ihbarData['durum'],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _getDurumColor(widget.ihbarData['durum']),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInfoRow(context, 'İhbar Kodu', widget.ihbarData['ihbarKodu']),
                      _buildInfoRow(context, 'Hayvan Türü', widget.ihbarData['hayvanTuru']),
                      _buildInfoRow(context, 'Tarih', _formatDate(widget.ihbarData['olusturulmaTarihi'])),
                      if (widget.ihbarData['fotografUrl'] != null) ...[
                        const SizedBox(height: 24),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            widget.ihbarData['fotografUrl'],
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                      _buildAdminNoteSection(context, widget.ihbarData),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _getInfoIcon(label),
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminNoteSection(BuildContext context, Map<String, dynamic> ihbarData) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_alt,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Yetkili Notu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              ihbarData['adminNote'] ?? 'Henüz not eklenmemiş',
              style: TextStyle(
                fontSize: 15,
                color: ihbarData['adminNote'] == null 
                    ? Colors.grey 
                    : Colors.black87,
              ),
            ),
          ),
          if (ihbarData['adminNoteDate'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Son güncelleme: ${_formatDate(ihbarData['adminNoteDate'])}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  IconData _getInfoIcon(String label) {
    switch (label) {
      case 'İhbar Kodu':
        return Icons.numbers;
      case 'Hayvan Türü':
        return Icons.pets;
      case 'Tarih':
        return Icons.calendar_today;
      default:
        return Icons.info;
    }
  }

  IconData _getDurumIcon(String durum) {
    final lowerDurum = durum.toLowerCase();
    if (lowerDurum.contains('kurtarılamadı')) {
      return Icons.sentiment_dissatisfied;
    }
    switch (lowerDurum) {
      case 'ihbar alındı':
        return Icons.notifications_active;
      case 'tedavi bekliyor':
        return Icons.medical_services;
      case 'tedavi sürecinde':
        return Icons.healing;
      case 'tedavi bitti - geri dönmeyi bekliyor':
        return Icons.home;
      case 'süreç tamamlandı':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Color _getDurumColor(String durum) {
    final lowerDurum = durum.toLowerCase();
    if (lowerDurum.contains('kurtarılamadı')) {
      return Colors.red;
    }
    switch (lowerDurum) {
      case 'ihbar alındı':
        return Colors.blue;
      case 'tedavi bekliyor':
        return Colors.orange;
      case 'tedavi sürecinde':
        return Colors.purple;
      case 'tedavi bitti - geri dönmeyi bekliyor':
        return Colors.teal;
      case 'süreç tamamlandı':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }
} 