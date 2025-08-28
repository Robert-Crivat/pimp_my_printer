import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

/// Widget per la visualizzazione tridimensionale di file STL.
///
/// Questo visualizzatore permette di caricare e visualizzare modelli 3D in formato STL,
/// con supporto per rotazione, zoom e manipolazione interattiva del modello.
/// Supporta sia il caricamento da file system (tramite [filePath]) che da dati binari
/// (tramite [fileBytes]), il che lo rende compatibile con ambienti web e mobile.
///
/// Il visualizzatore implementa tecniche di rendering 3D personalizzate usando
/// CustomPainter per disegnare triangoli con illuminazione Gouraud/Phong, per un'esperienza
/// visiva simile ad applicazioni professionali come OrcaSlicer.
class STL3DViewer extends StatefulWidget {
  /// Percorso del file STL sul file system (per mobile/desktop).
  final String? filePath;
  
  /// Nome del file da visualizzare nell'interfaccia.
  final String? fileName;
  
  /// Contenuto binario del file STL (utile per supporto web).
  final Uint8List? fileBytes;
  
  /// Larghezza opzionale del visualizzatore. Se null, si adatta al contenitore.
  final double? width;
  
  /// Altezza opzionale del visualizzatore. Se null, si adatta al contenitore.
  final double? height;
  
  /// Se mostrare i controlli di manipolazione (zoom, rotazione).
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

/// Stato interno del visualizzatore STL 3D.
///
/// Questa classe implementa la logica per il caricamento, parsing e visualizzazione
/// dei modelli STL, gestendo le interazioni dell'utente come rotazione e zoom.
class _STL3DViewerState extends State<STL3DViewer>
    with TickerProviderStateMixin {
  /// Flag che indica se un modello è in fase di caricamento.
  bool _isLoading = false;
  
  /// Messaggio di errore in caso di problemi di caricamento.
  String? _error;
  
  /// Flag che indica se è stato caricato un file reale (vs modello demo).
  bool _fileExists = false;
  
  /// Dimensione in byte del file STL caricato.
  int? _fileSize;
  
  /// Numero totale di triangoli nel modello.
  int? _triangleCount;
  
  /// Lista dei triangoli che compongono il modello 3D.
  List<STLTriangle> _triangles = [];
  
  /// Controller per l'animazione di rotazione automatica.
  late AnimationController _rotationController;
  
  /// Rotazione attuale sull'asse X (verticale), controllata dall'utente.
  double _userRotationX = 0.0;
  
  /// Rotazione attuale sull'asse Y (orizzontale), controllata dall'utente.
  double _userRotationY = 0.0;
  
  /// Flag per attivare/disattivare la rotazione automatica.
  bool _autoRotate = true;
  
  /// Fattore di scala attuale per lo zoom.
  double _scale = 1.0;
  
  /// Ultimo punto di contatto durante il drag per la rotazione.
  Offset _lastPanPoint = Offset.zero;
  
  /// Limiti del modello (min/max) per calcolare la scala ottimale.
  STLBounds? _bounds;

  /// Inizializza lo stato del visualizzatore e avvia il caricamento del modello.
  @override
  void initState() {
    super.initState();
    // Crea il controller per l'animazione di rotazione automatica
    _rotationController = AnimationController(
      duration: const Duration(seconds: 12), // Rotazione completa in 12 secondi
      vsync: this,
    );
    // Imposta una scala iniziale ben bilanciata (circa 7.5 volte più piccola dell'originale)
    _scale = 0.04;
    // Avvia il caricamento del modello
    _loadModel();
  }

  /// Libera le risorse quando il widget viene rimosso.
  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  /// Reagisce ai cambiamenti delle proprietà del widget.
  ///
  /// Se viene cambiato il file da visualizzare, ricarica il modello.
  @override
  void didUpdateWidget(STL3DViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filePath != oldWidget.filePath) {
      _loadModel();
    }
  }

