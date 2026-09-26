// SVG path verisinde komut harfleri boşluk gerektirmez.
// ignore_for_file: missing_whitespace_between_adjacent_strings

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Tasarımdaki çizgi ikonlar. Her ikon SVG path verisinden çizilir; böylece
/// HTML referansıyla birebir aynı görünür.
@immutable
class AppIconData {
  const AppIconData(
    this.paths, {
    this.viewBox = 24,
    this.strokeWidth = 2,
    this.filledDots = const [],
    this.fill = false,
  });

  /// SVG `d` değerleri.
  final List<String> paths;
  final double viewBox;
  final double strokeWidth;

  /// Dolu küçük daireler: (x, y, r).
  final List<(double, double, double)> filledDots;

  /// true ise path'ler çizgi yerine dolgu ile boyanır.
  final bool fill;
}

const _gearPath =
    'M19.4 13.5a7.7 7.7 0 0 0 0-3l2-1.6-2-3.4-2.4 1a7.6 7.6 0 0 0-2.6-1.5'
    'L14 2.5h-4l-.4 2.5A7.6 7.6 0 0 0 7 6.5l-2.4-1-2 3.4 2 1.6a7.7 7.7 0 '
    '0 0 0 3l-2 1.6 2 3.4 2.4-1a7.6 7.6 0 0 0 2.6 1.5l.4 2.5h4l.4-2.5a7.6 '
    '7.6 0 0 0 2.6-1.5l2.4 1 2-3.4z';
const _sunRays =
    'M12 2.5v2M12 19.5v2M4.3 4.3l1.4 1.4M18.3 18.3l1.4 1.4M2.5 12h2'
    'M19.5 12h2M4.3 19.7l1.4-1.4M18.3 5.7l1.4-1.4';
const _globeMeridian =
    'M12 3c2.4 2.6 3.6 5.6 3.6 9s-1.2 6.4-3.6 9c-2.4-2.6-3.6-5.6-3.6-9'
    'S9.6 5.6 12 3z';
const _heartPath =
    'M12 20s-7.5-4.6-7.5-10.2A4.3 4.3 0 0 1 12 7.3a4.3 4.3 0 0 1 7.5 2.5'
    'C19.5 15.4 12 20 12 20z';

const _flamePath =
    'M12 21a6 6 0 0 0 6-6c0-4-3-6-4-9-1 2-2 3-3.5 3.5'
    'C9 10 6 12 6 15a6 6 0 0 0 6 6z';

