class AsmaName {
  const AsmaName({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.englishMeaning,
    required this.banglaName,
    required this.banglaMeaning,
    required this.audio,
  });

  final int id;
  final String arabic;
  final String transliteration;
  final String englishMeaning;
  final String banglaName;
  final String banglaMeaning;
  final String? audio;

  factory AsmaName.fromJson(Map<String, dynamic> json) {
    return AsmaName(
      id: (json['id'] as num?)?.toInt() ?? 0,
      arabic: (json['arabic'] ?? '').toString(),
      transliteration: (json['transliteration'] ?? '').toString(),
      englishMeaning: (json['englishMeaning'] ?? '').toString(),
      banglaName: (json['banglaName'] ?? '').toString(),
      banglaMeaning: (json['banglaMeaning'] ?? '').toString(),
      audio: json['audio']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'arabic': arabic,
      'transliteration': transliteration,
      'englishMeaning': englishMeaning,
      'banglaName': banglaName,
      'banglaMeaning': banglaMeaning,
      'audio': audio,
    };
  }
}
