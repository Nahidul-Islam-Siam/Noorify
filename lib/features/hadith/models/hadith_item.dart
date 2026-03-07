class HadithItem {
  const HadithItem({
    required this.id,
    required this.uid,
    required this.sourceHadithId,
    required this.category,
    required this.titleEn,
    required this.titleBn,
    required this.arabic,
    required this.english,
    required this.bangla,
    required this.reference,
    required this.audio,
    required this.contentVersion,
    required this.updatedAt,
    required this.isActive,
    required this.sortOrder,
  });

  final int id;
  final String uid;
  final int sourceHadithId;
  final String category;
  final String titleEn;
  final String titleBn;
  final String arabic;
  final String english;
  final String bangla;
  final String reference;
  final String? audio;
  final int contentVersion;
  final String updatedAt;
  final bool isActive;
  final int sortOrder;

  factory HadithItem.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as num?)?.toInt() ?? 0;
    return HadithItem(
      id: id,
      uid: (json['uid'] ?? 'bukhari_${id.toString().padLeft(4, '0')}')
          .toString(),
      sourceHadithId: (json['source_hadith_id'] as num?)?.toInt() ?? 0,
      category: (json['category'] ?? 'general').toString(),
      titleEn: (json['title_en'] ?? '').toString(),
      titleBn: (json['title_bn'] ?? '').toString(),
      arabic: (json['arabic'] ?? '').toString(),
      english: (json['english'] ?? '').toString(),
      bangla: (json['bangla'] ?? '').toString(),
      reference: (json['reference'] ?? '').toString(),
      audio: json['audio']?.toString(),
      contentVersion: (json['content_version'] as num?)?.toInt() ?? 1,
      updatedAt: (json['updated_at'] ?? '').toString(),
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? id,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'source_hadith_id': sourceHadithId,
      'category': category,
      'title_en': titleEn,
      'title_bn': titleBn,
      'arabic': arabic,
      'english': english,
      'bangla': bangla,
      'reference': reference,
      'audio': audio,
      'content_version': contentVersion,
      'updated_at': updatedAt,
      'is_active': isActive,
      'sort_order': sortOrder,
    };
  }
}