abstract final class AppIcons {
  static const settings = AppIconData([
    'M12 8.5a3.5 3.5 0 1 0 0 7 3.5 3.5 0 1 0 0-7z',
    _gearPath,
  ]);
  static const bell = AppIconData([
    'M6 16v-5a6 6 0 0 1 12 0v5l1.5 2h-15z',
    'M10 20.5a2 2 0 0 0 4 0',
  ]);
  static const arrowUp = AppIconData([
    'M12 19V5M6 11l6-6 6 6',
  ], strokeWidth: 2.4);
  static const arrowDown = AppIconData([
    'M12 5v14M6 13l6 6 6-6',
  ], strokeWidth: 2.4);
  static const arrowRight = AppIconData([
    'M5 12h14M13 6l6 6-6 6',
  ], strokeWidth: 2.4);
  static const moon = AppIconData([
    'M20 14.5A8 8 0 0 1 9.5 4 8.5 8.5 0 1 0 20 14.5z',
  ]);
  static const moonNav = AppIconData([
    'M20 14.5A8 8 0 0 1 9.5 4 8.5 8.5 0 1 0 20 14.5z',
  ], strokeWidth: 2.2);
  static const back = AppIconData(['M15 5l-7 7 7 7'], strokeWidth: 2.2);
  static const chevronRight = AppIconData(['M9 5l7 7-7 7'], strokeWidth: 2.2);
  static const close = AppIconData(['M6 6l12 12M18 6L6 18'], strokeWidth: 2.2);
  static const minus = AppIconData(['M6 12h12'], strokeWidth: 2.4);
  static const plus = AppIconData(['M6 12h12M12 6v12'], strokeWidth: 2.4);
  static const check = AppIconData(['M5 12.5l4.5 4.5L19 7.5'], strokeWidth: 3);
  static const checkBold = AppIconData([
    'M5 12.5l4.5 4.5L19 7.5',
  ], strokeWidth: 2.4);
  static const home = AppIconData([
    'M4 11l8-6.5 8 6.5V20a1 1 0 0 1-1 1h-4.5v-6h-5v6H5a1 1 0 0 1-1-1z',
  ]);
  static const bars = AppIconData([
    'M6 20V12M12 20V5M18 20v-6',
  ], strokeWidth: 2.2);
  static const gauge = AppIconData([
    'M3.5 17A9 9 0 0 1 20.5 17',
    'M12 17l-4.5-7.5M12 17l4-7.8',
  ]);
  static const clock = AppIconData([
    'M12 3.5a8.5 8.5 0 1 0 0 17 8.5 8.5 0 1 0 0-17z',
    'M12 7.5V12l3 2',
  ]);
  static const target = AppIconData([
    'M12 3a9 9 0 1 0 0 18 9 9 0 1 0 0-18z',
    'M12 7.5a4.5 4.5 0 1 0 0 9 4.5 4.5 0 1 0 0-9z',
  ]);
  static const sun = AppIconData([
    'M12 8a4 4 0 1 0 0 8 4 4 0 1 0 0-8z',
    _sunRays,
  ]);
  static const globe = AppIconData([
    'M12 3a9 9 0 1 0 0 18 9 9 0 1 0 0-18z',
    'M3 12h18',
    _globeMeridian,
  ]);
  static const trash = AppIconData([
    'M4 7h16M10 11v6M14 11v6',
    'M6 7l1 12a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-12M9 7V4h6v3',
  ]);
  static const sparkle = AppIconData([
    'M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z',
  ]);
  static const grid = AppIconData([
    'M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z',
  ]);
  static const heart = AppIconData([_heartPath]);
  static const cloudRain = AppIconData([
    'M7 14.5a4 4 0 0 1-.6-8 5.5 5.5 0 0 1 10.6 1.5 3.5 3.5 0 0 1 0 6.5z',
    'M8.5 17.5l-1 2.5M12.5 17.5l-1 2.5M16.5 17.5l-1 2.5',
  ]);
  static const wave = AppIconData([
    'M3 12c1.5-3.5 3-3.5 4.5 0s3 3.5 4.5 0 3-3.5 4.5 0 3 3.5 4.5 0',
  ]);
  static const wind = AppIconData([
    'M3 9h11a3 3 0 1 0-3-3',
    'M3 15h14a3 3 0 1 1-3 3',
  ]);
  static const layers = AppIconData(['M12 4l9 5-9 5-9-5z', 'M3 14l9 5 9-5']);
  static const play = AppIconData(['M8 5.5v13l11-6.5z'], fill: true);
  static const stop = AppIconData(['M7 7h10v10H7z'], fill: true);
  static const speaker = AppIconData([
    'M4 9.5h3.5L12 6v12l-4.5-3.5H4z',
    'M15.5 9a4 4 0 0 1 0 6M18 6.5a7.5 7.5 0 0 1 0 11',
  ]);
  static const breath = AppIconData([
    'M12 8a4 4 0 1 0 0 8 4 4 0 1 0 0-8z',
    'M12 3a9 9 0 1 0 0 18 9 9 0 1 0 0-18z',
  ]);
  static const trophy = AppIconData([
    'M8 4h8v5a4 4 0 0 1-8 0z',
    'M8 6H5a3 3 0 0 0 3 4M16 6h3a3 3 0 0 1-3 4',
    'M12 13v4M8.5 20h7M10 17h4',
  ]);
  static const flame = AppIconData([_flamePath]);
  static const pen = AppIconData(['M4 20h4L19 9l-4-4L4 16z', 'M13.5 6.5l4 4']);
  static const lock = AppIconData([
    'M7 11V8a5 5 0 0 1 10 0v3',
    'M5 11h14v10H5z',
  ]);

  // Halka uç rozetleri (12 birimlik kutu).
  static const badgeMoon = AppIconData(
    ['M10 7.4A4.3 4.3 0 0 1 4.6 2 4.4 4.4 0 1 0 10 7.4z'],
    viewBox: 12,
    strokeWidth: 1.5,
  );
  static const badgeEye = AppIconData(
    ['M1 6s1.9-3.4 5-3.4S11 6 11 6 9.1 9.4 6 9.4 1 6 1 6z'],
    viewBox: 12,
    strokeWidth: 1.4,
    filledDots: [(6, 6, 1.4)],
  );
  static const badgeWave = AppIconData(
    ['M1 7.5c1.2-2.2 2.6-2.2 3.8 0s2.6 2.2 3.8 0c.6-1 1.2-1.5 1.9-1.5'],
    viewBox: 12,
    strokeWidth: 1.5,
  );
}

/// [AppIconData]'yı verilen boyut ve renkte çizer.
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {required this.color, this.size = 20, super.key});

  final AppIconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: AppIconPainter(icon, color)),
      ),
    );
  }
}

class AppIconPainter extends CustomPainter {
  AppIconPainter(this.icon, this.color);

  final AppIconData icon;
  final Color color;

  static final _cache = <String, Path>{};

  static Path pathFor(String d) =>
      _cache.putIfAbsent(d, () => SvgPathParser(d).parse());

