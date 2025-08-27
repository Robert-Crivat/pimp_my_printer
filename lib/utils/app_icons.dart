import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class AppIcons {
  static Widget home({double? size, Color? color}) => Icon(
    Icons.home,
    size: size ?? 24,
    color: color ?? Colors.white,
  );

  static Widget dashboard({double? size, Color? color}) => Icon(
    Icons.dashboard,
    size: size ?? 24,
    color: color ?? Colors.white,
  );

  static Widget thermometer({double? size, Color? color}) => Icon(
    Icons.thermostat,
    size: size ?? 24,
    color: color ?? Colors.white,
  );

  static Widget moreVert({double? size, Color? color}) => Icon(
    Icons.more_vert,
    size: size ?? 24,
    color: color ?? Colors.white,
  );

  static Widget download({double? size, Color? color}) => Icon(
    Icons.download,
    size: size ?? 24,
    color: color ?? Colors.white,
  );

  static Widget webcam({double? size, Color? color}) => Icon(
    Icons.videocam,
    size: size ?? 24,
    color: color ?? Colors.white,
  );

  static Widget macros({double? size, Color? color}) => Icon(
    Icons.code,
    size: size ?? 24,
    color: color ?? Colors.white,
  );

  static Widget printer({double? size, Color? color}) => SvgPicture.asset(
    'lib/assets/3d-printer-printing-svgrepo-com.svg',
    width: size ?? 24,
    height: size ?? 24,
    colorFilter: ColorFilter.mode(color ?? Colors.white, BlendMode.srcIn),
  );

  static Widget slicer({double? size, Color? color}) => Icon(
    Icons.view_in_ar,
    size: size ?? 24,
    color: color ?? Colors.white,
  );
}
