import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/webcam_provider.dart';
import '../providers/theme_provider.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Controlli',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Controlli Movimento XY
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text('Movimento XY'),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildDirectionButton(Icons.arrow_upward, 'Y+'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildDirectionButton(Icons.arrow_back, 'X-'),
                              const SizedBox(width: 50),
                              _buildDirectionButton(Icons.arrow_forward, 'X+'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildDirectionButton(Icons.arrow_downward, 'Y-'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Controlli Movimento Z
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text('Movimento Z'),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildDirectionButton(Icons.arrow_upward, 'Z+'),
                              const SizedBox(width: 16),
                              _buildDirectionButton(Icons.arrow_downward, 'Z-'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Controlli Estrusore
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text('Estrusore'),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: () {},
                                child: const Text('Estrudi'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {},
                                child: const Text('Ritrai'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Controlli Velocità e Distanza
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Impostazioni Movimento'),
                          const SizedBox(height: 16),
                          const Text('Distanza per Movimento:'),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildDistanceButton('0.1'),
                              _buildDistanceButton('1'),
                              _buildDistanceButton('10'),
                              _buildDistanceButton('100'),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Velocità:'),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildSpeedButton('Lento'),
                              _buildSpeedButton('Normale'),
                              _buildSpeedButton('Veloce'),
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

  Widget _buildDirectionButton(IconData icon, String tooltip) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Tooltip(
      message: tooltip,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeProvider.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16),
        ),
        onPressed: () {
          final webcamProvider = Provider.of<WebcamProvider>(context, listen: false);
          if (webcamProvider.showDuringMovement) {
            webcamProvider.showWebcam();
          }
          // TODO: Implementare il movimento
          
          // Nascondi la webcam dopo 5 secondi
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) {
              webcamProvider.hideWebcam();
            }
          });
        },
        child: Icon(icon),
      ),
    );
  }

  Widget _buildDistanceButton(String value) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: themeProvider.primaryColor,
        foregroundColor: Colors.white,
      ),
      onPressed: () {},
      child: Text('${value}mm'),
    );
  }

  Widget _buildSpeedButton(String speed) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: themeProvider.primaryColor,
        foregroundColor: Colors.white,
      ),
      onPressed: () {},
      child: Text(speed),
    );
  }
}
