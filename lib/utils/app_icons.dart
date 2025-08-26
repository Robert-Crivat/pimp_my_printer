import 'package:flutter/material.dart';

class AppIcons {
  static Widget home({double? size, Color? color}) => Icon(
    Icons.home,
    size: size ?? 24,
    color: Colors.white,
  );

  static Widget dashboard({double? size, Color? color}) => Icon(
    Icons.dashboard,
    size: size ?? 24,
    color: Colors.white,
  );

  static Widget thermometer({double? size, Color? color}) => Icon(
    Icons.thermostat,
    size: size ?? 24,
    color: Colors.white,
  );

  static Widget moreVert({double? size, Color? color}) => Icon(
    Icons.more_vert,
    size: size ?? 24,
    color: Colors.white,
  );

  static Widget download({double? size, Color? color}) => Icon(
    Icons.download,
    size: size ?? 24,
    color: Colors.white,
  );

  static Widget printer({double? size, Color? color}) => Icon(
    Icons.print,
    size: size ?? 24,
    color: Colors.white,
  );
}
