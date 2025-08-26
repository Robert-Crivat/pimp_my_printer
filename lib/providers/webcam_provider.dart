import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/webcam_overlay.dart';

class WebcamProvider with ChangeNotifier {
  bool _showDuringMovement = true;
  WebcamSize _defaultSize = WebcamSize.small;
  bool _isVisible = false;

  bool get showDuringMovement => _showDuringMovement;
  WebcamSize get defaultSize => _defaultSize;
  bool get isVisible => _isVisible;

  WebcamProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _showDuringMovement = prefs.getBool('webcam_show_during_movement') ?? true;
    _defaultSize = WebcamSize.values[prefs.getInt('webcam_default_size') ?? 0];
    notifyListeners();
  }

  Future<void> setShowDuringMovement(bool value) async {
    _showDuringMovement = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('webcam_show_during_movement', value);
    notifyListeners();
  }

  Future<void> setDefaultSize(WebcamSize size) async {
    _defaultSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('webcam_default_size', size.index);
    notifyListeners();
  }

  void showWebcam() {
    _isVisible = true;
    notifyListeners();
  }

  void hideWebcam() {
    _isVisible = false;
    notifyListeners();
  }

  void toggleWebcam() {
    _isVisible = !_isVisible;
    notifyListeners();
  }
}
