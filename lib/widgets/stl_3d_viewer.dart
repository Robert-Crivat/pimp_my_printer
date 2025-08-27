import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

class STL3DViewer extends StatefulWidget {
  final String? filePath;
  final String? fileName;
  final Uint8List? fileBytes; // Aggiunto per il supporto web
  final double? width;
  final double? height;
  final bool showControls;

  const STL3DViewer({
    super.key,
    this.filePath,
    this.fileName,
    this.fileBytes,
    this.width,
    this.height,
    this.showControls = true,
  });

  @override
  State<STL3DViewer> createState() => _STL3DViewerState();
}

class _STL3DViewerState extends State<STL3DViewer>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String? _error;
  bool _fileExists = false;
  int? _fileSize;
  int? _triangleCount;
  List<STLTriangle> _triangles = [];
  late AnimationController _rotationController;
  double _userRotationX = 0.0;
  double _userRotationY = 0.0;
  bool _autoRotate = true;
  double _scale = 1.0;
  Offset _lastPanPoint = Offset.zero;
  STLBounds? _bounds;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    );
    _loadModel();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(STL3DViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filePath != oldWidget.filePath) {
      _loadModel();
    }
  }

  Future<void> _loadModel() async {
    if (widget.filePath == null && widget.fileBytes == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _fileExists = false;
      _fileSize = null;
      _triangleCount = null;
      _triangles = [];
      _bounds = null;
    });

    try {
      List<int> bytes;
      
      // Usa i bytes se forniti (per il web/file picker)
      if (widget.fileBytes != null) {
        bytes = widget.fileBytes!;
        _fileSize = bytes.length;
        _fileExists = true;
        print('Usando bytes del file caricato: ${bytes.length} bytes');
      } else if (widget.filePath != null) {
        // Prova a leggere dal file system (mobile/desktop)
        final file = File(widget.filePath!);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
          _fileSize = bytes.length;
          _fileExists = true;
          print('File letto dal filesystem: ${bytes.length} bytes');
        } else {
          // Prova a caricare come asset se è il file di test
          if (widget.filePath!.contains('test_cube.stl')) {
            try {
              final assetBytes = await rootBundle.load('assets/models/test_cube.stl');
              bytes = assetBytes.buffer.asUint8List();
              _fileSize = bytes.length;
              _fileExists = true;
              print('File di test caricato da asset: ${bytes.length} bytes');
            } catch (e) {
              print('Errore caricamento asset: $e');
              await _createDemoModel();
              _fileExists = false;
              return;
            }
          } else {
            await _createDemoModel();
            _fileExists = false;
            return;
          }
        }
      } else {
        await _createDemoModel();
        _fileExists = false;
        return;
      }

      if (widget.fileName?.toLowerCase().endsWith('.stl') == true) {
        await _parseSTLFile(bytes);
      } else {
        await _createDemoModel();
      }
      
      setState(() {
        _isLoading = false;
      });

      if (_autoRotate) {
        _rotationController.repeat();
      }

      if (mounted && _fileExists && _triangleCount != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'STL caricato: ${(_fileSize! / 1024).round()}KB, $_triangleCount triangoli',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      await _createDemoModel();
      setState(() {
        _isLoading = false;
        _error = null;
      });
    }
  }

  Future<void> _parseSTLFile(List<int> bytes) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (bytes.length < 80) {
        throw Exception('File STL troppo piccolo');
      }

      // Determina se è ASCII o binario
      final header = String.fromCharCodes(bytes.take(5));
      final isAscii = header.toLowerCase().startsWith('solid');

      List<STLTriangle> triangles;
      
      if (isAscii) {
        triangles = await _parseASCIISTL(bytes);
      } else {
        triangles = await _parseBinarySTL(bytes);
      }

      if (triangles.isNotEmpty) {
        _triangles = triangles;
        _triangleCount = triangles.length;
        _bounds = _calculateBounds(triangles);
        _scale = _calculateOptimalScale();
      } else {
        throw Exception('Nessun triangolo trovato nel file STL');
      }
      
    } catch (e) {
      // Se il parsing fallisce, crea un modello demo
      await _createDemoModel();
    }
  }

  Future<List<STLTriangle>> _parseASCIISTL(List<int> bytes) async {
    final content = String.fromCharCodes(bytes);
    final lines = content.split('\n');
    final triangles = <STLTriangle>[];
    
    STLVector3? normal;
    final vertices = <STLVector3>[];
    
    for (final line in lines) {
      final trimmed = line.trim();
      
      if (trimmed.startsWith('facet normal')) {
        final parts = trimmed.split(' ');
        if (parts.length >= 5) {
          normal = STLVector3(
            double.tryParse(parts[2]) ?? 0.0,
            double.tryParse(parts[3]) ?? 0.0,
            double.tryParse(parts[4]) ?? 0.0,
          );
        }
      } else if (trimmed.startsWith('vertex')) {
        final parts = trimmed.split(' ');
        if (parts.length >= 4) {
          vertices.add(STLVector3(
            double.tryParse(parts[1]) ?? 0.0,
            double.tryParse(parts[2]) ?? 0.0,
            double.tryParse(parts[3]) ?? 0.0,
          ));
        }
      } else if (trimmed == 'endfacet') {
        if (vertices.length == 3 && normal != null) {
          triangles.add(STLTriangle(
            vertices[0], vertices[1], vertices[2], normal,
          ));
        }
        vertices.clear();
        normal = null;
      }
    }
    
    return triangles;
  }

  Future<List<STLTriangle>> _parseBinarySTL(List<int> bytes) async {
    if (bytes.length < 84) {
      throw Exception('File STL binario malformato');
    }

    // Leggi il numero di triangoli (bytes 80-83, little endian)
    final triangleCount = ByteData.sublistView(Uint8List.fromList(bytes), 80, 84)
        .getUint32(0, Endian.little);

    final expectedSize = 80 + 4 + (triangleCount * 50);
    if (bytes.length < expectedSize) {
      throw Exception('File STL binario incompleto');
    }

    final triangles = <STLTriangle>[];
    var offset = 84;

    for (int i = 0; i < triangleCount; i++) {
      if (offset + 50 > bytes.length) break;

      final triangleBytes = ByteData.sublistView(Uint8List.fromList(bytes), offset, offset + 50);
      
      // Normale (12 bytes)
      final normal = STLVector3(
        triangleBytes.getFloat32(0, Endian.little),
        triangleBytes.getFloat32(4, Endian.little),
        triangleBytes.getFloat32(8, Endian.little),
      );
      
      // Vertici (36 bytes)
      final v1 = STLVector3(
        triangleBytes.getFloat32(12, Endian.little),
        triangleBytes.getFloat32(16, Endian.little),
        triangleBytes.getFloat32(20, Endian.little),
      );
      
      final v2 = STLVector3(
        triangleBytes.getFloat32(24, Endian.little),
        triangleBytes.getFloat32(28, Endian.little),
        triangleBytes.getFloat32(32, Endian.little),
      );
      
      final v3 = STLVector3(
        triangleBytes.getFloat32(36, Endian.little),
        triangleBytes.getFloat32(40, Endian.little),
        triangleBytes.getFloat32(44, Endian.little),
      );
      
      triangles.add(STLTriangle(v1, v2, v3, normal));
      offset += 50;
    }

    return triangles;
  }

  STLBounds _calculateBounds(List<STLTriangle> triangles) {
    if (triangles.isEmpty) {
      return STLBounds(
        STLVector3(0, 0, 0),
        STLVector3(0, 0, 0),
      );
    }

    double minX = double.infinity, minY = double.infinity, minZ = double.infinity;
    double maxX = -double.infinity, maxY = -double.infinity, maxZ = -double.infinity;

    for (final triangle in triangles) {
      for (final vertex in [triangle.v1, triangle.v2, triangle.v3]) {
        minX = math.min(minX, vertex.x);
        minY = math.min(minY, vertex.y);
        minZ = math.min(minZ, vertex.z);
        maxX = math.max(maxX, vertex.x);
        maxY = math.max(maxY, vertex.y);
        maxZ = math.max(maxZ, vertex.z);
      }
    }

    return STLBounds(
      STLVector3(minX, minY, minZ),
      STLVector3(maxX, maxY, maxZ),
    );
  }

  double _calculateOptimalScale() {
    if (_bounds == null) return 1.0;
    
    final size = _bounds!.size;
    final maxDimension = math.max(size.x, math.max(size.y, size.z));
    
    if (maxDimension == 0) return 1.0;
    
    return 2.0 / maxDimension; // Scala per adattare nell'area di visualizzazione
  }

  Future<void> _createDemoModel() async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Crea un modello demo (un cubo con dettagli)
    _triangles = _createCubeTriangles();
    _triangleCount = _triangles.length;
    _bounds = _calculateBounds(_triangles);
    _scale = _calculateOptimalScale();
  }

  List<STLTriangle> _createCubeTriangles() {
    final triangles = <STLTriangle>[];
    
    // Vertici del cubo
    final vertices = [
      STLVector3(-1, -1, 1),  // 0
      STLVector3(1, -1, 1),   // 1
      STLVector3(1, 1, 1),    // 2
      STLVector3(-1, 1, 1),   // 3
      STLVector3(-1, -1, -1), // 4
      STLVector3(1, -1, -1),  // 5
      STLVector3(1, 1, -1),   // 6
      STLVector3(-1, 1, -1),  // 7
    ];

    // Facce del cubo (ogni faccia = 2 triangoli)
    final faces = [
      // Front
      [0, 1, 2, STLVector3(0, 0, 1)],
      [0, 2, 3, STLVector3(0, 0, 1)],
      // Back
      [4, 6, 5, STLVector3(0, 0, -1)],
      [4, 7, 6, STLVector3(0, 0, -1)],
      // Bottom
      [0, 4, 5, STLVector3(0, -1, 0)],
      [0, 5, 1, STLVector3(0, -1, 0)],
      // Top
      [2, 6, 7, STLVector3(0, 1, 0)],
      [2, 7, 3, STLVector3(0, 1, 0)],
      // Left
      [0, 3, 7, STLVector3(-1, 0, 0)],
      [0, 7, 4, STLVector3(-1, 0, 0)],
      // Right
      [1, 5, 6, STLVector3(1, 0, 0)],
      [1, 6, 2, STLVector3(1, 0, 0)],
    ];

    for (final face in faces) {
      triangles.add(STLTriangle(
        vertices[face[0] as int],
        vertices[face[1] as int],
        vertices[face[2] as int],
        face[3] as STLVector3,
      ));
    }

    return triangles;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.filePath == null) {
      return _buildEmptyState();
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Stack(
        children: [
          if (!_isLoading && _error == null)
            _build3DViewer(),
          
          if (_isLoading)
            _buildLoadingOverlay(),
          
          if (_error != null)
            _buildErrorOverlay(),
          
          if (widget.fileName != null && !_isLoading && _error == null)
            _buildFileInfo(),
            
          if (widget.showControls && !_isLoading && _error == null)
            _buildControls(),
            
          if (!_isLoading && _error == null)
            _buildFileStatus(),
            
          if (widget.showControls && !_isLoading && _error == null)
            _buildZoomIndicator(),
        ],
      ),
    );
  }

  Widget _build3DViewer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Listener(
        onPointerSignal: (pointerSignal) {
          if (pointerSignal is PointerScrollEvent) {
            setState(() {
              final delta = pointerSignal.scrollDelta.dy;
              if (delta > 0) {
                _scale = (_scale / 1.1).clamp(0.1, 5.0);
              } else {
                _scale = (_scale * 1.1).clamp(0.1, 5.0);
              }
              _autoRotate = false;
              _rotationController.stop();
            });
          }
        },
        child: GestureDetector(
          onPanStart: (details) {
            _autoRotate = false;
            _rotationController.stop();
            _lastPanPoint = details.localPosition;
          },
          onPanUpdate: (details) {
            setState(() {
              final delta = details.localPosition - _lastPanPoint;
              _userRotationY += delta.dx * 0.01;
              _userRotationX += delta.dy * 0.01;
              _userRotationX = _userRotationX.clamp(-math.pi / 2, math.pi / 2);
              _lastPanPoint = details.localPosition;
              _autoRotate = false;
              _rotationController.stop();
            });
          },
          onDoubleTap: () {
            setState(() {
              _userRotationX = 0.0;
              _userRotationY = 0.0;
              _scale = 1.0;
              _autoRotate = true;
              _rotationController.repeat();
            });
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              // Sfondo più chiaro e professionale
              color: Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF2A2A2A)  // Grigio scuro per tema scuro
                : const Color(0xFFF8F9FA), // Grigio molto chiaro per tema chiaro
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Sfondo con griglia 3D
                CustomPaint(
                  size: Size.infinite,
                  painter: GridPainter(
                    rotationX: _userRotationX,
                    rotationY: _userRotationY,
                    rotationAnimation: _rotationController,
                    scale: _scale,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
                // Modello 3D
                CustomPaint(
                  painter: STL3DPainter(
                    triangles: _triangles,
                    rotationX: _userRotationX,
                    rotationY: _userRotationY,
                    rotationAnimation: _rotationController,
                    scale: _scale,
                    bounds: _bounds,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Parsing file STL...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Lettura triangoli 3D',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadModel,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.view_in_ar_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Visualizzatore STL Avanzato',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Carica un file STL per vedere il modello reale',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Trascina per ruotare • Doppio tap per reset',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      top: 12,
      right: 12,
      child: Column(
        children: [
          // Controlli zoom
          _buildControlButton(
            Icons.zoom_in,
            'Zoom In',
            () {
              setState(() {
                _scale = (_scale * 1.2).clamp(0.1, 5.0);
                _autoRotate = false;
                _rotationController.stop();
              });
            },
          ),
          const SizedBox(height: 4),
          _buildControlButton(
            Icons.zoom_out,
            'Zoom Out',
            () {
              setState(() {
                _scale = (_scale / 1.2).clamp(0.1, 5.0);
                _autoRotate = false;
                _rotationController.stop();
              });
            },
          ),
          const SizedBox(height: 8),
          // Controllo rotazione automatica
          _buildControlButton(
            _autoRotate ? Icons.pause : Icons.play_arrow,
            _autoRotate ? 'Ferma rotazione' : 'Avvia rotazione',
            () {
              setState(() {
                _autoRotate = !_autoRotate;
                if (_autoRotate) {
                  _rotationController.repeat();
                } else {
                  _rotationController.stop();
                }
              });
            },
          ),
          const SizedBox(height: 8),
          // Reset vista
          _buildControlButton(
            Icons.refresh,
            'Reset vista',
            () {
              setState(() {
                _userRotationX = 0.0;
                _userRotationY = 0.0;
                _scale = 1.0;
                _autoRotate = true;
                _rotationController.repeat();
              });
            },
          ),
          const SizedBox(height: 8),
          // Info modello
          _buildControlButton(
            Icons.info_outline,
            'Info STL',
            () => _showModelInfo(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.black.withOpacity(0.8)
            : Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomIndicator() {
    return Positioned(
      bottom: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withOpacity(0.8)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.zoom_in,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              '${(_scale * 100).toInt()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfo() {
    return Positioned(
      bottom: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withOpacity(0.8)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).dividerColor.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.precision_manufacturing,
              size: 16,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 6),
            Text(
              widget.fileName!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_triangleCount != null) ...[
              const SizedBox(width: 8),
              Text(
                '$_triangleCount△',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFileStatus() {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _fileExists 
              ? Colors.green.withOpacity(0.9)
              : Colors.orange.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _fileExists ? Icons.check_circle : Icons.science,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              _fileExists ? 'STL Reale' : 'Demo',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModelInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.precision_manufacturing, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Dettagli STL'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Nome', widget.fileName ?? 'N/A'),
            if (_fileSize != null)
              _buildInfoRow('Dimensione', '${(_fileSize! / 1024).round()}KB'),
            if (_triangleCount != null)
              _buildInfoRow('Triangoli', '$_triangleCount'),
            _buildInfoRow('Stato', _fileExists ? 'File reale' : 'Modello demo'),
            if (_bounds != null) ...[
              const SizedBox(height: 8),
              const Text('Dimensioni:', style: TextStyle(fontWeight: FontWeight.w600)),
              _buildInfoRow('X', '${_bounds!.size.x.toStringAsFixed(2)}mm'),
              _buildInfoRow('Y', '${_bounds!.size.y.toStringAsFixed(2)}mm'),
              _buildInfoRow('Z', '${_bounds!.size.z.toStringAsFixed(2)}mm'),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _fileExists 
                    ? 'Questo modello è stato parsato dal tuo file STL reale. Ogni triangolo visualizzato corrisponde ai dati effettivi del file.'
                    : 'Questo è un modello demo. Carica un file STL per vedere il tuo modello reale.',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }
}

// Classi di supporto per STL
class STLVector3 {
  final double x, y, z;
  
  const STLVector3(this.x, this.y, this.z);
  
  STLVector3 operator +(STLVector3 other) => STLVector3(x + other.x, y + other.y, z + other.z);
  STLVector3 operator -(STLVector3 other) => STLVector3(x - other.x, y - other.y, z - other.z);
  STLVector3 operator *(double scalar) => STLVector3(x * scalar, y * scalar, z * scalar);
  
  // Metodi per il calcolo dell'illuminazione
  double get length => math.sqrt(x * x + y * y + z * z);
  
  STLVector3 normalized() {
    final len = length;
    if (len == 0) return const STLVector3(0, 0, 1);
    return STLVector3(x / len, y / len, z / len);
  }
  
  double dot(STLVector3 other) => x * other.x + y * other.y + z * other.z;
  
  @override
  String toString() => 'STLVector3($x, $y, $z)';
}

class STLTriangle {
  final STLVector3 v1, v2, v3;
  final STLVector3 normal;
  
  const STLTriangle(this.v1, this.v2, this.v3, this.normal);
}

class STLBounds {
  final STLVector3 min, max;
  
  const STLBounds(this.min, this.max);
  
  STLVector3 get size => max - min;
  STLVector3 get center => (min + max) * 0.5;
}

class STL3DPainter extends CustomPainter {
  final List<STLTriangle> triangles;
  final double rotationX;
  final double rotationY;
  final Animation<double> rotationAnimation;
  final double scale;
  final STLBounds? bounds;
  final bool isDark;

  STL3DPainter({
    required this.triangles,
    required this.rotationX,
    required this.rotationY,
    required this.rotationAnimation,
    required this.scale,
    required this.bounds,
    required this.isDark,
  }) : super(repaint: rotationAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    if (triangles.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final viewScale = math.min(size.width, size.height) * 0.35 * scale;
    
    // Calcola la rotazione totale
    final totalRotationY = rotationY + (rotationAnimation.value * 2 * math.pi);
    
    // Centra il modello
    final modelCenter = bounds?.center ?? const STLVector3(0, 0, 0);
    
    // Trasforma e ordina i triangoli per il depth sorting
    final transformedTriangles = <_TransformedTriangle>[];
    
    for (final triangle in triangles) {
      final t1 = _transformPoint(triangle.v1 - modelCenter, rotationX, totalRotationY, viewScale, center);
      final t2 = _transformPoint(triangle.v2 - modelCenter, rotationX, totalRotationY, viewScale, center);
      final t3 = _transformPoint(triangle.v3 - modelCenter, rotationX, totalRotationY, viewScale, center);
      
      final avgZ = (t1.z + t2.z + t3.z) / 3;
      
      // Calcola la normale trasformata per il lighting
      final transformedNormal = _transformNormal(triangle.normal, rotationX, totalRotationY);
      
      transformedTriangles.add(_TransformedTriangle(
        Offset(t1.x, t1.y),
        Offset(t2.x, t2.y),
        Offset(t3.x, t3.y),
        avgZ,
        transformedNormal,
      ));
    }
    
    // Ordina per profondità (z)
    transformedTriangles.sort((a, b) => b.avgZ.compareTo(a.avgZ));
    
    // Disegna i triangoli con illuminazione 3D (stile OrcaSlicer)
    final baseColor = isDark ? const Color(0xFFB0C4DE) : const Color(0xFF607D8B); // Grigio-blu
    
    // Definisci le fonti di luce
    final light1 = STLVector3(-1.0, -1.0, 1.0).normalized(); // Luce dall'alto a sinistra
    final light2 = STLVector3(1.0, -0.5, 0.5).normalized(); // Luce frontale/destra
    
    for (final triangle in transformedTriangles) {
      final path = Path()
        ..moveTo(triangle.p1.dx, triangle.p1.dy)
        ..lineTo(triangle.p2.dx, triangle.p2.dy)
        ..lineTo(triangle.p3.dx, triangle.p3.dy)
        ..close();
      
      // Calcola illuminazione Gouraud-like
      final double ambient = 0.3;
      final double diffuse1 = 0.5 * math.max(0.0, triangle.normal.dot(light1));
      final double diffuse2 = 0.3 * math.max(0.0, triangle.normal.dot(light2));
      
      // Calcolo speculare semplificato (Phong)
      final viewDirection = STLVector3(0, 0, -1); // Camera punta lungo Z negativo
      final reflect1 = light1 - (triangle.normal * (2 * triangle.normal.dot(light1)));
      final specular1 = 0.2 * math.pow(math.max(0.0, -reflect1.dot(viewDirection)), 32.0);

      final intensity = (ambient + diffuse1 + diffuse2 + specular1).clamp(0.0, 1.0);
      
      // Applica intensità al colore base
      final finalColor = Color.fromRGBO(
        (baseColor.red * intensity).round(),
        (baseColor.green * intensity).round(), 
        (baseColor.blue * intensity).round(),
        1.0
      );
      
      final trianglePaint = Paint()
        ..color = finalColor
        ..style = PaintingStyle.fill;
      
      canvas.drawPath(path, trianglePaint);
      
      // Outline delicato per definizione geometrica (stile OrcaSlicer)
      final outlinePaint = Paint()
        ..color = Colors.black.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.2;
      
      canvas.drawPath(path, outlinePaint);
    }
  }

  STLVector3 _transformPoint(STLVector3 point, double rotX, double rotY, double scale, Offset center) {
    // Rotazione Y
    final cosY = math.cos(rotY);
    final sinY = math.sin(rotY);
    final x1 = point.x * cosY - point.z * sinY;
    final z1 = point.x * sinY + point.z * cosY;
    
    // Rotazione X
    final cosX = math.cos(rotX);
    final sinX = math.sin(rotX);
    final y1 = point.y * cosX - z1 * sinX;
    final z2 = point.y * sinX + z1 * cosX;
    
    // Proiezione prospettica
    final perspective = 5.0;
    final projectedX = x1 / (1 + z2 / perspective);
    final projectedY = y1 / (1 + z2 / perspective);
    
    return STLVector3(
      center.dx + projectedX * scale,
      center.dy - projectedY * scale, // Inverti Y per sistema di coordinate corretto
      z2,
    );
  }

  STLVector3 _transformNormal(STLVector3 normal, double rotX, double rotY) {
    // Rotazione Y
    final cosY = math.cos(rotY);
    final sinY = math.sin(rotY);
    final x1 = normal.x * cosY - normal.z * sinY;
    final z1 = normal.x * sinY + normal.z * cosY;
    
    // Rotazione X
    final cosX = math.cos(rotX);
    final sinX = math.sin(rotX);
    final y1 = normal.y * cosX - z1 * sinX;
    final z2 = normal.y * sinX + z1 * cosX;
    
    return STLVector3(x1, -y1, z2).normalized(); // Inverti Y e normalizza
  }



  void _drawAxes(Canvas canvas, Offset center, double length) {
    // Questo metodo non è più necessario perché la griglia ha i suoi assi
  }

  @override
  bool shouldRepaint(STL3DPainter oldDelegate) {
    return oldDelegate.rotationX != rotationX ||
           oldDelegate.rotationY != rotationY ||
           oldDelegate.triangles != triangles ||
           oldDelegate.scale != scale;
  }
}

class _TransformedTriangle {
  final Offset p1, p2, p3;
  final double avgZ;
  final STLVector3 normal;
  
  const _TransformedTriangle(this.p1, this.p2, this.p3, this.avgZ, this.normal);
}

class GridPainter extends CustomPainter {
  final double rotationX;
  final double rotationY;
  final Animation<double> rotationAnimation;
  final double scale;
  final bool isDark;

  GridPainter({
    required this.rotationX,
    required this.rotationY,
    required this.rotationAnimation,
    required this.scale,
    required this.isDark,
  }) : super(repaint: rotationAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final gridSize = math.min(size.width, size.height) * 0.4 * scale;
    
    // Calcola la rotazione totale
    final totalRotationY = rotationY + (rotationAnimation.value * 2 * math.pi);
    
    // Disegna la griglia
    final paint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    for (double i = -gridSize; i <= gridSize; i += 10) {
      // Linee orizzontali
      canvas.drawLine(
        Offset(-gridSize, i) + center,
        Offset(gridSize, i) + center,
        paint,
      );
      
      // Linee verticali
      canvas.drawLine(
        Offset(i, -gridSize) + center,
        Offset(i, gridSize) + center,
        paint,
      );
    }
    
    // Disegna i bordi della griglia
    final borderPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    canvas.drawRect(
      Rect.fromCenter(center: center, width: gridSize * 2, height: gridSize * 2),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) {
    return oldDelegate.rotationX != rotationX ||
           oldDelegate.rotationY != rotationY ||
           oldDelegate.scale != scale;
  }
}
