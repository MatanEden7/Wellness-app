/// The scroll edge effect: a bar carries no material until content is under it.
///
/// This is the behaviour the app spent three attempts failing to fake — a glass
/// band under the date strip (a second pane stacked over the page's own), no
/// band at all (content collided with the controls), then unpinning the strip
/// entirely. All three were workarounds for a missing signal: nothing observed
/// the scroll offset, so no bar could know whether anything was beneath it.
@Tags(['ui'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_app/core/design/scroll_edge.dart';

void main() {
  /// A page whose bar reports what the scroll edge tells it.
  Widget host({ValueChanged<bool>? onChanged}) => MaterialApp(
        home: Scaffold(
          body: ScrollEdgeObserver(
            onChanged: onChanged,
            child: Builder(
              builder: (context) => Column(
                children: [
                  Text(ScrollEdgeScope.of(context) ? 'material' : 'bare'),
                  Expanded(
                    child: ListView(
                      children: [
                        for (var i = 0; i < 40; i++)
                          SizedBox(height: 40, child: Text('row $i')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  testWidgets('at rest the bar is bare', (tester) async {
    await tester.pumpWidget(host());
    expect(find.text('bare'), findsOneWidget);
  });

  testWidgets('the material appears once content is underneath',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump();
    expect(find.text('material'), findsOneWidget);
  });

  testWidgets('scrolling back to the top takes the material away again',
      (tester) async {
    await tester.pumpWidget(host());
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, 400));
    await tester.pump();
    expect(find.text('bare'), findsOneWidget);
  });

  testWidgets('the callback fires on transitions, not on every frame',
      (tester) async {
    // The callback crosses a platform channel to reach UIKit. One message per
    // scroll frame would be the most expensive thing in the app; the observer
    // has to reduce the offset to a single bit and only report when it flips.
    final events = <bool>[];
    await tester.pumpWidget(host(onChanged: events.add));

    for (var i = 0; i < 5; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -60));
      await tester.pump();
    }
    expect(events, [true],
        reason: 'five separate drags past the threshold are still one '
            'transition');

    await tester.drag(find.byType(ListView), const Offset(0, 1000));
    await tester.pump();
    expect(events, [true, false]);
  });

  testWidgets('a horizontal inner list does not speak for the page',
      (tester) async {
    // A filter bar scrolling sideways, or a nested list scrolling inside a
    // card, must not tell the nav bar that the *page* has moved.
    final events = <bool>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ScrollEdgeObserver(
          onChanged: events.add,
          child: ListView(
            children: [
              SizedBox(
                height: 60,
                child: ListView(
                  key: const Key('filters'),
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < 20; i++)
                      const SizedBox(width: 80, child: Text('chip')),
                  ],
                ),
              ),
              for (var i = 0; i < 30; i++) const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    ));

    await tester.drag(find.byKey(const Key('filters')), const Offset(-300, 0));
    await tester.pump();
    expect(events, isEmpty,
        reason: 'a sideways filter bar is not the page scrolling');
  });

  testWidgets('with no observer installed, bars get the at-rest look',
      (tester) async {
    // Android and every widget test: no scope, so `false` — bare — which is the
    // correct default for a shell that has no scroll edge effect at all.
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) =>
            Text(ScrollEdgeScope.of(context) ? 'material' : 'bare'),
      ),
    ));
    expect(find.text('bare'), findsOneWidget);
  });
}
