import 'package:flutter/material.dart';
import '../services/mock_printer_service.dart';
import '../models/printer_status.dart';

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  late MockPrinterService _printerService;
  PrinterStatus? _status;

  @override
  void initState() {
    super.initState();
    _printerService = MockPrinterService();
    _connectToPrinter();
  }

  void _connectToPrinter() {
    _printerService.printerUpdates.listen(
      (status) {
        if (mounted) {
          setState(() => _status = status);
        }
      },
      onError: (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Errore di connessione: $e')),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pimp My Printer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Implementare schermata impostazioni
            },
          ),
        ],
      ),
      body: _status == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTemperatureCard(),
                    const SizedBox(height: 16),
                    _buildControlsCard(),
                    if (_status?.filename != null) ...[
                      const SizedBox(height: 16),
                      _buildPrintProgressCard(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTemperatureCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Temperature', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            _buildTemperatureRow('Nozzle', _status?.nozzleTemp ?? 0, _status?.nozzleTargetTemp ?? 0),
            const SizedBox(height: 8),
            _buildTemperatureRow('Bed', _status?.bedTemp ?? 0, _status?.bedTargetTemp ?? 0),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureRow(String label, double current, double target) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text('${current.toStringAsFixed(1)}°C / ${target.toStringAsFixed(1)}°C'),
      ],
    );
  }

  Widget _buildControlsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Controlli', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _printerService.home(),
                  child: const Text('Home'),
                ),
                ElevatedButton(
                  onPressed: () => _printerService.disableMotors(),
                  child: const Text('Disabilita Motori'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('Temperatura Ugello'),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _printerService.setNozzleTemperature(200),
                          icon: const Icon(Icons.local_fire_department),
                        ),
                        IconButton(
                          onPressed: () => _printerService.setNozzleTemperature(0),
                          icon: const Icon(Icons.ac_unit),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text('Temperatura Piano'),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => _printerService.setBedTemperature(60),
                          icon: const Icon(Icons.local_fire_department),
                        ),
                        IconButton(
                          onPressed: () => _printerService.setBedTemperature(0),
                          icon: const Icon(Icons.ac_unit),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_status?.state == 'idle')
              Center(
                child: ElevatedButton(
                  onPressed: () => _printerService.startPrint('test_print.gcode'),
                  child: const Text('Avvia Stampa di Prova'),
                ),
              )
            else if (_status?.state == 'printing')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _printerService.pausePrint(),
                    child: const Text('Pausa'),
                  ),
                  ElevatedButton(
                    onPressed: () => _printerService.stopPrint(),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Stop'),
                  ),
                ],
              )
            else if (_status?.state == 'paused')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => _printerService.resumePrint(),
                    child: const Text('Riprendi'),
                  ),
                  ElevatedButton(
                    onPressed: () => _printerService.stopPrint(),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Stop'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrintProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stampa in Corso', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(_status?.filename ?? ''),
            LinearProgressIndicator(value: _status?.progress ?? 0),
            Text('${((_status?.progress ?? 0) * 100).toStringAsFixed(1)}%'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _printerService.dispose();
    super.dispose();
  }
}
