import 'package:flutter/material.dart';
import 'dart:math' as math;

class LayerPreviewWidget extends StatefulWidget {
  final int totalLayers;
  final Function(int)? onLayerChanged;

  const LayerPreviewWidget({
    super.key,
    required this.totalLayers,
    this.onLayerChanged,
  });

  @override
  State<LayerPreviewWidget> createState() => _LayerPreviewWidgetState();
}

class _LayerPreviewWidgetState extends State<LayerPreviewWidget>
    with SingleTickerProviderStateMixin {
  int _currentLayer = 1;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _showInfill = true;
  bool _showPerimeters = true;
  bool _showSupports = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Controlli visualizzazione
        _buildLayerControls(),
        const SizedBox(height: 16),
        // Area di visualizzazione 3D
        Expanded(
          child: _buildLayerVisualization(),
        ),
        const SizedBox(height: 16),
        // Slider per navigazione layer
        _buildLayerSlider(),
        const SizedBox(height: 8),
        // Informazioni layer corrente
        _buildLayerInfo(),
      ],
    );
  }

  Widget _buildLayerControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Controlli Visualizzazione',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    IconButton(
                      onPressed: _previousLayer,
                      icon: const Icon(Icons.skip_previous),
                      tooltip: 'Layer precedente',
                    ),
                    IconButton(
                      onPressed: _playAnimation,
                      icon: const Icon(Icons.play_arrow),
                      tooltip: 'Anima layer',
                    ),
                    IconButton(
                      onPressed: _nextLayer,
                      icon: const Icon(Icons.skip_next),
                      tooltip: 'Layer successivo',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildToggleOption(
                    'Perimetri',
                    _showPerimeters,
                    Colors.blue,
                    (value) => setState(() => _showPerimeters = value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildToggleOption(
                    'Riempimento',
                    _showInfill,
                    Colors.green,
                    (value) => setState(() => _showInfill = value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildToggleOption(
                    'Supporti',
                    _showSupports,
                    Colors.orange,
                    (value) => setState(() => _showSupports = value),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(
    String label,
    bool value,
    Color color,
    Function(bool) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? color : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: value ? color : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: value ? color : Colors.grey,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: color,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildLayerVisualization() {
    return Card(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomPaint(
            painter: LayerPainter(
              currentLayer: _currentLayer,
              totalLayers: widget.totalLayers,
              showInfill: _showInfill,
              showPerimeters: _showPerimeters,
              showSupports: _showSupports,
              isDarkMode: Theme.of(context).brightness == Brightness.dark,
            ),
            child: Container(),
          ),
        ),
      ),
    );
  }

  Widget _buildLayerSlider() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  'Layer: $_currentLayer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'di ${widget.totalLayers}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                valueIndicatorShape: const PaddleSliderValueIndicatorShape(),
                valueIndicatorTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                showValueIndicator: ShowValueIndicator.always,
              ),
              child: Slider(
                value: _currentLayer.toDouble(),
                min: 1,
                max: widget.totalLayers.toDouble(),
                divisions: widget.totalLayers - 1,
                label: 'Layer $_currentLayer',
                onChanged: (value) {
                  setState(() {
                    _currentLayer = value.round();
                  });
                  _animationController.reset();
                  _animationController.forward();
                  widget.onLayerChanged?.call(_currentLayer);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayerInfo() {
    final progress = (_currentLayer / widget.totalLayers * 100);
    final layerHeight = 0.2; // mm
    final currentHeight = _currentLayer * layerHeight;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Progresso: ${progress.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: progress / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Altezza: ${currentHeight.toStringAsFixed(2)}mm',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Layer: $layerHeight mm',
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _previousLayer() {
    if (_currentLayer > 1) {
      setState(() {
        _currentLayer--;
      });
      _animationController.reset();
      _animationController.forward();
      widget.onLayerChanged?.call(_currentLayer);
    }
  }

  void _nextLayer() {
    if (_currentLayer < widget.totalLayers) {
      setState(() {
        _currentLayer++;
      });
      _animationController.reset();
      _animationController.forward();
      widget.onLayerChanged?.call(_currentLayer);
    }
  }

  void _playAnimation() {
    // TODO: Implementare animazione automatica attraverso i layer
    _animationController.reset();
    _animationController.forward();
  }
}

class LayerPainter extends CustomPainter {
  final int currentLayer;
  final int totalLayers;
  final bool showInfill;
  final bool showPerimeters;
  final bool showSupports;
  final bool isDarkMode;

  LayerPainter({
    required this.currentLayer,
    required this.totalLayers,
    required this.showInfill,
    required this.showPerimeters,
    required this.showSupports,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) * 0.3;

    // Disegna i layer precedenti con opacità ridotta
    for (int layer = 1; layer <= currentLayer; layer++) {
      final opacity = layer == currentLayer ? 1.0 : 0.3;
      final layerOffset = (layer - currentLayer) * 2.0;
      
      _drawLayer(
        canvas,
        center + Offset(0, layerOffset),
        baseRadius,
        layer,
        opacity,
      );
    }

    // Disegna griglia di riferimento
    _drawGrid(canvas, size);
    
    // Disegna assi di riferimento
    _drawAxes(canvas, center, baseRadius);
  }

  void _drawLayer(Canvas canvas, Offset center, double radius, int layer, double opacity) {
    // Calcola le dimensioni del layer basate sulla posizione
    final layerProgress = layer / totalLayers;
    final currentRadius = radius * (0.8 + 0.2 * (1 - layerProgress));

    // Perimetro esterno
    if (showPerimeters) {
      final perimeterPaint = Paint()
        ..color = Colors.blue.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, currentRadius, perimeterPaint);
      
      // Perimetro interno (se presente)
      if (currentRadius > 30) {
        canvas.drawCircle(center, currentRadius * 0.6, perimeterPaint);
      }
    }

    // Riempimento (pattern)
    if (showInfill && currentRadius > 20) {
      final infillPaint = Paint()
        ..color = Colors.green.withOpacity(opacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      _drawInfillPattern(canvas, center, currentRadius * 0.9, infillPaint);
    }

    // Supporti (se necessari)
    if (showSupports && layer < totalLayers * 0.7) {
      final supportPaint = Paint()
        ..color = Colors.orange.withOpacity(opacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      _drawSupports(canvas, center, currentRadius, supportPaint);
    }
  }

  void _drawInfillPattern(Canvas canvas, Offset center, double radius, Paint paint) {
    // Pattern di riempimento a griglia
    final step = 8.0;
    final bounds = Rect.fromCircle(center: center, radius: radius);

    for (double x = bounds.left; x <= bounds.right; x += step) {
      for (double y = bounds.top; y <= bounds.bottom; y += step) {
        final point1 = Offset(x, y);
        final point2 = Offset(x + step * 0.7, y + step * 0.7);
        
        // Verifica se i punti sono dentro il cerchio
        if ((point1 - center).distance <= radius && 
            (point2 - center).distance <= radius) {
          canvas.drawLine(point1, point2, paint);
        }
      }
    }
  }

  void _drawSupports(Canvas canvas, Offset center, double radius, Paint paint) {
    // Disegna alcuni supporti verticali
    final supportPositions = [
      center + Offset(radius * 0.3, radius * 0.3),
      center + Offset(-radius * 0.3, radius * 0.3),
      center + Offset(0, radius * 0.5),
    ];

    for (final pos in supportPositions) {
      canvas.drawLine(
        pos,
        pos + const Offset(0, 15),
        paint,
      );
      
      // Piccolo cerchio alla base
      canvas.drawCircle(pos + const Offset(0, 15), 2, paint);
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = (isDarkMode ? Colors.white : Colors.black).withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Griglia orizzontale
    for (double y = 0; y <= size.height; y += 20) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Griglia verticale
    for (double x = 0; x <= size.width; x += 20) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
  }

  void _drawAxes(Canvas canvas, Offset center, double radius) {
    final axesPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Asse X (rosso)
    axesPaint.color = Colors.red.withOpacity(0.7);
    canvas.drawLine(
      center + Offset(-radius * 0.3, 0),
      center + Offset(radius * 0.3, 0),
      axesPaint,
    );
    
    // Freccia X
    canvas.drawLine(
      center + Offset(radius * 0.3, 0),
      center + Offset(radius * 0.25, -5),
      axesPaint,
    );
    canvas.drawLine(
      center + Offset(radius * 0.3, 0),
      center + Offset(radius * 0.25, 5),
      axesPaint,
    );

    // Asse Y (verde)
    axesPaint.color = Colors.green.withOpacity(0.7);
    canvas.drawLine(
      center + Offset(0, -radius * 0.3),
      center + Offset(0, radius * 0.3),
      axesPaint,
    );
    
    // Freccia Y
    canvas.drawLine(
      center + Offset(0, -radius * 0.3),
      center + Offset(-5, -radius * 0.25),
      axesPaint,
    );
    canvas.drawLine(
      center + Offset(0, -radius * 0.3),
      center + Offset(5, -radius * 0.25),
      axesPaint,
    );

    // Etichette assi
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Etichetta X
    textPainter.text = TextSpan(
      text: 'X',
      style: TextStyle(
        color: Colors.red,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, center + Offset(radius * 0.35, -8));

    // Etichetta Y
    textPainter.text = TextSpan(
      text: 'Y',
      style: TextStyle(
        color: Colors.green,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, center + Offset(-8, -radius * 0.35));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
