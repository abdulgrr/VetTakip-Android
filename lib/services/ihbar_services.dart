import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class IhbarService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  String generateIhbarKodu() {
    return _uuid.v4().substring(0, 6).toUpperCase();
  }

  Future<String> createIhbar({
    required String adSoyad,
    required String telefon,
    required String hayvanTuru,
    required String aciklama,
    String? fotografUrl,
    String? konum,
  }) async {
    try {
      final ihbarKodu = generateIhbarKodu();
      
      await _firestore.collection('ihbarlar').add({
        'ihbarKodu': ihbarKodu,
        'adSoyad': adSoyad,
        'telefon': telefon,
        'hayvanTuru': hayvanTuru,
        'aciklama': aciklama,
        'fotografUrl': fotografUrl,
        'konum': konum,
        'durum': 'İhbar Alındı',
        'olusturulmaTarihi': FieldValue.serverTimestamp(),
      });
      
      return ihbarKodu;
    } catch (e) {
      print('Ihbar oluşturma hatası: $e');
      throw Exception('İhbar oluşturulurken bir hata oluştu');
    }
  }

  Future<Map<String, dynamic>?> getIhbarByKod(String ihbarKodu) async {
    try {
      final querySnapshot = await _firestore
          .collection('ihbarlar')
          .where('ihbarKodu', isEqualTo: ihbarKodu)
          .get();

      if (querySnapshot.docs.isEmpty) return null;
      return querySnapshot.docs.first.data();
    } catch (e) {
      print('Ihbar sorgulama hatası: $e');
      throw Exception('İhbar sorgulanırken bir hata oluştu');
    }
  }
}