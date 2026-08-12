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

  // No `qualityText` getter here. Wording for a 1-5 rating is a presentation
  // concern and this getter hardcoded English, so a Hebrew user saw "Very
  // Good" in the middle of an otherwise translated card. Use
  // `qualityLabel(l10n, quality)` from `sleep/ui/sleep_page.dart` instead.

  factory SleepEntry.fromJson(Map<String, dynamic> json) =>
      _$SleepEntryFromJson(json);
}
