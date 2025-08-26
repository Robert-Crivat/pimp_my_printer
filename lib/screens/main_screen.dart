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
  final Widget Function({double? size, Color? color}) selectedIcon;
  final String label;
  final String category;

  NavigationItem({
    required Widget Function({double? size, Color? color}) icon,
    required Widget Function({double? size, Color? color}) selectedIcon,
    required this.label,
    required this.category,
  })  : icon = icon,
        selectedIcon = selectedIcon;
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isMenuVisible = true;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const TemperatureScreen(),
    const ControlScreen(),
    const CameraScreen(),
    const FilesScreen(),
    const MacrosScreen(),
  ];

  final List<NavigationItem> _menuItems = [
    NavigationItem(
      icon: AppIcons.dashboard,
      selectedIcon: AppIcons.dashboard,
      label: 'Dashboard',
      category: 'main',
    ),
    NavigationItem(
      icon: AppIcons.thermometer,
      selectedIcon: AppIcons.thermometer,
      label: 'Tool',
      category: 'main',
    ),
    NavigationItem(
      icon: AppIcons.thermometer,
      selectedIcon: AppIcons.thermometer,
      label: 'Bed',
      category: 'main',
    ),
    NavigationItem(
      icon: AppIcons.home,
      selectedIcon: AppIcons.home,
      label: 'Controls',
      category: 'main',
    ),
    NavigationItem(
      icon: AppIcons.dashboard,
      selectedIcon: AppIcons.dashboard,
      label: 'Webcam',
      category: 'main',
    ),
    NavigationItem(
      icon: AppIcons.download,
      selectedIcon: AppIcons.download,
      label: 'G-Code Files',
      category: 'main',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Raggruppa gli elementi del menu per categoria
    Map<String, List<NavigationItem>> groupedItems = {};
    for (var item in _menuItems) {
      if (!groupedItems.containsKey(item.category)) {
        groupedItems[item.category] = [];
      }
      groupedItems[item.category]!.add(item);
    }

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: themeProvider.isDarkMode 
                ? const Color(0xFF1E1E1E) 
                : Colors.white,
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
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  size: 20,
                ),
                onPressed: () {
                  themeProvider.setDarkMode(!themeProvider.isDarkMode);
                },
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
          Row(
            children: [
              Container(
                width: 48,
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode ? const Color(0xFF252525) : Colors.grey[100],
                  border: Border(
                    right: BorderSide(
                      color: themeProvider.isDarkMode ? Colors.grey[850]! : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: _menuItems.length,
                        itemBuilder: (context, index) {
                          final item = _menuItems[index];
                          return Tooltip(
                            message: item.label,
                            preferBelow: false,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedIndex = index;
                                });
                              },
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(
                                      color: _selectedIndex == index
                                          ? themeProvider.primaryColor
                                          : Colors.transparent,
                                      width: 3,
                                    ),
                                  ),
                                  color: _selectedIndex == index
                                      ? (themeProvider.isDarkMode
                                          ? Colors.grey[850]
                                          : Colors.grey[200])
                                      : Colors.transparent,
                                ),
                                child: _selectedIndex == index
                                    ? item.selectedIcon(
                                        size: 20,
                                        color: themeProvider.primaryColor,
                                      )
                                    : item.icon(
                                        size: 20,
                                        color: themeProvider.isDarkMode
                                            ? Colors.white
                                            : Colors.grey[600],
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _screens[_selectedIndex],
              ),
            ],
          ),
          Consumer<WebcamProvider>(
            builder: (context, webcamProvider, _) {
              if (!webcamProvider.isVisible) return const SizedBox();
              
              return WebcamOverlay(
                size: webcamProvider.defaultSize,
                onSizeChange: () {
                  // Se la dimensione cambia in fullscreen, nascondiamo il menu
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