  /// Tuval başka bir yerde konumlanmışken ikonu çizmek için.
  static void paintIcon(
    Canvas canvas,
    AppIconData icon,
    Color color,
    Rect rect,
  ) {
    canvas
      ..save()
      ..translate(rect.left, rect.top)
      ..scale(rect.width / icon.viewBox, rect.height / icon.viewBox);
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = icon.fill ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = icon.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final d in icon.paths) {
      canvas.drawPath(pathFor(d), paint);
    }
    final dot = Paint()..color = color;
    for (final (x, y, r) in icon.filledDots) {
      canvas.drawCircle(Offset(x, y), r, dot);
    }
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) =>
      paintIcon(canvas, icon, color, Offset.zero & size);

  @override
  bool shouldRepaint(AppIconPainter oldDelegate) =>
      oldDelegate.icon != icon || oldDelegate.color != color;
}

/// SVG path verisini (M L H V C S Q A Z, göreli ve mutlak) [Path]'e çevirir.
class SvgPathParser {
  SvgPathParser(this.source);

  final String source;
  int _i = 0;

  static final _number = RegExp(r'[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?');

  Path parse() {
    final path = Path();
    var cx = 0.0;
    var cy = 0.0;
    var sx = 0.0;
    var sy = 0.0;
    double? lastCtrlX;
    double? lastCtrlY;
    String? cmd;

    while (true) {
      _skipSeparators();
      if (_i >= source.length) break;
      final ch = source[_i];
      if (RegExp('[a-zA-Z]').hasMatch(ch)) {
        cmd = ch;
        _i++;
      } else if (cmd == null) {
        throw FormatException('SVG path komutla başlamalı', source, _i);
      }
      final c = cmd;
      final rel = c == c.toLowerCase();
      final ox = rel ? cx : 0.0;
      final oy = rel ? cy : 0.0;
      switch (c.toUpperCase()) {
        case 'M':
          cx = ox + _num();
          cy = oy + _num();
          path.moveTo(cx, cy);
          sx = cx;
          sy = cy;
          // Ardışık koordinatlar lineto sayılır.
          cmd = rel ? 'l' : 'L';
          lastCtrlX = null;
        case 'L':
          cx = ox + _num();
          cy = oy + _num();
          path.lineTo(cx, cy);
          lastCtrlX = null;
        case 'H':
          cx = ox + _num();
          path.lineTo(cx, cy);
          lastCtrlX = null;
        case 'V':
          cy = oy + _num();
          path.lineTo(cx, cy);
          lastCtrlX = null;
        case 'C':
          final x1 = ox + _num();
          final y1 = oy + _num();
          final x2 = ox + _num();
          final y2 = oy + _num();
          cx = ox + _num();
          cy = oy + _num();
          path.cubicTo(x1, y1, x2, y2, cx, cy);
          lastCtrlX = x2;
          lastCtrlY = y2;
        case 'S':
          final x1 = lastCtrlX == null ? cx : 2 * cx - lastCtrlX;
          final y1 = lastCtrlY == null ? cy : 2 * cy - lastCtrlY;
          final x2 = ox + _num();
          final y2 = oy + _num();
          cx = ox + _num();
          cy = oy + _num();
          path.cubicTo(x1, y1, x2, y2, cx, cy);
          lastCtrlX = x2;
          lastCtrlY = y2;
        case 'Q':
          final x1 = ox + _num();
          final y1 = oy + _num();
          cx = ox + _num();
          cy = oy + _num();
          path.quadraticBezierTo(x1, y1, cx, cy);
          lastCtrlX = null;
        case 'A':
          final rx = _num();
          final ry = _num();
          final rotation = _num();
          final large = _flag();
          final sweep = _flag();
          cx = ox + _num();
          cy = oy + _num();
          path.arcToPoint(
            Offset(cx, cy),
            radius: Radius.elliptical(rx, ry),
            rotation: rotation * math.pi / 180,
            largeArc: large,
            clockwise: sweep,
          );
          lastCtrlX = null;
        case 'Z':
          path.close();
          cx = sx;
          cy = sy;
          lastCtrlX = null;
          cmd = null;
        default:
          throw FormatException('Desteklenmeyen komut $c', source, _i);
      }
    }
    return path;
  }

  void _skipSeparators() {
    while (_i < source.length &&
        (source[_i] == ' ' || source[_i] == ',' || source[_i] == '\n')) {
      _i++;
    }
  }

  double _num() {
    _skipSeparators();
    final match = _number.matchAsPrefix(source, _i);
    if (match == null) {
      throw FormatException('Sayı bekleniyordu', source, _i);
    }
    _i = match.end;
    return double.parse(match[0]!);
  }

  bool _flag() {
    _skipSeparators();
    final value = source[_i] == '1';
    _i++;
    return value;
  }
}
