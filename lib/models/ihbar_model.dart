class Ihbar {
  final String id;
  final String ihbarKodu;
  final String adSoyad;
  final String telefon;
  final String hayvanTuru;
  final String aciklama;
  final String? fotografUrl;
  final String? konum;
  final String durum;
  final DateTime olusturulmaTarihi;

  Ihbar({
    required this.id,
    required this.ihbarKodu,
    required this.adSoyad,
    required this.telefon,
    required this.hayvanTuru,
    required this.aciklama,
    this.fotografUrl,
    this.konum,
    this.durum = 'Beklemede',
    required this.olusturulmaTarihi,
  });

  Map<String, dynamic> toMap() {
    return {
      'ihbarKodu': ihbarKodu,
      'adSoyad': adSoyad,
      'telefon': telefon,
      'hayvanTuru': hayvanTuru,
      'aciklama': aciklama,
      'fotografUrl': fotografUrl,
      'konum': konum,
      'durum': durum,
      'olusturulmaTarihi': olusturulmaTarihi.toIso8601String(),
    };
  }

  factory Ihbar.fromMap(String id, Map<String, dynamic> map) {
    return Ihbar(
      id: id,
      ihbarKodu: map['ihbarKodu'],
      adSoyad: map['adSoyad'],
      telefon: map['telefon'],
      hayvanTuru: map['hayvanTuru'],
      aciklama: map['aciklama'],
      fotografUrl: map['fotografUrl'],
      konum: map['konum'],
      durum: map['durum'],
      olusturulmaTarihi: DateTime.parse(map['olusturulmaTarihi']),
    );
  }
}