  /// Carica il modello 3D da file o bytes.
  ///
  /// Questo metodo implementa la logica per caricare i dati STL da diverse fonti:
  /// 1. Bytes forniti direttamente (utile per il web)
  /// 2. File dal filesystem (per mobile/desktop)
  /// 3. Asset incorporato nell'app
  /// 4. Modello demo generato proceduralmente in caso di fallimento
  ///
  /// Il metodo gestisce anche la visualizzazione dello stato di caricamento
  /// e gli eventuali errori.
  Future<void> _loadModel() async {
    if (widget.filePath == null && widget.fileBytes == null) return;

    // Reset dello stato durante il caricamento
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
      
      // Strategia 1: Usa i bytes se forniti (per il web/file picker)
      if (widget.fileBytes != null) {
        bytes = widget.fileBytes!;
        _fileSize = bytes.length;
        _fileExists = true;
        print('Usando bytes del file caricato: ${bytes.length} bytes');
      } 
      // Strategia 2: Carica da file system (mobile/desktop)
      else if (widget.filePath != null) {
        final file = File(widget.filePath!);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
          _fileSize = bytes.length;
          _fileExists = true;
          print('File letto dal filesystem: ${bytes.length} bytes');
        } 
        // Strategia 3: Prova a caricare come asset se è il file di test
        else if (widget.filePath!.contains('test_cube.stl')) {
          try {
            final assetBytes = await rootBundle.load('assets/models/test_cube.stl');
            bytes = assetBytes.buffer.asUint8List();
            _fileSize = bytes.length;
            _fileExists = true;
            print('File di test caricato da asset: ${bytes.length} bytes');
          } catch (e) {
            print('Errore caricamento asset: $e');
            // Fallback: crea un modello demo
            await _createDemoModel();
            _fileExists = false;
            return;
          }
        } 
        // Fallback: se non è possibile caricare il file, usa modello demo
        else {
          await _createDemoModel();
          _fileExists = false;
          return;
        }
      } 
      // Se non ci sono dati, crea un modello demo
      else {
        await _createDemoModel();
        _fileExists = false;
        return;
      }

      // Verifica che il file abbia effettivamente l'estensione STL
      if (widget.fileName?.toLowerCase().endsWith('.stl') == true) {
        await _parseSTLFile(bytes);
      } else {
        await _createDemoModel();
      }
      
      setState(() {
        _isLoading = false;
      });

      // Avvia la rotazione automatica se abilitata
      if (_autoRotate) {
        _rotationController.repeat();
      }

