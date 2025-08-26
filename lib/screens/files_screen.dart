import 'package:flutter/material.dart';

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
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Carica File'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.create_new_folder),
                    label: const Text('Nuova Cartella'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh),
                    label: const Text('Aggiorna'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Lista File
          Expanded(
            child: Card(
              child: ListView(
                children: [
                  _buildFileListTile(
                    'calibrazione.gcode',
                    '2.5 MB',
                    '10 minuti',
                    Icons.file_present,
                  ),
                  const Divider(),
                  _buildFileListTile(
                    'test_print.gcode',
                    '1.2 MB',
                    '5 minuti',
                    Icons.file_present,
                  ),
                  const Divider(),
                  _buildFileListTile(
                    'config',
                    '--',
                    '--',
                    Icons.folder,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileListTile(String name, String size, String time, IconData icon) {
    return ListTile(
      leading: Icon(icon),
      title: Text(name),
      subtitle: Text('Dimensione: $size - Tempo stimato: $time'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            onPressed: () {},
            tooltip: 'Stampa',
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {},
            tooltip: 'Informazioni',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {},
            tooltip: 'Elimina',
          ),
        ],
      ),
    );
  }
}
