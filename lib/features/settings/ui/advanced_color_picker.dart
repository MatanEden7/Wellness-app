import 'package:flutter/material.dart';
import 'package:wellness_app/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/contrast.dart';
import '../../../core/ios/glass.dart';
import '../../../core/design/tokens.dart';

class AdvancedColorPicker extends HookConsumerWidget {
  final String label;
  final IconData icon;
  final Color initialColor;
  final Future<void> Function(Color) onColorChanged;
  final String scope;

  const AdvancedColorPicker({
    super.key,
    required this.label,
    required this.icon,
    required this.initialColor,
    required this.onColorChanged,
    required this.scope,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedColor = useState(initialColor);
    final previousColor = initialColor;
    final hexController = useTextEditingController(
      text: _colorToHex(initialColor),
    );
    final redController = useTextEditingController(
      text: initialColor.red.toString(),
    );
    final greenController = useTextEditingController(
      text: initialColor.green.toString(),
    );
    final blueController = useTextEditingController(
      text: initialColor.blue.toString(),
    );
    final alphaValue = useState(initialColor.a);

    // HSV values for the pickers
    final hsvColor = useState(HSVColor.fromColor(initialColor));

    // Presets - curated accessible colors
    final presetColors = [
      // Reds
      const Color(0xFFB71C1C),
      const Color(0xFFE53935),
      const Color(0xFFEF5350),
      const Color(0xFFE91E63),
      // Purples
      const Color(0xFF6A1B9A),
      const Color(0xFF9C27B0),
      const Color(0xFF7E57C2),
      const Color(0xFF5E35B1),
      // Blues
      const Color(0xFF1565C0),
      const Color(0xFF1976D2),
      const Color(0xFF42A5F5),
      const Color(0xFF0288D1),
      // Cyans/Teals
      const Color(0xFF00838F),
      const Color(0xFF00ACC1),
      const Color(0xFF00695C),
      const Color(0xFF00897B),
      // Greens
      const Color(0xFF2E7D32),
      const Color(0xFF43A047),
      const Color(0xFF66BB6A),
      const Color(0xFF7CB342),
      // Yellows/Oranges
      const Color(0xFFF57C00),
      const Color(0xFFFF6F00),
      const Color(0xFFFFA726),
      const Color(0xFFFF9800),
    ];

    // Update all controls when color changes
    void updateFromColor(Color color) {
      selectedColor.value = color;
      hsvColor.value = HSVColor.fromColor(color);
      hexController.text = _colorToHex(color);
      redController.text = color.red.toString();
      greenController.text = color.green.toString();
      blueController.text = color.blue.toString();
      alphaValue.value = color.a;
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return GlassSheet(
          radius: 20,
          child: SafeArea(
            bottom: true,
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: Space.md),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Space.xl, vertical: Space.sm),
                  child: Row(
                    children: [
                      Icon(icon, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'Pick $label Color',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(Space.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Preview Section
                        _buildPreviewSection(
                            context, selectedColor.value, previousColor),
                        const SizedBox(height: 24),

                        // Contrast Indicator
                        _buildContrastIndicator(context, selectedColor.value),
                        const SizedBox(height: 24),

                        // Hue Picker
                        Text(
                          AppLocalizations.of(context)!.hue,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        HuePicker(
                          hue: hsvColor.value.hue,
                          onChanged: (hue) {
                            final newHsv = hsvColor.value.withHue(hue);
                            hsvColor.value = newHsv;
                            updateFromColor(newHsv.toColor());
                          },
                        ),
                        const SizedBox(height: 24),

                        // Saturation-Brightness Picker
                        Text(
                          AppLocalizations.of(context)!.saturationAndBrightness,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        SaturationBrightnessPicker(
                          hue: hsvColor.value.hue,
                          saturation: hsvColor.value.saturation,
                          value: hsvColor.value.value,
                          onChanged: (saturation, brightness) {
                            final newHsv = HSVColor.fromAHSV(
                              hsvColor.value.alpha,
                              hsvColor.value.hue,
                              saturation,
                              brightness,
                            );
                            hsvColor.value = newHsv;
                            updateFromColor(newHsv.toColor());
                          },
                        ),
                        const SizedBox(height: 24),

                        // HSVA Sliders
                        Text(
                          AppLocalizations.of(context)!.preciseControls,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        _HSVASlider(
                          label: 'H',
                          value: hsvColor.value.hue,
                          min: 0,
                          max: 360,
                          suffix: '°',
                          onChanged: (value) {
                            final newHsv = hsvColor.value.withHue(value);
                            hsvColor.value = newHsv;
                            updateFromColor(newHsv.toColor());
                          },
                          gradientBuilder: (width) => const LinearGradient(
                            colors: [
                              Color(0xFFFF0000),
                              Color(0xFFFFFF00),
                              Color(0xFF00FF00),
                              Color(0xFF00FFFF),
                              Color(0xFF0000FF),
                              Color(0xFFFF00FF),
                              Color(0xFFFF0000),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _HSVASlider(
                          label: 'S',
                          value: hsvColor.value.saturation * 100,
                          min: 0,
                          max: 100,
                          suffix: '%',
                          onChanged: (value) {
                            final newHsv =
                                hsvColor.value.withSaturation(value / 100);
                            hsvColor.value = newHsv;
                            updateFromColor(newHsv.toColor());
                          },
                          gradientBuilder: (width) => LinearGradient(
                            colors: [
                              HSVColor.fromAHSV(1, hsvColor.value.hue, 0,
                                      hsvColor.value.value)
                                  .toColor(),
                              HSVColor.fromAHSV(1, hsvColor.value.hue, 1,
                                      hsvColor.value.value)
                                  .toColor(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _HSVASlider(
                          label: 'B',
                          value: hsvColor.value.value * 100,
                          min: 0,
                          max: 100,
                          suffix: '%',
                          onChanged: (value) {
                            final newHsv =
                                hsvColor.value.withValue(value / 100);
                            hsvColor.value = newHsv;
                            updateFromColor(newHsv.toColor());
                          },
                          gradientBuilder: (width) => LinearGradient(
                            colors: [
                              Colors.black,
                              HSVColor.fromAHSV(1, hsvColor.value.hue,
                                      hsvColor.value.saturation, 1)
                                  .toColor(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _HSVASlider(
                          label: 'A',
                          value: alphaValue.value * 100,
                          min: 0,
                          max: 100,
                          suffix: '%',
                          onChanged: (value) {
                            alphaValue.value = value / 100;
                            updateFromColor(selectedColor.value
                                .withValues(alpha: value / 100));
                          },
                          gradientBuilder: (width) {
                            final baseColor = selectedColor.value;
                            return LinearGradient(
                              colors: [
                                baseColor.withValues(alpha: 0),
                                baseColor.withValues(alpha: 1),
                              ],
                            );
                          },
                          showCheckerboard: true,
                        ),
                        const SizedBox(height: 24),

                        // Hex Input
                        Text(
                          AppLocalizations.of(context)!.hexCode,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: hexController,
                          decoration: InputDecoration(
                            prefixText: '#',
                            hintText: 'RRGGBB',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9A-Fa-f]')),
                            LengthLimitingTextInputFormatter(6),
                            _UpperCaseTextFormatter(),
                          ],
                          onChanged: (value) {
                            if (value.length == 6) {
                              try {
                                final color =
                                    Color(int.parse('FF$value', radix: 16));
                                updateFromColor(color);
                              } catch (e) {
                                // Invalid hex, ignore
                              }
                            }
                          },
                        ),
                        const SizedBox(height: 24),

                        // RGB Inputs
                        Text(
                          AppLocalizations.of(context)!.rgbValues,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildRGBField(
                                context,
                                'R',
                                redController,
                                (value) {
                                  final r = int.tryParse(value) ??
                                      selectedColor.value.red;
                                  updateFromColor(Color.fromARGB(
                                    (alphaValue.value * 255).round(),
                                    r.clamp(0, 255),
                                    selectedColor.value.green,
                                    selectedColor.value.blue,
                                  ));
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildRGBField(
                                context,
                                'G',
                                greenController,
                                (value) {
                                  final g = int.tryParse(value) ??
                                      selectedColor.value.green;
                                  updateFromColor(Color.fromARGB(
                                    (alphaValue.value * 255).round(),
                                    selectedColor.value.red,
                                    g.clamp(0, 255),
                                    selectedColor.value.blue,
                                  ));
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildRGBField(
                                context,
                                'B',
                                blueController,
                                (value) {
                                  final b = int.tryParse(value) ??
                                      selectedColor.value.blue;
                                  updateFromColor(Color.fromARGB(
                                    (alphaValue.value * 255).round(),
                                    selectedColor.value.red,
                                    selectedColor.value.green,
                                    b.clamp(0, 255),
                                  ));
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Presets
                        Text(
                          AppLocalizations.of(context)!.presets,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: presetColors.map((color) {
                            final isSelected = color.toARGB32() ==
                                selectedColor.value.toARGB32();
                            return GestureDetector(
                              onTap: () => updateFromColor(color),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey[400]!,
                                    width: isSelected ? 3 : 1.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? Icon(
                                        Icons.check,
                                        color: color.computeLuminance() > 0.5
                                            ? Colors.black
                                            : Colors.white,
                                        size: 24,
                                      )
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 80), // Space for fixed buttons
                      ],
                    ),
                  ),
                ),

                // Fixed action buttons
                GlassSurface(
                  padding: const EdgeInsets.all(Space.xl),
                  borderRadius: BorderRadius.zero,
                  showEdgeHighlight: false,
                  fallbackColor: Theme.of(context).scaffoldBackgroundColor,
                  child: Row(
                    children: [
                      Expanded(
                        child: GlassButton(
                          onPressed: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(12),
                          child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassButton(
                          prominent: true,
                          borderRadius: BorderRadius.circular(12),
                          onPressed: () async {
                            await onColorChanged(selectedColor.value);
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text(AppLocalizations.of(context)!.apply),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewSection(
      BuildContext context, Color current, Color previous) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.previous,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: previous,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!, width: 2),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.currentColorLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: current,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!, width: 2),
                ),
                child: Center(
                  child: Icon(
                    Icons.check,
                    color: current.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContrastIndicator(BuildContext context, Color color) {
    final luminance = color.computeLuminance();
    final textColor = luminance > 0.5 ? Colors.black : Colors.white;
    final ratio = contrastRatio(color, textColor);
    final passesAA = ratio >= 4.5;
    final passesAAA = ratio >= 7.0;

    return Container(
      height: 56, // Fixed height
      padding:
          const EdgeInsets.symmetric(horizontal: Space.md, vertical: Space.sm),
      decoration: BoxDecoration(
        color: passesAA
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: passesAA ? Colors.green : Colors.orange,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            passesAA ? Icons.check_circle : Icons.warning,
            color: passesAA ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Contrast: ${ratio.toStringAsFixed(1)}:1',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: passesAA ? Colors.green : Colors.orange,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  passesAAA
                      ? 'Excellent (AAA)'
                      : passesAA
                          ? 'Good (AA)'
                          : 'Auto-adjusted for readability',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        height: 1.2,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRGBField(
    BuildContext context,
    String label,
    TextEditingController controller,
    Function(String) onChanged,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(3),
      ],
      onChanged: onChanged,
    );
  }

  String _colorToHex(Color color) {
    return color.toARGB32().toRadixString(16).substring(2, 8).toUpperCase();
  }
}

class HuePicker extends StatelessWidget {
  final double hue;
  final ValueChanged<double> onChanged;

  const HuePicker({
    super.key,
    required this.hue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final hueValue =
            (localPosition.dx / box.size.width * 360).clamp(0.0, 360.0);
        onChanged(hueValue);
      },
      onTapDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.localPosition);
        final hueValue =
            (localPosition.dx / box.size.width * 360).clamp(0.0, 360.0);
        onChanged(hueValue);
      },
      child: Container(
        height: 40,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFFF0000),
              Color(0xFFFFFF00),
              Color(0xFF00FF00),
              Color(0xFF00FFFF),
              Color(0xFF0000FF),
              Color(0xFFFF00FF),
              Color(0xFFFF0000),
            ],
          ),
        ),
        // CustomPaint has no child, so it sizes itself to `size` (default
        // Size.zero) constrained by whatever it's given. Container(height: 40)
        // only fixes height, leaving width loose, so without this SizedBox
        // the paint area collapsed to zero width -- the rainbow track never
        // rendered, and only the thumb (drawn via canvas overflow past the
        // zero-width box) was visible, floating with nothing behind it.
        child: SizedBox.expand(
          child: CustomPaint(
            painter: _HueThumbPainter(hue: hue),
          ),
        ),
      ),
    );
  }
}

class _HueThumbPainter extends CustomPainter {
  final double hue;

  _HueThumbPainter({required this.hue});

  @override
  void paint(Canvas canvas, Size size) {
    final position = hue / 360 * size.width;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(
      Offset(position, size.height / 2),
      15,
      paint,
    );

    final fillPaint = Paint()
      ..color = HSVColor.fromAHSV(1, hue, 1, 1).toColor()
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(position, size.height / 2),
      12,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HueThumbPainter oldDelegate) {
    return oldDelegate.hue != hue;
  }
}

class SaturationBrightnessPicker extends StatelessWidget {
  final double hue;
  final double saturation;
  final double value;
  final Function(double, double) onChanged;

  const SaturationBrightnessPicker({
    super.key,
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final sat = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
        final val = (1 - localPosition.dy / box.size.height).clamp(0.0, 1.0);
        onChanged(sat, val);
      },
      onTapDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.localPosition);
        final sat = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
        final val = (1 - localPosition.dy / box.size.height).clamp(0.0, 1.0);
        onChanged(sat, val);
      },
      child: AspectRatio(
        aspectRatio: 1.5,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[400]!, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CustomPaint(
              painter: _SaturationBrightnessPainter(
                hue: hue,
                saturation: saturation,
                value: value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SaturationBrightnessPainter extends CustomPainter {
  final double hue;
  final double saturation;
  final double value;

  _SaturationBrightnessPainter({
    required this.hue,
    required this.saturation,
    required this.value,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the gradient
    final baseColor = HSVColor.fromAHSV(1, hue, 1, 1).toColor();

    // Horizontal gradient (saturation)
    final satGradient = LinearGradient(
      colors: [Colors.white, baseColor],
    );
    final satRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(
        satRect, Paint()..shader = satGradient.createShader(satRect));

    // Vertical gradient (brightness)
    const brightGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Colors.black],
    );
    canvas.drawRect(
        satRect, Paint()..shader = brightGradient.createShader(satRect));

    // Draw crosshair
    final x = saturation * size.width;
    final y = (1 - value) * size.height;

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset(x, y), 12, paint);
    canvas.drawLine(Offset(x, y - 20), Offset(x, y - 8), paint);
    canvas.drawLine(Offset(x, y + 8), Offset(x, y + 20), paint);
    canvas.drawLine(Offset(x - 20, y), Offset(x - 8, y), paint);
    canvas.drawLine(Offset(x + 8, y), Offset(x + 20, y), paint);
  }

  @override
  bool shouldRepaint(covariant _SaturationBrightnessPainter oldDelegate) {
    return oldDelegate.hue != hue ||
        oldDelegate.saturation != saturation ||
        oldDelegate.value != value;
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class _HSVASlider extends HookWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ValueChanged<double> onChanged;
  final LinearGradient Function(double width) gradientBuilder;
  final bool showCheckerboard;

  const _HSVASlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.onChanged,
    required this.gradientBuilder,
    this.showCheckerboard = false,
  });

  @override
  Widget build(BuildContext context) {
    final sliderValue = useState(value);

    // Sync external changes
    useEffect(() {
      sliderValue.value = value;
      return null;
    }, [value]);

    return Semantics(
      label: '$label slider, current value ${value.round()}$suffix',
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44, // Touch target
                  // Builder so the gesture handlers get a context whose
                  // RenderBox *is* the track. Previously they used the whole
                  // row's context and subtracted hardcoded label/badge widths.
                  child: Builder(
                    builder: (trackContext) => GestureDetector(
                      onPanStart: (details) {
                        _updateValue(details.localPosition.dx, trackContext);
                      },
                      onPanUpdate: (details) {
                        _updateValue(details.localPosition.dx, trackContext);
                      },
                      onTapDown: (details) {
                        _updateValue(details.localPosition.dx, trackContext);
                      },
                      child: Container(
                        height: 36,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.grey[400]!,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          // One LayoutBuilder for the whole stack so the thumb is
                          // positioned from the track's *actual* width. It used to
                          // derive that from MediaQuery screen width minus a
                          // hardcoded 108, which only matched one device and one
                          // set of paddings -- and was wrong in RTL, where the
                          // track doesn't start at the screen edge.
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const thumbSize = 28.0;
                              final trackWidth = constraints.maxWidth;
                              final fraction =
                                  ((sliderValue.value - min) / (max - min))
                                      .clamp(0.0, 1.0);
                              // Inset so the thumb stays fully on the track at
                              // both extremes instead of hanging off the ends.
                              final left = fraction * (trackWidth - thumbSize);

                              return Stack(
                                children: [
                                  // Checkerboard background for alpha
                                  if (showCheckerboard)
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _CheckerboardPainter(),
                                      ),
                                    ),
                                  // Gradient
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: gradientBuilder(trackWidth),
                                      ),
                                    ),
                                  ),
                                  // Thumb
                                  PositionedDirectional(
                                    start: left,
                                    top: 4,
                                    child: Container(
                                      width: thumbSize,
                                      height: thumbSize,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GlassSurface.tinted(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(
                      horizontal: Space.sm, vertical: Space.xs),
                  child: Text(
                    '${value.round()}$suffix',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateValue(double dx, BuildContext context) {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final width = renderBox.size.width;
    if (width <= 0) return;

    var fraction = (dx / width).clamp(0.0, 1.0);
    // The track is mirrored in RTL (the thumb is placed with
    // PositionedDirectional), so dragging must be mirrored to match.
    if (Directionality.of(context) == TextDirection.rtl) {
      fraction = 1.0 - fraction;
    }

    onChanged((min + fraction * (max - min)).clamp(min, max));
  }
}

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const squareSize = 8.0;
    final paint1 = Paint()..color = Colors.white;
    final paint2 = Paint()..color = Colors.grey[300]!;

    for (var y = 0.0; y < size.height; y += squareSize) {
      for (var x = 0.0; x < size.width; x += squareSize) {
        final isEven =
            ((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0;
        canvas.drawRect(
          Rect.fromLTWH(x, y, squareSize, squareSize),
          isEven ? paint1 : paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
