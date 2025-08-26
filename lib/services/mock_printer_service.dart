import 'dart:async';
import 'dart:math';
import '../models/printer_status.dart';

class MockPrinterService {
  final _random = Random();
  Timer? _timer;
  final _statusController = StreamController<PrinterStatus>.broadcast();
  bool _isPrinting = false;
  double _progress = 0;

  PrinterStatus _currentStatus = PrinterStatus(
    bedTemp: 25,
    bedTargetTemp: 0,
    nozzleTemp: 25,
    nozzleTargetTemp: 0,
    state: 'idle',
    progress: 0,
  );

  MockPrinterService() {
    // Simula fluttuazioni di temperatura ogni secondo
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTemperatures();
      if (_isPrinting) {
        _updatePrintProgress();
      }
      _statusController.add(_currentStatus);
    });
  }

  void _updateTemperatures() {
    // Simula piccole fluttuazioni di temperatura
    if (_currentStatus.bedTargetTemp > 0) {
      _currentStatus = _currentStatus.copyWith(
        bedTemp: _simulateTemperature(
          _currentStatus.bedTemp,
          _currentStatus.bedTargetTemp,
        ),
      );
    }

    if (_currentStatus.nozzleTargetTemp > 0) {
      _currentStatus = _currentStatus.copyWith(
        nozzleTemp: _simulateTemperature(
          _currentStatus.nozzleTemp,
          _currentStatus.nozzleTargetTemp,
        ),
      );
    }
  }

  double _simulateTemperature(double current, double target) {
    if (target > current) {
      return min(target, current + 2 + _random.nextDouble());
    } else if (target < current) {
      return max(target, current - 1 - _random.nextDouble());
    }
    // Aggiungi una piccola fluttuazione intorno alla temperatura target
    return target + (_random.nextDouble() * 0.4 - 0.2);
  }

  void _updatePrintProgress() {
    if (_progress < 1) {
      _progress += 0.001;
      _currentStatus = _currentStatus.copyWith(
        progress: _progress,
      );
    } else {
      _isPrinting = false;
      _progress = 0;
      _currentStatus = _currentStatus.copyWith(
        state: 'idle',
        progress: 0,
        filename: null,
      );
    }
  }

  Stream<PrinterStatus> get printerUpdates => _statusController.stream;

  Future<void> setBedTemperature(double temp) async {
    _currentStatus = _currentStatus.copyWith(bedTargetTemp: temp);
    _statusController.add(_currentStatus);
  }

  Future<void> setNozzleTemperature(double temp) async {
    _currentStatus = _currentStatus.copyWith(nozzleTargetTemp: temp);
    _statusController.add(_currentStatus);
  }

  Future<void> startPrint(String filename) async {
    _isPrinting = true;
    _progress = 0;
    _currentStatus = _currentStatus.copyWith(
      state: 'printing',
      filename: filename,
      progress: 0,
    );
    _statusController.add(_currentStatus);
  }

  Future<void> pausePrint() async {
    _isPrinting = false;
    _currentStatus = _currentStatus.copyWith(state: 'paused');
    _statusController.add(_currentStatus);
  }

  Future<void> resumePrint() async {
    _isPrinting = true;
    _currentStatus = _currentStatus.copyWith(state: 'printing');
    _statusController.add(_currentStatus);
  }

  Future<void> stopPrint() async {
    _isPrinting = false;
    _progress = 0;
    _currentStatus = _currentStatus.copyWith(
      state: 'idle',
      progress: 0,
      filename: null,
    );
    _statusController.add(_currentStatus);
  }

  Future<void> home() async {
    // Simula un'operazione di homing
    _currentStatus = _currentStatus.copyWith(state: 'homing');
    _statusController.add(_currentStatus);
    
    await Future.delayed(const Duration(seconds: 2));
    
    _currentStatus = _currentStatus.copyWith(state: 'idle');
    _statusController.add(_currentStatus);
  }

  Future<void> disableMotors() async {
    // Simula la disabilitazione dei motori
    _currentStatus = _currentStatus.copyWith(state: 'motors_off');
    _statusController.add(_currentStatus);
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    _currentStatus = _currentStatus.copyWith(state: 'idle');
    _statusController.add(_currentStatus);
  }

  void dispose() {
    _timer?.cancel();
    _statusController.close();
  }
}
