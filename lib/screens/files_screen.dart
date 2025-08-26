import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class FilesScreen extends StatelessWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'File',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          // Barra degli strumenti
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToolbarButton(
                      context,
                      Icons.upload_file,
                      'Carica File',
                      Colors.blue,
                      () {
                        // TODO: Implementare caricamento file
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildToolbarButton(
                      context,
                      Icons.create_new_folder,
                      'Nuova Cartella',
                      Colors.green,
                      () {
                        // TODO: Implementare creazione cartella
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Lista File
          Expanded(
            child: Card(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[700]!
                              : Colors.grey[300]!,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'File G-Code',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        _buildToolbarButton(
                          context,
                          Icons.refresh,
                          'Aggiorna',
                          Colors.grey,
                          () {
                            // TODO: Implementare aggiornamento lista
                          },
                          isCompact: true,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildFileListTile(
                          context,
                          'calibrazione.gcode',
                          '2.5 MB',
                          '10 minuti',
                          Icons.description,
                          false,
                        ),
                        _buildDivider(context),
                        _buildFileListTile(
                          context,
                          'test_print.gcode',
                          '1.2 MB',
                          '5 minuti',
                          Icons.description,
                          false,
                        ),
                        _buildDivider(context),
                        _buildFileListTile(
                          context,
                          'config',
                          '--',
                          '--',
                          Icons.folder,
                          true,
                        ),
                      ],
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

  Widget _buildToolbarButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed, {
    bool isCompact = false,
  }) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        return Container(
          height: isCompact ? 40 : 48,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onPressed,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 12 : 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: color,
                      size: isCompact ? 20 : 24,
                    ),
                    if (!isCompact) ...[
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFileListTile(
    BuildContext context,
    String name,
    String size,
    String time,
    IconData icon,
    bool isFolder,
  ) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isFolder
                      ? Colors.amber.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isFolder ? Colors.amber : Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Dimensione: $size${size != '--' ? ' - Tempo stimato: $time' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isFolder) ...[
                _buildActionButton(
                  context,
                  Icons.play_arrow,
                  'Stampa',
                  Colors.green,
                  () {
                    // TODO: Implementare stampa
                  },
                ),
                const SizedBox(width: 8),
              ],
              _buildActionButton(
                context,
                Icons.info_outline,
                'Info',
                Colors.blue,
                () {
                  // TODO: Implementare informazioni
                },
              ),
              const SizedBox(width: 8),
              _buildActionButton(
                context,
                Icons.delete_outline,
                'Elimina',
                Colors.red,
                () {
                  // TODO: Implementare eliminazione
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    String tooltip,
    Color color,
    VoidCallback onPressed,
  ) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onPressed,
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 1,
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[700]
          : Colors.grey[300],
    );
  }
}
