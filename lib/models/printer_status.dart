class PrinterStatus {
  final double bedTemp;
  final double bedTargetTemp;
  final double nozzleTemp;
  final double nozzleTargetTemp;
  final String state;
  final double progress;
  final String? filename;

  PrinterStatus({
    required this.bedTemp,
    required this.bedTargetTemp,
    required this.nozzleTemp,
    required this.nozzleTargetTemp,
    required this.state,
    required this.progress,
    this.filename,
  });

  PrinterStatus copyWith({
    double? bedTemp,
    double? bedTargetTemp,
    double? nozzleTemp,
    double? nozzleTargetTemp,
    String? state,
    double? progress,
    String? filename,
  }) {
    return PrinterStatus(
      bedTemp: bedTemp ?? this.bedTemp,
      bedTargetTemp: bedTargetTemp ?? this.bedTargetTemp,
      nozzleTemp: nozzleTemp ?? this.nozzleTemp,
      nozzleTargetTemp: nozzleTargetTemp ?? this.nozzleTargetTemp,
      state: state ?? this.state,
      progress: progress ?? this.progress,
      filename: filename ?? this.filename,
    );
  }
}
