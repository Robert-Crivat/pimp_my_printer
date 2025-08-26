import 'package:flutter/material.dart';

class MacrosScreen extends StatelessWidget {
  const MacrosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macro',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Macro Principali
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Macro Principali'),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: [
                              _buildMacroButton('START_PRINT', 'Avvia Stampa'),
                              _buildMacroButton('END_PRINT', 'Fine Stampa'),
                              _buildMacroButton('PAUSE', 'Pausa'),
                              _buildMacroButton('RESUME', 'Riprendi'),
                              _buildMacroButton('CANCEL_PRINT', 'Annulla'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Macro di Calibrazione
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Calibrazione'),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: [
                              _buildMacroButton('BED_LEVELING', 'Livellamento Piano'),
                              _buildMacroButton('PID_TUNE_HOTEND', 'PID Hotend'),
                              _buildMacroButton('PID_TUNE_BED', 'PID Bed'),
                              _buildMacroButton('CALIBRATE_Z', 'Calibra Z'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Macro Personalizzate
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Macro Personalizzate'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {},
                                tooltip: 'Aggiungi Macro',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Nessuna macro personalizzata'),
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

  Widget _buildMacroButton(String macro, String label) {
    return ElevatedButton(
      onPressed: () {},
      child: Text(label),
    );
  }
}
