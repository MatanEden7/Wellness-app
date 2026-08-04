import 'package:flutter/material.dart';

/// WCAG 2.x relative-luminance contrast ratio between two colors, from 1:1
/// (identical) to 21:1 (pure black on white). 4.5:1 is the AA bar for normal
/// text; 3:1 for large text/icons.
double contrastRatio(Color a, Color b) {
  final lumA = a.computeLuminance();
  final lumB = b.computeLuminance();
  final lighter = lumA > lumB ? lumA : lumB;
  final darker = lumA > lumB ? lumB : lumA;
  return (lighter + 0.05) / (darker + 0.05);
}
