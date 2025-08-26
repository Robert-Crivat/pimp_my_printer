import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/webcam_provider.dart';
import '../widgets/webcam_overlay.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, WebcamProvider>(
      builder: (context, themeProvider, webcamProvider, child) {
        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Torna indietro',
                    ),
                    const Spacer(),
                  ],
                ),
                Text(
                  'Impostazioni',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personalizzazione',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        // Nome Stampante
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Nome Stampante',
                            prefixIcon: Icon(Icons.print),
                          ),
                          controller: TextEditingController(
                            text: themeProvider.printerName,
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              themeProvider.setPrinterName(value);
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        // Tema Scuro
                        SwitchListTile(
                          title: const Text('Tema Scuro'),
                          subtitle: Text(
                            themeProvider.isDarkMode ? 'Attivo' : 'Disattivo',
                          ),
                          value: themeProvider.isDarkMode,
                          onChanged: (bool value) {
                            themeProvider.setDarkMode(value);
                          },
                        ),
                        const SizedBox(height: 16),
                        // Colore Primario
                        ListTile(
                          title: const Text('Colore Primario'),
                          trailing: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: themeProvider.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                          ),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Scegli un colore'),
                                  content: SingleChildScrollView(
                                    child: ColorPicker(
                                      pickerColor: themeProvider.primaryColor,
                                      onColorChanged: (Color color) {
                                        themeProvider.setPrimaryColor(color);
                                      },
                                      labelTypes: const [],
                                      pickerAreaHeightPercent: 0.8,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Impostazioni Webcam',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        // Mostra durante i movimenti
                        SwitchListTile(
                          title: const Text('Mostra durante i movimenti'),
                          subtitle: const Text(
                            'La webcam apparirà automaticamente durante i movimenti della stampante'
                          ),
                          value: webcamProvider.showDuringMovement,
                          onChanged: (value) {
                            webcamProvider.setShowDuringMovement(value);
                          },
                        ),
                        const SizedBox(height: 16),
                        // Dimensione predefinita
                        ListTile(
                          title: const Text('Dimensione predefinita'),
                          trailing: DropdownButton<WebcamSize>(
                            value: webcamProvider.defaultSize,
                            items: [
                              const DropdownMenuItem(
                                value: WebcamSize.small,
                                child: Text('Piccola'),
                              ),
                              const DropdownMenuItem(
                                value: WebcamSize.medium,
                                child: Text('Media'),
                              ),
                              const DropdownMenuItem(
                                value: WebcamSize.large,
                                child: Text('Grande'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                webcamProvider.setDefaultSize(value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Test webcam
                        Center(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeProvider.primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.videocam),
                            label: const Text('Test webcam'),
                            onPressed: () {
                              webcamProvider.showWebcam();
                              Future.delayed(const Duration(seconds: 5), () {
                                webcamProvider.hideWebcam();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              ),
            ),
          ),
        );
      },
    );
  }
}
