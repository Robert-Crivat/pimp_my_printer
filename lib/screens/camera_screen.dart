import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Webcam',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                // Area Principale Webcam
                Expanded(
                  flex: 3,
                  child: Card(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // Placeholder webcam
                          const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.videocam_off,
                                  size: 64,
                                  color: Colors.white54,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Webcam non configurata',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Configura la webcam nelle impostazioni',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Overlay con controlli posizionali (come nelle immagini)
                          Positioned(
                            top: 20,
                            left: 20,
                            child: _buildOverlayControl(
                              context,
                              Icons.zoom_in,
                              'Zoom In',
                              () {
                                // TODO: Implementare zoom in
                              },
                            ),
                          ),
                          Positioned(
                            bottom: 20,
                            right: 20,
                            child: _buildOverlayControl(
                              context,
                              Icons.zoom_out,
                              'Zoom Out',
                              () {
                                // TODO: Implementare zoom out
                              },
                            ),
                          ),
                          // Linee di calibrazione (come nelle immagini)
                          CustomPaint(
                            size: Size.infinite,
                            painter: _CalibrationLinesPainter(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Controlli Webcam
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Controlli Webcam',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildControlButton(
                                context,
                                Icons.refresh,
                                'Aggiorna',
                                Colors.blue,
                                () {
                                  // TODO: Implementare aggiornamento webcam
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildControlButton(
                                context,
                                Icons.photo_camera,
                                'Screenshot',
                                Colors.green,
                                () {
                                  // TODO: Implementare screenshot
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildControlButton(
                                context,
                                Icons.settings,
                                'Impostazioni',
                                Colors.grey,
                                () {
                                  // TODO: Implementare impostazioni webcam
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlayControl(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white24,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context,
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        return Container(
          height: 56,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
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

class _CalibrationLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Linea diagonale dall'alto sinistra al basso destra
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width, size.height),
      paint,
    );

    // Cerchi di calibrazione
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.15),
      20,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.6),
      15,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.9, size.height * 0.85),
      20,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
