import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'models.freezed.dart';
part 'models.g.dart';

const _uuid = Uuid();

@freezed
class SleepEntry with _$SleepEntry {
  const factory SleepEntry({
    required String id,
    required DateTime startedAt,
    DateTime? endedAt,
    int? quality, // 1-5 rating
    String? note,
  }) = _SleepEntry;

  const SleepEntry._();

  factory SleepEntry.create({
    DateTime? startedAt,
    DateTime? endedAt,
    int? quality,
    String? note,
  }) {
    return SleepEntry(
      id: _uuid.v4(),
      startedAt: startedAt ?? DateTime.now(),
      endedAt: endedAt,
      quality: quality,
      note: note,
    );
  }

  bool get isCompleted => endedAt != null;
  
  Duration? get duration {
    if (endedAt == null) return null;
    return endedAt!.difference(startedAt);
  }

  double? get durationInHours {
    final dur = duration;
    if (dur == null) return null;
    return dur.inMinutes / 60.0;
  }

  String get qualityText {
    switch (quality) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Not Rated';
    }
  }

  factory SleepEntry.fromJson(Map<String, dynamic> json) => _$SleepEntryFromJson(json);
}