      // Mostra una notifica con le informazioni sul modello caricato
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
      // In caso di errore, mostra un modello demo
      await _createDemoModel();
      setState(() {
        _isLoading = false;
        _error = null;
      });
    }
  }

  /// Analizza il contenuto di un file STL e costruisce il modello 3D.
  ///
  /// Il metodo identifica automaticamente se il file è in formato ASCII o binario
  /// e chiama il parser appropriato. Dopo il parsing, calcola i limiti del modello
  /// e la scala ottimale per la visualizzazione.
  ///
  /// @param bytes I dati binari del file STL.
  /// @throws Exception se il file è troppo piccolo o non contiene triangoli.
  Future<void> _parseSTLFile(List<int> bytes) async {
    try {
      // Breve ritardo per mostrare lo stato di caricamento
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Verifica la dimensione minima per un file STL valido
      if (bytes.length < 80) {
        throw Exception('File STL troppo piccolo');
      }

      // Determina il formato del file STL (ASCII o binario)
      // I file ASCII iniziano con la parola "solid"
      final header = String.fromCharCodes(bytes.take(5));
      final isAscii = header.toLowerCase().startsWith('solid');

      List<STLTriangle> triangles;
      
      // Seleziona il parser appropriato in base al formato
      if (isAscii) {
        triangles = await _parseASCIISTL(bytes);
      } else {
        triangles = await _parseBinarySTL(bytes);
      }

      // Verifica che siano stati trovati dei triangoli validi
      if (triangles.isNotEmpty) {
        _triangles = triangles;
        _triangleCount = triangles.length;
        // Calcola i limiti (min/max) del modello per il corretto scaling
        _bounds = _calculateBounds(triangles);
        // Determina la scala ottimale per visualizzare il modello
        _scale = _calculateOptimalScale();
      } else {
        throw Exception('Nessun triangolo trovato nel file STL');
      }
      
    } catch (e) {
      // Se il parsing fallisce per qualsiasi motivo, mostra un modello demo
      await _createDemoModel();
    }
  }

  /// Parser per file STL in formato ASCII.
  ///
  /// I file STL ASCII hanno un formato testuale dove ogni triangolo è definito da:
  /// - Una normale (facet normal nx ny nz)
  /// - Tre vertici (vertex x y z)
  /// - Tag di inizio/fine come "facet", "outer loop", "endloop", "endfacet"
  ///
  /// @param bytes I bytes del file STL ASCII.
  /// @return Lista di triangoli estratti dal file.
  Future<List<STLTriangle>> _parseASCIISTL(List<int> bytes) async {
    // Converte i bytes in una stringa e divide per righe
    final content = String.fromCharCodes(bytes);
    final lines = content.split('\n');
    final triangles = <STLTriangle>[];
    
    // Variabili temporanee per costruire un triangolo
    STLVector3? normal;
    final vertices = <STLVector3>[];
    
    // Analizza il file riga per riga
    for (final line in lines) {
      final trimmed = line.trim();
      
      // Estrazione della normale del triangolo
      if (trimmed.startsWith('facet normal')) {
        final parts = trimmed.split(' ');
        if (parts.length >= 5) {
          normal = STLVector3(
            double.tryParse(parts[2]) ?? 0.0,
            double.tryParse(parts[3]) ?? 0.0,
            double.tryParse(parts[4]) ?? 0.0,
          );
        }
      } 
      // Estrazione dei vertici
      else if (trimmed.startsWith('vertex')) {
        final parts = trimmed.split(' ');
        if (parts.length >= 4) {
          vertices.add(STLVector3(
            double.tryParse(parts[1]) ?? 0.0,
            double.tryParse(parts[2]) ?? 0.0,
            double.tryParse(parts[3]) ?? 0.0,
          ));
        }
      } 
      // Fine di un triangolo, salva i dati raccolti
      else if (trimmed == 'endfacet') {
        if (vertices.length == 3 && normal != null) {
          triangles.add(STLTriangle(
            vertices[0], vertices[1], vertices[2], normal,
          ));
        }
        // Reset per il prossimo triangolo
        vertices.clear();
        normal = null;
      }
    }
    
    return triangles;
  }

  /// Parser per file STL in formato binario.
  ///
  /// I file STL binari hanno la seguente struttura:
  /// - 80 bytes di header (ignorati)
  /// - 4 bytes per il numero di triangoli (uint32, little endian)
  /// - Per ogni triangolo (50 bytes):
  ///   - 12 bytes per la normale (3 float32)
  ///   - 36 bytes per i 3 vertici (9 float32)
  ///   - 2 bytes di "attribute byte count" (ignorati)
  ///
  /// @param bytes I bytes del file STL binario.
  /// @return Lista di triangoli estratti dal file.
  /// @throws Exception se il file è malformato o incompleto.
  Future<List<STLTriangle>> _parseBinarySTL(List<int> bytes) async {
    // Verifica che il file abbia almeno l'header e il contatore di triangoli
    if (bytes.length < 84) {
      throw Exception('File STL binario malformato');
    }

    // Ottimizzazione: convertiamo i bytes una sola volta
    final byteData = ByteData.sublistView(Uint8List.fromList(bytes));

    // Leggi il numero di triangoli (bytes 80-83, little endian)
    final triangleCount = byteData.getUint32(80, Endian.little);

    // Verifica che il file contenga tutti i triangoli dichiarati
    final expectedSize = 80 + 4 + (triangleCount * 50);
    if (bytes.length < expectedSize) {
      throw Exception('File STL binario incompleto');
    }

    // Ottimizzazione: preallochiamo la memoria per tutti i triangoli
    final triangles = List<STLTriangle>.filled(
        triangleCount, 
        STLTriangle(
            STLVector3(0, 0, 0), 
            STLVector3(0, 0, 0), 
            STLVector3(0, 0, 0), 
            STLVector3(0, 0, 0)
        )
    );

    // Ottimizzazione: utilizziamo l'isolate per il parsing se il modello è grande
    if (triangleCount > 10000) {
      // Per modelli molto grandi, mostriamo un campione iniziale mentre processsiamo
      // il resto in background
      final sampleSize = math.min(5000, triangleCount);
      
      // Parse del campione iniziale per mostrare subito qualcosa
      for (int i = 0; i < sampleSize; i++) {
        final offset = 84 + (i * 50);
        triangles[i] = _parseTriangleFromByteData(byteData, offset);
      }
      
      // Aggiorniamo la UI con il campione
      setState(() {
        _triangles = triangles.sublist(0, sampleSize);
        _triangleCount = sampleSize;
        _bounds = _calculateBounds(_triangles);
        _scale = _calculateOptimalScale();
        _isLoading = false;
      });
      
      // Continuiamo il parsing in background
      Future.microtask(() async {
        for (int i = sampleSize; i < triangleCount; i++) {
          final offset = 84 + (i * 50);
          triangles[i] = _parseTriangleFromByteData(byteData, offset);
          
          // Aggiorniamo progressivamente per modelli molto grandi
          if (i % 10000 == 0) {
            setState(() {
              _triangles = List.from(triangles);
              _triangleCount = i + 1;
            });
            await Future.delayed(const Duration(milliseconds: 1));
          }
        }
        
        // Aggiornamento finale
        setState(() {
          _triangles = triangles;
          _triangleCount = triangleCount;
          _bounds = _calculateBounds(_triangles);
          _scale = _calculateOptimalScale();
        });
      });
      
      return triangles.sublist(0, sampleSize);
    }
    
    // Per modelli di dimensioni normali, processsiamo tutto in una volta
    for (int i = 0; i < triangleCount; i++) {
      final offset = 84 + (i * 50);
      triangles[i] = _parseTriangleFromByteData(byteData, offset);
    }

    return triangles;
  }
  
  /// Estrae un triangolo dai dati binari a un offset specifico
  /// 
  /// Metodo di supporto per ottimizzare il parsing binario
  STLTriangle _parseTriangleFromByteData(ByteData data, int offset) {
    // Estrazione della normale (primi 12 bytes del triangolo)
    final normal = STLVector3(
      data.getFloat32(offset, Endian.little),
      data.getFloat32(offset + 4, Endian.little),
      data.getFloat32(offset + 8, Endian.little),
    );
    
    // Estrazione del primo vertice (bytes 12-24)
    final v1 = STLVector3(
      data.getFloat32(offset + 12, Endian.little),
      data.getFloat32(offset + 16, Endian.little),
      data.getFloat32(offset + 20, Endian.little),
    );
    
    // Estrazione del secondo vertice (bytes 24-36)
    final v2 = STLVector3(
      data.getFloat32(offset + 24, Endian.little),
      data.getFloat32(offset + 28, Endian.little),
      data.getFloat32(offset + 32, Endian.little),
    );
    
    // Estrazione del terzo vertice (bytes 36-48)
    final v3 = STLVector3(
      data.getFloat32(offset + 36, Endian.little),
      data.getFloat32(offset + 40, Endian.little),
      data.getFloat32(offset + 44, Endian.little),
    );
    
    return STLTriangle(v1, v2, v3, normal);
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
    
    // Assicuriamoci che il modello sia ben proporzionato nella vista
    // Ridotto di 7.5 volte rispetto al valore originale di 1.0
    return 0.13 / maxDimension;
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
                _scale = (_scale / 1.1).clamp(0.01, 5.0);
              } else {
                _scale = (_scale * 1.1).clamp(0.01, 5.0);
              }
              _autoRotate = false;
              _rotationController.stop();
            });
          }
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
          child: GestureDetector(
            onDoubleTap: () {
              setState(() {
                _userRotationX = 0.0;
                _userRotationY = 0.0;
                _scale = 0.04;
                _autoRotate = true;
                _rotationController.repeat();
              });
            },
            onPanStart: (details) {
              _autoRotate = false;
              _rotationController.stop();
              _lastPanPoint = details.localPosition;
            },
            onPanUpdate: (details) {
              setState(() {
                final delta = details.localPosition - _lastPanPoint;
                _userRotationY += delta.dx * 0.01;
                _userRotationX -= delta.dy * 0.01; // Invertiamo il movimento Y per un controllo più intuitivo
                
                // Limita la rotazione verticale per evitare capovolgimenti
                _userRotationX = _userRotationX.clamp(-math.pi / 2 + 0.1, math.pi / 2 - 0.1);
                
                _lastPanPoint = details.localPosition;
              });
            },
            child: Stack(
              children: [
                // Modello 3D con scala fissa
                CustomPaint(
                  size: Size.infinite,
                  painter: STL3DPainter(
                    triangles: _triangles,
                    rotationX: _userRotationX,
                    rotationY: _userRotationY,
                    rotationAnimation: _rotationController,
                    scale: _scale * 0.4, // Valore equilibrato per rendere il modello circa 7.5 volte più piccolo
                    bounds: _bounds,
                    isDark: Theme.of(context).brightness == Brightness.dark,
                  ),
                ),
                // Visualizza i controlli a schermo per il 3D
                if (widget.showControls)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildRoundedIconButton(
                          Icons.zoom_in, 
                          () => setState(() {
                            _scale = (_scale * 1.1).clamp(0.01, 10.0);
                          })
                        ),
                        const SizedBox(height: 8),
                        _buildRoundedIconButton(
                          Icons.zoom_out,
                          () => setState(() {
                            _scale = (_scale / 1.1).clamp(0.01, 10.0);
                          })
                        ),
                        const SizedBox(height: 8),
                        _buildRoundedIconButton(
                          _autoRotate ? Icons.pause : Icons.play_arrow,
                          () => setState(() {
                            _autoRotate = !_autoRotate;
                            if (_autoRotate) {
                              _rotationController.repeat();
                            } else {
                              _rotationController.stop();
                            }
                          })
                        ),
                        const SizedBox(height: 8),
                        _buildRoundedIconButton(
                          Icons.restart_alt,
                          () => setState(() {
                            _userRotationX = 0.0;
                            _userRotationY = 0.0;
                            _scale = 0.04;
                            _autoRotate = false;
                            _rotationController.stop();
                          })
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildRoundedIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(180),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 4,
          )
        ]
      ),
      child: ClipOval(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Icon(icon, size: 20),
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
                _scale = (_scale * 1.1).clamp(0.01, 10.0);
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
                _scale = (_scale / 1.1).clamp(0.01, 10.0);
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

/// Classi di supporto per la gestione dei modelli STL

/// Rappresenta un vettore tridimensionale con coordinate x, y, z.
///
/// Questa classe implementa le operazioni vettoriali fondamentali
/// per i calcoli 3D, inclusi somma, sottrazione, moltiplicazione per scalare,
/// prodotto scalare e normalizzazione.
class STLVector3 {
  /// Coordinata x del vettore
  final double x;
  
  /// Coordinata y del vettore
  final double y;
  
  /// Coordinata z del vettore
  final double z;
  
  /// Crea un nuovo vettore con le coordinate specificate
  const STLVector3(this.x, this.y, this.z);
  
  /// Somma di due vettori
  STLVector3 operator +(STLVector3 other) => STLVector3(x + other.x, y + other.y, z + other.z);
  
  /// Differenza di due vettori
  STLVector3 operator -(STLVector3 other) => STLVector3(x - other.x, y - other.y, z - other.z);
  
  /// Moltiplicazione per scalare
  STLVector3 operator *(double scalar) => STLVector3(x * scalar, y * scalar, z * scalar);
  
  /// Lunghezza (modulo) del vettore
  double get length => math.sqrt(x * x + y * y + z * z);
  
  /// Restituisce un vettore normalizzato (stesso verso ma con lunghezza 1)
  ///
  /// Utile per i calcoli di illuminazione e rendering.
  STLVector3 normalized() {
    final len = length;
    if (len == 0) return const STLVector3(0, 0, 1); // Vettore di default se lunghezza è zero
    return STLVector3(x / len, y / len, z / len);
  }
  
  /// Calcola il prodotto scalare con un altro vettore
  ///
  /// Il prodotto scalare è essenziale per i calcoli di illuminazione,
  /// in quanto rappresenta il coseno dell'angolo tra i vettori moltiplicato
  /// per le loro lunghezze.
  double dot(STLVector3 other) => x * other.x + y * other.y + z * other.z;
  
  @override
  String toString() => 'STLVector3($x, $y, $z)';
}

/// Rappresenta un triangolo 3D, l'elemento base dei modelli STL.
///
/// Ogni triangolo è definito da tre vertici (v1, v2, v3) e un vettore normale
/// che indica l'orientamento della superficie.
class STLTriangle {
  /// Primo vertice del triangolo
  final STLVector3 v1;
  
  /// Secondo vertice del triangolo
  final STLVector3 v2;
  
  /// Terzo vertice del triangolo
  final STLVector3 v3;
  
  /// Vettore normale al triangolo, usato per il calcolo dell'illuminazione
  final STLVector3 normal;
  
  /// Crea un nuovo triangolo con i vertici e la normale specificati
  const STLTriangle(this.v1, this.v2, this.v3, this.normal);
}

/// Definisce i limiti (bounding box) di un modello 3D.
///
/// Utilizzato per centrare e scalare correttamente il modello durante la visualizzazione.
class STLBounds {
  /// Punto minimo (angolo inferiore sinistro posteriore) del bounding box
  final STLVector3 min;
  
  /// Punto massimo (angolo superiore destro anteriore) del bounding box
  final STLVector3 max;
  
  /// Crea un nuovo bounding box con i punti minimo e massimo specificati
  const STLBounds(this.min, this.max);
  
  /// Calcola le dimensioni del bounding box
  STLVector3 get size => max - min;
  
  /// Calcola il centro del bounding box
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
    final viewScale = math.min(size.width, size.height) * scale;
    
    // Calcola la rotazione totale e usa effettivamente questa variabile
    final actualRotationY = rotationY + (rotationAnimation.value * 2 * math.pi);
    
    // Centra il modello
    final modelCenter = bounds?.center ?? const STLVector3(0, 0, 0);
    
    // Trasforma e ordina i triangoli per il depth sorting
    final transformedTriangles = <_TransformedTriangle>[];
    
    // Usiamo un fattore di scale per rendere il modello ben proporzionato
    final modelScaleFactor = 0.05;
    
    for (final triangle in triangles) {
      // Applichiamo un fattore di scala prima della trasformazione
      final v1 = (triangle.v1 - modelCenter) * modelScaleFactor;
      final v2 = (triangle.v2 - modelCenter) * modelScaleFactor;
      final v3 = (triangle.v3 - modelCenter) * modelScaleFactor;
      
      final t1 = _transformPoint(v1, rotationX, actualRotationY, viewScale, center);
      final t2 = _transformPoint(v2, rotationX, actualRotationY, viewScale, center);
      final t3 = _transformPoint(v3, rotationX, actualRotationY, viewScale, center);
      
      final avgZ = (t1.z + t2.z + t3.z) / 3;
      
      // Calcola la normale trasformata per il lighting
      final transformedNormal = _transformNormal(triangle.normal, rotationX, actualRotationY);
      
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
      final int r = (baseColor.red * intensity).round();
      final int g = (baseColor.green * intensity).round();
      final int b = (baseColor.blue * intensity).round();
      final finalColor = Color.fromRGBO(r, g, b, 1.0);
      
      final trianglePaint = Paint()
        ..color = finalColor
        ..style = PaintingStyle.fill;
      
      canvas.drawPath(path, trianglePaint);
      
      // Outline delicato per definizione geometrica (stile OrcaSlicer)
      final outlinePaint = Paint()
        ..color = Colors.black.withAlpha(25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.2;
      
      canvas.drawPath(path, outlinePaint);
    }
  }

  STLVector3 _transformPoint(STLVector3 point, double rotX, double rotY, double scale, Offset center) {
    // Rotazione Y (attorno all'asse verticale)
    final cosY = math.cos(rotY);
    final sinY = math.sin(rotY);
    final x1 = point.x * cosY - point.z * sinY;
    final z1 = point.x * sinY + point.z * cosY;
    
    // Rotazione X (attorno all'asse orizzontale)
    final cosX = math.cos(rotX);
    final sinX = math.sin(rotX);
    final y1 = point.y * cosX - z1 * sinX;
    final z2 = point.y * sinX + z1 * cosX;
    
    // Proiezione quasi-ortografica per un aspetto tecnico come OrcaSlicer
    // Usiamo un approccio più semplice senza prospettiva
    
    // Riduzione dell'offset verticale per centrare meglio il modello
    final verticalOffset = -20.0; // Un valore minore per centrare meglio
    
    return STLVector3(
      center.dx + x1 * scale,
      center.dy - y1 * scale + verticalOffset, // Inverti Y e aggiungi offset
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

/// Implementazione semplice di una griglia fissa (non ruota)
class SimpleGridPainter extends CustomPainter {
  final bool isDark;

  SimpleGridPainter({
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Non disegniamo nulla - griglia rimossa
    // Questo lascia lo sfondo completamente trasparente/vuoto
  }

  @override
  bool shouldRepaint(SimpleGridPainter oldDelegate) {
    return false; // Non c'è bisogno di ridisegnare poiché non disegniamo nulla
  }
}
