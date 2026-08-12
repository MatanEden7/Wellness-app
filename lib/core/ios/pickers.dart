import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import '../../l10n/app_localizations.dart';
import 'native_ui.dart';

/// Date and time entry, on the real `UIDatePicker`.
///
/// Material's `showDatePicker` is a calendar grid in a rectangular card and
/// `showTimePicker` is a clock face — neither exists anywhere in iOS, and the
/// app reached for them twelve times. Both now present the system picker via
/// the bridge; the Cupertino wheels below are the Android/test fallback.

/// [first] and [last] clamp the selectable range; both are optional.
Future<DateTime?> showAppDatePicker({
  required BuildContext context,
  required DateTime initial,
  DateTime? first,
  DateTime? last,
}) async {
  final native = await NativeUI.pickDateTime(
    mode: 'date',
    initial: initial,
    minimum: first,
    maximum: last,
  );
  if (native != null) return native.value;
  if (!context.mounted) return null;

  return _showWheel(
    context: context,
    mode: CupertinoDatePickerMode.date,
    initial: initial,
    minimum: first,
    maximum: last,
  );
}

/// Returns a [TimeOfDay] so call sites that already speak it need no change.
Future<TimeOfDay?> showAppTimePicker({
  required BuildContext context,
  required TimeOfDay initial,
}) async {
  // UIDatePicker works in absolute dates, so the time is carried on an
  // arbitrary day and only the clock fields are read back out.
  final now = DateTime.now();
  final seed =
      DateTime(now.year, now.month, now.day, initial.hour, initial.minute);

  final native = await NativeUI.pickDateTime(mode: 'time', initial: seed);
  if (native != null) {
    final picked = native.value;
    return picked == null
        ? null
        : TimeOfDay(hour: picked.hour, minute: picked.minute);
  }
  if (!context.mounted) return null;

  final result = await _showWheel(
    context: context,
    mode: CupertinoDatePickerMode.time,
    initial: seed,
  );
  return result == null
      ? null
      : TimeOfDay(hour: result.hour, minute: result.minute);
}

/// The fallback wheel, in the standard iOS bottom sheet with Cancel/Done.
Future<DateTime?> _showWheel({
  required BuildContext context,
  required CupertinoDatePickerMode mode,
  required DateTime initial,
  DateTime? minimum,
  DateTime? maximum,
}) {
  final l10n = AppLocalizations.of(context)!;
  var current = initial;

  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (sheetContext) => Container(
      height: 320,
      color: CupertinoColors.systemBackground.resolveFrom(sheetContext),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(l10n.cancel),
              ),
              CupertinoButton(
                onPressed: () => Navigator.of(sheetContext).pop(current),
                child: Text(
                  l10n.done,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Expanded(
            child: CupertinoDatePicker(
              mode: mode,
              initialDateTime: initial,
              minimumDate: minimum,
              maximumDate: maximum,
              onDateTimeChanged: (value) => current = value,
            ),
          ),
        ],
      ),
    ),
  );
}
