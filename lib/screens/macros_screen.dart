import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

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
                          Text(
                            'Macro Principali',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildMacroGrid([
                            _MacroData('START_PRINT', 'Avvia Stampa', Icons.play_arrow, Colors.green),
                            _MacroData('END_PRINT', 'Fine Stampa', Icons.stop, Colors.red),
                            _MacroData('PAUSE', 'Pausa', Icons.pause, Colors.orange),
                            _MacroData('RESUME', 'Riprendi', Icons.play_arrow, Colors.blue),
                            _MacroData('CANCEL_PRINT', 'Annulla', Icons.cancel, Colors.red),
                          ]),
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
                          Text(
                            'Calibrazione',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildMacroGrid([
                            _MacroData('BED_LEVELING', 'Livellamento Piano', Icons.tune, Colors.purple),
                            _MacroData('PID_TUNE_HOTEND', 'PID Hotend', Icons.thermostat, Colors.deepOrange),
                            _MacroData('PID_TUNE_BED', 'PID Bed', Icons.hot_tub, Colors.red),
                            _MacroData('CALIBRATE_Z', 'Calibra Z', Icons.height, Colors.indigo),
                          ]),
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
                              Text(
                                'Macro Personalizzate',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? const Color(0xFF1A1A1A)
                                      : Colors.grey[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!,
                                  ),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () {
                                    // TODO: Implementare aggiunta macro
                                  },
                                  tooltip: 'Aggiungi Macro',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF1A1A1A)
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              'Nessuna macro personalizzata',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 16,
                              ),
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
        ],
      ),
    );
  }

  Widget _buildMacroGrid(List<_MacroData> macros) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: macros.length,
          itemBuilder: (context, index) {
            final macro = macros[index];
            return _buildMacroButton(macro);
          },
        );
      },
    );
  }

  Widget _buildMacroButton(_MacroData macro) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // TODO: Implementare esecuzione macro
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: macro.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        macro.icon,
                        color: macro.color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        macro.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
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

class _MacroData {
  final String command;
  final String label;
  final IconData icon;
  final Color color;

  _MacroData(this.command, this.label, this.icon, this.color);
}
