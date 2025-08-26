import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class TemperatureScreen extends StatefulWidget {
  const TemperatureScreen({super.key});

  @override
  State<TemperatureScreen> createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> {
  final _extruderController = TextEditingController(text: '0');
  final _bedController = TextEditingController(text: '0');
  final _extruderFocus = FocusNode();
  final _bedFocus = FocusNode();

  @override
  void dispose() {
    _extruderController.dispose();
    _bedController.dispose();
    _extruderFocus.dispose();
    _bedFocus.dispose();
    super.dispose();
  }

  void _clearFocus() {
    _extruderFocus.unfocus();
    _bedFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Temperature',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Area Grafico Temperature
                  Card(
                    child: Container(
                      height: 300,
                      padding: const EdgeInsets.all(16.0),
                      child: const Center(
                        child: Text('Grafico Temperature (da implementare)'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Controlli Estrusore
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estrusore',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Temperatura Target',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _extruderController,
                                        focusNode: _extruderFocus,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          hintText: '0',
                                          suffixText: '°C',
                                          suffixStyle: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        style: const TextStyle(fontSize: 18),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Consumer<ThemeProvider>(
                                  builder: (context, themeProvider, _) => ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: themeProvider.primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      _clearFocus();
                                      // TODO: Implementare l'invio della temperatura
                                    },
                                    child: const Text('Imposta'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _presetButton('PLA', 200, isExtruder: true),
                              _presetButton('PETG', 230, isExtruder: true),
                              _presetButton('ABS', 240, isExtruder: true),
                              _presetButton('Off', 0, isExtruder: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Controlli Piano Riscaldato
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Piano Riscaldato',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Temperatura Target',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _bedController,
                                        focusNode: _bedFocus,
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.zero,
                                          hintText: '0',
                                          suffixText: '°C',
                                          suffixStyle: TextStyle(
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        style: const TextStyle(fontSize: 18),
                                        keyboardType: TextInputType.number,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Consumer<ThemeProvider>(
                                  builder: (context, themeProvider, _) => ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: themeProvider.primaryColor,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () {
                                      _clearFocus();
                                      // TODO: Implementare l'invio della temperatura
                                    },
                                    child: const Text('Imposta'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _presetButton('PLA', 60, isExtruder: false),
                              _presetButton('PETG', 80, isExtruder: false),
                              _presetButton('ABS', 100, isExtruder: false),
                              _presetButton('Off', 0, isExtruder: false),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _presetButton(String label, int temp, {bool isExtruder = false}) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        return Container(
          width: 80,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                if (isExtruder) {
                  _extruderController.text = temp.toString();
                } else {
                  _bedController.text = temp.toString();
                }
                _clearFocus();
                // TODO: Implementare l'invio della temperatura
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: themeProvider.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${temp}°C',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
