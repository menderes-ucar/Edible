import '../../domain/entities/culture_guide.dart';

class CultureGuideItemModel extends CultureGuideItem {
  const CultureGuideItemModel({
    required super.id,
    required super.type,
    required super.title,
    required super.body,
    required super.priority,
    super.phraseLocal,
    super.phrasePronunciation,
    super.phraseTranslation,
  });

  factory CultureGuideItemModel.fromMap(Map<String, dynamic> map) {
    return CultureGuideItemModel(
      id: map['id'].toString(),
      type: CultureTipType.fromValue(
        (map['tip_type'] ?? 'doTip').toString(),
      ),
      title: (map['title'] ?? '').toString(),
      body: (map['body'] ?? '').toString(),
      priority: _toInt(map['priority']) ?? 0,
      phraseLocal: map['phrase_local']?.toString(),
      phrasePronunciation: map['phrase_pronunciation']?.toString(),
      phraseTranslation: map['phrase_translation']?.toString(),
    );
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
