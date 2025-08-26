import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/webcam_provider.dart';
import '../widgets/webcam_overlay.dart';
import '../utils/app_icons.dart';
import 'dashboard_screen.dart';
import 'temperature_screen.dart';
import 'control_screen.dart';
import 'camera_screen.dart';
import 'files_screen.dart';
import 'macros_screen.dart';
import 'settings_screen.dart';

//TODO : ROB svg : https://www.svgrepo.com/vectors/3d-printer/

class NavigationItem {
  final Widget Function({double? size, Color? color}) icon;
  final String label;
  final Widget screen;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.screen,
  });
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isMenuVisible = true;

  // Define navigation items and their corresponding screens together
  // to prevent mismatches and improve maintainability.
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: AppIcons.dashboard,
      label: 'Dashboard',
      screen: const DashboardScreen(),
    ),
    NavigationItem(
      icon: AppIcons.thermometer,
      label: 'Temperature',
      screen: const TemperatureScreen(),
    ),
    NavigationItem(
      icon: AppIcons.home,
      label: 'Controls',
      screen: const ControlScreen(),
    ),
    NavigationItem(
      icon: AppIcons.webcam, // Assuming a webcam icon exists
      label: 'Webcam',
      screen: const CameraScreen(),
    ),
    NavigationItem(
      icon: AppIcons.download,
      label: 'G-Code Files',
      screen: const FilesScreen(),
    ),
    NavigationItem(
      icon: AppIcons.macros, // Assuming a macros icon exists
      label: 'Macros',
      screen: const MacrosScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDarkMode = themeProvider.isDarkMode;
        final primaryColor = themeProvider.primaryColor;
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final iconColor = isDarkMode ? Colors.white : Colors.grey[600];
        final appBarColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
        final navRailColor = isDarkMode ? const Color(0xFF252525) : Colors.grey[100];
        final navRailBorderColor = isDarkMode ? Colors.grey[850]! : Colors.grey[300]!;
        final navItemSelectedColor = isDarkMode ? Colors.grey[850] : Colors.grey[200];

        return Scaffold(
          appBar: AppBar(
            backgroundColor: appBarColor,
            elevation: 1,
            leadingWidth: 200,
            leading: Row(
              children: [
                const SizedBox(width: 16),
                AppIcons.printer(size: 20),
                const SizedBox(width: 8),
                Text(
                  themeProvider.printerName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  size: 20,
                ),
                onPressed: () => themeProvider.setDarkMode(!isDarkMode),
              ),
              IconButton(
                icon: const Icon(Icons.settings, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Stack(
            children: [
              if (_isMenuVisible)
                Row(
                  children: [
                    Container(
                      width: 48,
                      decoration: BoxDecoration(
                        color: navRailColor,
                        border: Border(
                          right: BorderSide(color: navRailBorderColor, width: 1),
                        ),
                      ),
                      child: ListView.builder(
                        itemCount: _navigationItems.length,
                        itemBuilder: (context, index) {
                          final item = _navigationItems[index];
                          final isSelected = _selectedIndex == index;
                          return Tooltip(
                            message: item.label,
                            preferBelow: false,
                            child: InkWell(
                              onTap: () => setState(() => _selectedIndex = index),
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: isSelected ? primaryColor : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                  color: isSelected ? navItemSelectedColor : Colors.transparent,
                                ),
                                child: item.icon(
                                  size: 20,
                                  color: isSelected ? primaryColor : (iconColor ?? Colors.white),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: _navigationItems[_selectedIndex].screen,
                    ),
                  ],
                )
              else
                // Show only the selected screen when the menu is not visible
                _navigationItems[_selectedIndex].screen,
              Consumer<WebcamProvider>(
                builder: (context, webcamProvider, _) {
                  if (!webcamProvider.isVisible) return const SizedBox.shrink();

                  return WebcamOverlay(
                    size: webcamProvider.defaultSize,
                    onSizeChange: () {
                      // Toggle menu visibility based on webcam size
                      setState(() {
                        _isMenuVisible = webcamProvider.defaultSize != WebcamSize.fullscreen;
                      });
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
