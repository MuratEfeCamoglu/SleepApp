import 'package:flutter/painting.dart';

/// Gölgeler (CLAUDE.md §5.6). `lift` yalnızca tooltip içindir.
abstract final class AppShadows {
  static const List<BoxShadow> none = [];

  static const lift = [
    BoxShadow(color: Color(0x1A2B211C), offset: Offset(0, 8), blurRadius: 24),
  ];
}
