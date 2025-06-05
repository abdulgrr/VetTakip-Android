import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'screens/ihbar_detay.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  State<AdminPanel> createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedFilter = 'Tümü';
  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _filterOptions = [
    'Tümü',
    'İhbar Alındı',
    'Tedavi Bekliyor',
    'Tedavi Sürecinde',
    'Tedavi Bitti - Geri Dönmeyi Bekliyor',
    'Süreç Tamamlandı',
    'Hayvan Kurtarılamadı'
  ];

  Stream<QuerySnapshot> _buildQuery() {
    Query query = _firestore.collection('ihbarlar');

    // Sadece durum filtresi uygulama
    if (_selectedFilter != 'Tümü') {
      query = query.where('durum', isEqualTo: _selectedFilter);
    }

    return query.orderBy('olusturulmaTarihi', descending: true).snapshots();
  }

  List<QueryDocumentSnapshot> _filterByDate(List<QueryDocumentSnapshot> docs) {
    if (_startDate == null && _endDate == null) {
      return docs;
    }

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['olusturulmaTarihi'] as Timestamp;
      final date = timestamp.toDate();

      if (_startDate != null && date.isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null) {
        final endOfDay = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59);
        if (date.isAfter(endOfDay)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            )),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () async {
                        await _auth.signOut();
                        if (mounted) {
                          Navigator.pop(context); // Diyaloğu kapa
                          Navigator.pushReplacementNamed(context, '/'); // Anasayfaya yönlendir
                        }
                      },
                      child: const Text(
                        'Çıkış Yap',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.filter_list),
                    const SizedBox(width: 8),
                    const Text('Filtrele:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: _selectedFilter,
                        isExpanded: true,
                        items: _filterOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() => _selectedFilter = newValue);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 8),
                    const Text('Tarih Aralığı:'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context, true),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_startDate == null 
                          ? 'Başlangıç Tarihi' 
                          : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _selectDate(context, false),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_endDate == null 
                          ? 'Bitiş Tarihi' 
                          : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'),
                      ),
                    ),
                    if (_startDate != null || _endDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearDateFilter,
                        tooltip: 'Tarih Filtresini Temizle',
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _buildQuery(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredDocs = _filterByDate(snapshot.data?.docs ?? []);

                if (filteredDocs.isEmpty) {
                  return const Center(child: Text('İhbar bulunamadı'));
                }

                return ListView.builder(
                  itemCount: filteredDocs.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final Timestamp timestamp = data['olusturulmaTarihi'];
                    final date = timestamp.toDate();
                    final formattedDate = "${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}";

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          'İhbar #${data['ihbarKodu']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, 
                                    size: 16, 
                                    color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(formattedDate),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.pets, 
                                    size: 16, 
                                    color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${data['hayvanTuru']} - ${data['adSoyad']}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getStatusColor(data['durum']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _getStatusIcon(data['durum']),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => IhbarDetayPage(
                                ihbarId: doc.id,
                                ihbarData: data,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _clearDateFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
  }

  Icon _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'ihbar alındı':
        return Icon(Icons.notifications_active, color: Colors.blue.shade700);
      case 'tedavi bekliyor':
        return Icon(Icons.schedule, color: Colors.orange.shade700);
      case 'tedavi sürecinde':
        return Icon(Icons.medical_services, color: Colors.purple.shade700);
      case 'tedavi bitti - geri dönmeyi bekliyor':
        return Icon(Icons.home, color: Colors.teal.shade700);
      case 'süreç tamamlandı':
        return Icon(Icons.check_circle, color: Colors.green.shade700);
      case 'hayvan kurtarılamadı':
        return Icon(Icons.error, color: Colors.red.shade700);
      default:
        return const Icon(Icons.info);
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
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
      case 'hayvan kurtarılamadı':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}