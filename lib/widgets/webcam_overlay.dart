import 'package:flutter/material.dart';

enum WebcamSize {
  small,
  medium,
  large,
  fullscreen
}

class WebcamOverlay extends StatefulWidget {
  final WebcamSize size;
  final VoidCallback? onSizeChange;
  final bool isDraggable;

  const WebcamOverlay({
    super.key,
    this.size = WebcamSize.small,
    this.onSizeChange,
    this.isDraggable = true,
  });

  @override
  State<WebcamOverlay> createState() => _WebcamOverlayState();
}

class _WebcamOverlayState extends State<WebcamOverlay> {
  Offset _position = const Offset(16, 16);
  late WebcamSize _currentSize;

  @override
  void initState() {
    super.initState();
    _currentSize = widget.size;
    // Posiziona inizialmente la webcam nell'angolo in alto a destra
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final screenSize = MediaQuery.of(context).size;
        final safeArea = MediaQuery.of(context).padding;
        final size = _getWebcamSize(context);
        
        setState(() {
          _position = Offset(
            screenSize.width - size.width - safeArea.right - 16,
            safeArea.top + 16,
          );
        });
      }
    });
  }

  Size _clampSize(Size size, Size min, Size max) {
    return Size(
      size.width.clamp(min.width, max.width),
      size.height.clamp(min.height, max.height),
    );
  }

  Size _getWebcamSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final safeArea = MediaQuery.of(context).padding;
    final availableWidth = screenSize.width - safeArea.left - safeArea.right;
    final availableHeight = screenSize.height - safeArea.top - safeArea.bottom;
    
    switch (_currentSize) {
      case WebcamSize.small:
        final width = availableWidth * 0.2;
        return _clampSize(
          Size(width, width * 9 / 16),
          const Size(160, 90),
          Size(availableWidth * 0.3, availableHeight * 0.3),
        );
      case WebcamSize.medium:
        final width = availableWidth * 0.3;
        return _clampSize(
          Size(width, width * 9 / 16),
          const Size(240, 135),
          Size(availableWidth * 0.4, availableHeight * 0.4),
        );
      case WebcamSize.large:
        final width = availableWidth * 0.4;
        return _clampSize(
          Size(width, width * 9 / 16),
          const Size(320, 180),
          Size(availableWidth * 0.6, availableHeight * 0.6),
        );
      case WebcamSize.fullscreen:
        return Size(availableWidth, availableHeight);
    }
  }

  void _cycleSize() {
    setState(() {
      switch (_currentSize) {
        case WebcamSize.small:
          _currentSize = WebcamSize.medium;
          break;
        case WebcamSize.medium:
          _currentSize = WebcamSize.large;
          break;
        case WebcamSize.large:
          _currentSize = WebcamSize.fullscreen;
          break;
        case WebcamSize.fullscreen:
          _currentSize = WebcamSize.small;
          break;
      }
    });
    widget.onSizeChange?.call();
  }

  @override
  Widget build(BuildContext context) {
    final size = _getWebcamSize(context);
    
    if (_currentSize == WebcamSize.fullscreen) {
      return Material(
        color: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Container(
                color: Colors.black54,
                child: const Center(
                  child: Text(
                    'Webcam non configurata',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
                onPressed: _cycleSize,
              ),
            ),
          ],
        ),
      );
    }

    return widget.isDraggable
        ? Positioned(
            left: _position.dx,
            top: _position.dy,
            child: Draggable(
              feedback: _buildWebcamCard(size),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: _buildWebcamCard(size),
              ),
              onDragEnd: (details) {
                final screenSize = MediaQuery.of(context).size;
                final safeArea = MediaQuery.of(context).padding;
                
                setState(() {
                  // Mantieni la webcam all'interno dei limiti dello schermo
                  _position = Offset(
                    details.offset.dx.clamp(
                      safeArea.left,
                      screenSize.width - size.width - safeArea.right,
                    ),
                    details.offset.dy.clamp(
                      safeArea.top,
                      screenSize.height - size.height - safeArea.bottom,
                    ),
                  );
                });
              },
              child: _buildWebcamCard(size),
            ),
          )
        : _buildWebcamCard(size);
  }

  Widget _buildWebcamCard(Size size) {
    return Card(
      elevation: 4,
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            const Center(
              child: Text(
                'Webcam non configurata',
                style: TextStyle(color: Colors.white),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Row(
                children: [
                  IconButton(
                    iconSize: 20,
                    icon: const Icon(Icons.photo_camera, color: Colors.white),
                    onPressed: () {
                      // TODO: Implementare screenshot
                    },
                  ),
                  IconButton(
                    iconSize: 20,
                    icon: const Icon(Icons.zoom_in, color: Colors.white),
                    onPressed: _cycleSize,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
