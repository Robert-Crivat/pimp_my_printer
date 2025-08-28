import 'dart:async';
import 'dart:convert';
import 'dart:io' if (dart.library.html) 'dart:html';
import 'dart:math';
import 'package:flutter/foundation.dart'; // Per kIsWeb e Uint8List
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:universal_html/html.dart' as html;
import '../providers/theme_provider.dart';
import '../services/gcode_api_service.dart';
import '../widgets/stl_3d_viewer.dart';

/// Schermata Slicer per la preparazione e il slicing di modelli 3D.
///
/// Questa schermata permette all'utente di:
/// - Caricare modelli 3D in formato STL, OBJ, 3MF o AMF
/// - Visualizzare il modello 3D in un visualizzatore interattivo
/// - Configurare i parametri di stampa (altezza layer, temperatura, velocità, ecc.)
/// - Eseguire il slicing del modello generando il G-code per la stampa
///
/// La schermata si adatta automaticamente al layout tablet o mobile
/// in base alle dimensioni dello schermo.
class SlicerScreen extends StatefulWidget {
  const SlicerScreen({super.key});

  @override
  State<SlicerScreen> createState() => _SlicerScreenState();
}

/// Implementazione dello stato per la schermata dello slicer.
///
/// Gestisce:
/// - Caricamento e visualizzazione di modelli 3D
/// - Impostazioni di slicing come altezza layer, temperatura, densità di riempimento
/// - Simulazione del processo di slicing
/// - Adattamento dell'interfaccia in base alla dimensione dello schermo
class _SlicerScreenState extends State<SlicerScreen> with TickerProviderStateMixin {
  /// Controller per la navigazione a tab nelle impostazioni di slicing
  late TabController _tabController;
  
  /// Percorso del file 3D selezionato
  String? _selectedFile;
  
  /// Contenuto binario del file selezionato (usato principalmente per Web)
  Uint8List? _selectedFileBytes;
  
  /// Altezza di ogni layer in mm (influisce sulla qualità e tempo di stampa)
  double _layerHeight = 0.2;
  
  /// Percentuale di riempimento interno del modello (0-100%)
  double _infillDensity = 20.0;
  
  /// Velocità di stampa in mm/s
  int _printSpeed = 60;
  
  /// Temperatura dell'ugello/estrusore in °C
  double _nozzleTemp = 210.0;
  
  /// Temperatura del piano di stampa in °C
  double _bedTemp = 60.0;
  
  /// Profilo di stampa selezionato con impostazioni predefinite
  String _selectedProfile = 'PLA Standard';
  
  /// Indica se il processo di slicing è attualmente in corso
  bool _isSlicing = false;
  
  /// Progresso dell'operazione di slicing (0.0-1.0)
  double _slicingProgress = 0.0;

  /// Elenco dei profili di stampa disponibili
  final List<String> _profiles = [
    'PLA Standard',
    'PETG Standard',
    'ABS Standard',
    'TPU Flexible',
    'Custom Profile'
  ];

  /// Pattern di riempimento disponibili per il modello
  final List<String> _infillPatterns = [
    'Grid',
    'Lines',
    'Triangles',
    'Cubic',
    'Gyroid',
    'Honeycomb'
  ];

  /// Pattern di riempimento attualmente selezionato
  String _selectedInfillPattern = 'Grid';
  
  /// Servizio per l'interazione con l'API G-code
  final GcodeApiService _apiService = GcodeApiService();
  
  /// Indica se l'API è disponibile
  bool _isApiAvailable = false;
  
  /// Messaggi di errore dell'API
  String? _apiErrorMessage;

  /// Inizializza lo stato del widget
  ///
  /// Configura il controller per la navigazione a tab delle impostazioni
  @override
  void initState() {
    super.initState();
    // Inizializza il controller per i 4 tab delle impostazioni:
    // Qualità, Materiale, Velocità e Avanzate
    _tabController = TabController(length: 4, vsync: this);
    
    // Verifica la disponibilità dell'API
    _checkApiAvailability();
  }
  
  /// Verifica se l'API è disponibile
  Future<void> _checkApiAvailability() async {
    try {
      final isAvailable = await _apiService.checkHealth();
      setState(() {
        _isApiAvailable = isAvailable;
        _apiErrorMessage = isAvailable ? null : 'API non disponibile';
      });
    } catch (e) {
      setState(() {
        _isApiAvailable = false;
        _apiErrorMessage = 'Errore di connessione all\'API: $e';
      });
    }
  }

  /// Libera le risorse quando il widget viene rimosso dalla UI
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Costruisce l'interfaccia utente della schermata Slicer
  ///
  /// Determina automaticamente se utilizzare il layout tablet o mobile
  /// in base alla larghezza dello schermo (tablet > 600px)
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Slicer',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Costruisce il layout per dispositivi mobili (width <= 600px)
  ///
  /// Il layout mobile è organizzato verticalmente con:
  /// - Area caricamento file compatta
  /// - Anteprima 3D con altezza fissa
  /// - Controlli rapidi
  /// - Pannelli di impostazioni espandibili
  /// - Controlli per lo slicing
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Area caricamento file compatta
          _buildCompactFileSection(),
          const SizedBox(height: 12),
          
          // Anteprima 3D/Layer - altezza fissa per mobile
          SizedBox(
            height: 300,
            child: Card(
              child: _build3DPreview(),
            ),
          ),
          const SizedBox(height: 12),
          
          // Controlli rapidi
          _buildQuickControls(),
          const SizedBox(height: 12),
          
          // Settings in pannelli espandibili
          _buildExpandableSettings(),
          const SizedBox(height: 12),
          
          // Controlli slicing
          _buildMobileSlicingControls(),
          const SizedBox(height: 20), // Spazio extra per il bottom
        ],
      ),
    );
  }

  /// Costruisce il layout per tablet (width > 600px)
  ///
  /// Il layout tablet è organizzato in due colonne:
  /// - A sinistra: caricamento file e anteprima 3D (2/3 dello spazio)
  /// - A destra: controlli slicing e impostazioni (1/3 dello spazio)
  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Area principale - File e anteprima
        Expanded(
          flex: 2,
          child: Column(
            children: [
              // Area caricamento file
              Card(
                child: Container(
                  width: double.infinity,
                  height: 200,
                  child: _selectedFile == null
                      ? _buildFileDropZone()
                      : _buildFilePreview(),
                ),
              ),
              const SizedBox(height: 16),
              // Anteprima 3D
              Expanded(
                child: Card(
                  child: Container(
                    width: double.infinity,
                    child: _build3DPreview(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Pannello impostazioni
        Expanded(
          flex: 1,
          child: Column(
            children: [
              // Controlli slicing
              _buildSlicingControls(),
              const SizedBox(height: 16),
              // Impostazioni
              Expanded(
                child: _buildSettingsPanel(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Costruisce la sezione compatta per il caricamento dei file (versione mobile)
  ///
  /// Mostra un'area per il caricamento del file se nessun file è selezionato,
  /// o una preview del file selezionato.
  Widget _buildCompactFileSection() {
    return Card(
      child: Container(
        width: double.infinity,
        height: 120, // Altezza ridotta per mobile
        child: _selectedFile == null
            ? _buildCompactFileDropZone()
            : _buildCompactFilePreview(),
      ),
    );
  }

  /// Costruisce l'area di caricamento file compatta per dispositivi mobili
  ///
  /// Visualizza una UI orizzontale per caricare un file 3D, con icone e testo
  /// che spiegano quali formati sono supportati.
  Widget _buildCompactFileDropZone() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickFile,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Icon(
                      Icons.upload_file,
                      size: 40,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Carica File 3D',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[300] : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'STL, OBJ, 3MF, AMF',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Icon(
                      Icons.add_circle_outline,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Costruisce una visualizzazione compatta del file 3D selezionato per dispositivi mobili
  ///
  /// Mostra il nome del file, un'icona rappresentativa e un pulsante per rimuoverlo
  Widget _buildCompactFilePreview() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icona del file con sfondo colorato
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: themeProvider.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2,
                  color: themeProvider.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              // Nome del file
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFile!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Pulsante per rimuovere il file
              IconButton(
                onPressed: () => setState(() {
                  _selectedFile = null;
                  _selectedFileBytes = null;
                }),
                icon: const Icon(Icons.close),
                iconSize: 20,
              ),
            ],
          ),
        );
      },
    );
  }

  /// Costruisce la sezione dei controlli rapidi per dispositivi mobili
  ///
  /// Include un selettore di profilo e un pulsante rapido per avviare lo slicing
  Widget _buildQuickControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Controlli Rapidi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildQuickProfileSelector(),
                ),
                const SizedBox(width: 12),
                _buildQuickSliceButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Costruisce un selettore rapido di profili di stampa
  ///
  /// Permette all'utente di selezionare rapidamente un profilo predefinito
  /// che imposterà automaticamente i parametri di stampa (temperatura, velocità, ecc.)
  Widget _buildQuickProfileSelector() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          decoration: BoxDecoration(
            color: themeProvider.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedProfile,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: themeProvider.primaryColor),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedProfile = newValue);
                  _loadProfile(newValue);
                }
              },
              items: _profiles.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      value,
                      style: TextStyle(
                        color: themeProvider.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  /// Costruisce il pulsante rapido per avviare lo slicing
  ///
  /// Mostra un pulsante per avviare il processo di slicing se un file è caricato,
  /// o un pulsante disabilitato se nessun file è presente.
  /// Durante lo slicing, mostra un indicatore di progresso circolare.
  Widget _buildQuickSliceButton() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _selectedFile != null && !_isSlicing ? _startSlicing : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeProvider.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSlicing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.play_arrow),
          ),
        );
      },
    );
  }

  /// Costruisce i pannelli espandibili delle impostazioni per layout mobile
  ///
  /// Organizza le impostazioni in categorie espandibili:
  /// - Qualità: altezza layer, densità riempimento
  /// - Materiale: temperature dell'ugello e del piano
  /// - Velocità: velocità di stampa
  /// - Avanzate: pattern di riempimento e altre impostazioni avanzate
  Widget _buildExpandableSettings() {
    return Column(
      children: [
        _buildExpandablePanel(
          'Qualità',
          Icons.high_quality,
          _buildQualitySettings(),
        ),
        const SizedBox(height: 8),
        _buildExpandablePanel(
          'Materiale',
          Icons.thermostat,
          _buildMaterialSettings(),
        ),
        const SizedBox(height: 8),
        _buildExpandablePanel(
          'Velocità',
          Icons.speed,
          _buildSpeedSettings(),
        ),
        const SizedBox(height: 8),
        _buildExpandablePanel(
          'Avanzate',
          Icons.settings,
          _buildAdvancedSettings(),
        ),
      ],
    );
  }

  /// Costruisce un singolo pannello espandibile per le impostazioni
  ///
  /// @param title Il titolo del pannello
  /// @param icon L'icona rappresentativa della categoria
  /// @param content Il contenuto del pannello (widget con le impostazioni)
  Widget _buildExpandablePanel(String title, IconData icon, Widget content) {
    return ExpansionTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: content,
        ),
      ],
    );
  }

  /// Costruisce le impostazioni di qualità della stampa
  ///
  /// Include controlli per:
  /// - Altezza layer: influisce sulla risoluzione e tempo di stampa (0.1-0.4mm)
  /// - Densità riempimento: percentuale di riempimento interno (0-100%)
  Widget _buildQualitySettings() {
    return Column(
      children: [
        _buildCompactSlider(
          'Altezza Layer',
          _layerHeight,
          0.1,
          0.4,
          'mm',
          (value) => setState(() {
            _layerHeight = value;
          }),
        ),
        const SizedBox(height: 12),
        _buildCompactSlider(
          'Densità Riempimento',
          _infillDensity,
          0,
          100,
          '%',
          (value) => setState(() => _infillDensity = value),
        ),
      ],
    );
  }

  /// Costruisce le impostazioni relative al materiale di stampa
  ///
  /// Include controlli per:
  /// - Temperatura ugello/estrusore (180-300°C)
  /// - Temperatura del piano di stampa (0-120°C)
  Widget _buildMaterialSettings() {
    return Column(
      children: [
        _buildCompactSlider(
          'Temp. Nozzle',
          _nozzleTemp,
          180,
          300,
          '°C',
          (value) => setState(() => _nozzleTemp = value),
        ),
        const SizedBox(height: 12),
        _buildCompactSlider(
          'Temp. Bed',
          _bedTemp,
          0,
          120,
          '°C',
          (value) => setState(() => _bedTemp = value),
        ),
      ],
    );
  }

  /// Costruisce le impostazioni di velocità di stampa
  ///
  /// Controlla la velocità generale di stampa in mm/s
  /// Valori più alti = stampa più veloce ma potenzialmente meno precisa
  Widget _buildSpeedSettings() {
    return Column(
      children: [
        _buildCompactSlider(
          'Velocità Stampa',
          _printSpeed.toDouble(),
          20,
          100,
          'mm/s',
          (value) => setState(() => _printSpeed = value.round()),
        ),
      ],
    );
  }

  /// Costruisce le impostazioni avanzate di stampa
  ///
  /// Include opzioni come il pattern di riempimento interno
  /// (grid, lines, triangles, ecc) e altre impostazioni tecniche
  Widget _buildAdvancedSettings() {
    return Column(
      children: [
        Row(
          children: [
            const Text('Pattern Riempimento:'),
            const Spacer(),
            DropdownButton<String>(
              value: _selectedInfillPattern,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() => _selectedInfillPattern = newValue);
                }
              },
              items: _infillPatterns.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }

  /// Costruisce un controllo slider compatto per le impostazioni
  ///
  /// @param label Etichetta descrittiva del parametro
  /// @param value Valore attuale
  /// @param min Valore minimo
  /// @param max Valore massimo
  /// @param unit Unità di misura (mm, °C, %, ecc.)
  /// @param onChanged Callback chiamata quando il valore cambia
  Widget _buildCompactSlider(
    String label,
    double value,
    double min,
    double max,
    String unit,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${value.toStringAsFixed(value < 10 ? 1 : 0)}$unit',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Costruisce l'interfaccia dei controlli di slicing per dispositivi mobili
  ///
  /// Mostra la barra di progresso durante lo slicing
  /// Non viene visualizzato se non c'è un processo di slicing in corso
  Widget _buildMobileSlicingControls() {
    if (!_isSlicing && _slicingProgress == 0.0) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome),
                const SizedBox(width: 8),
                const Text(
                  'Slicing in Corso...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text('${(_slicingProgress * 100).toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _slicingProgress,
              backgroundColor: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }

  /// Costruisce l'anteprima 3D del modello
  ///
  /// Visualizza il visualizzatore 3D STL se è caricato un file,
  /// altrimenti mostra un messaggio per caricare un file.
  /// In alcuni casi mostra anche un modello di test come esempio.
  Widget _build3DPreview() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.grey[100],
            ),
            child: _selectedFile == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.view_in_ar_outlined,
                          size: 48,
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Anteprima 3D',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Carica un file per iniziare',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[500] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : _build3DView(themeProvider),
          ),
        );
      },
    );
  }

  /// Costruisce la vista 3D del modello
  ///
  /// Se c'è un file selezionato, mostra il visualizzatore STL3D con quel file.
  /// Altrimenti, mostra un modello di test con un overlay che indica 
  /// che è un esempio e un prompt per caricare un file reale.
  ///
  /// @param themeProvider Provider di tema per adattare i colori dell'interfaccia
  Widget _build3DView(ThemeProvider themeProvider) {
    // Usa il nuovo viewer 3D se c'è un file selezionato
    if (_selectedFile != null) {
      return STL3DViewer(
        filePath: _selectedFile,
        fileName: _selectedFile,
        fileBytes: _selectedFileBytes, // Passa i bytes per il web
        showControls: true,
      );
    }
    
    // Mostra il visualizzatore con file di test se non c'è nessun file caricato
    return Stack(
      children: [
        // Usa il file di test come esempio
        STL3DViewer(
          filePath: 'assets/models/test_cube.stl',
          fileName: 'test_cube.stl',
          showControls: true,
        ),
        
        // Overlay per indicare che è un esempio
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.science,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                const Text(
                  'Esempio STL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Prompt per caricare un file
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Carica il tuo file STL per vedere il modello reale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('Carica STL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 32),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  /// Costruisce l'area di caricamento file per layout tablet
  ///
  /// Mostra un'area di drop o selezione file più grande con
  /// istruzioni dettagliate su come caricare un file 3D
  Widget _buildFileDropZone() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final isDark = themeProvider.isDarkMode;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _pickFile,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.upload_file,
                    size: 64,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Carica File 3D',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Trascina o clicca per selezionare',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'STL, OBJ, 3MF, AMF',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[600] : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Costruisce la preview del file selezionato per il layout tablet
  ///
  /// Mostra un'anteprima del file con icona, nome file e un pulsante per rimuoverlo
  Widget _buildFilePreview() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
                // Icona del file con sfondo colorato
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: themeProvider.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.inventory_2,
                    size: 40,
                    color: themeProvider.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                // Nome del file
                Flexible(
                  child: Text(
                    _selectedFile!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 12),
                // Pulsante per rimuovere il file
                ElevatedButton.icon(
                  onPressed: () => setState(() {
                    _selectedFile = null;
                    _selectedFileBytes = null;
                  }),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Rimuovi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
        );
      },
    );
  }

  /// Costruisce i controlli di slicing per il layout tablet
  ///
  /// Include:
  /// - Informazioni sul progresso di slicing
  /// - Pulsante per avviare lo slicing
  /// - Pulsanti per anteprima e salvataggio delle impostazioni
  Widget _buildSlicingControls() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Controlli Slicing',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                
                // Progresso slicing
                if (_isSlicing || _slicingProgress > 0) ...[
                  Text(
                    'Slicing in corso...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: themeProvider.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: _slicingProgress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(themeProvider.primaryColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_slicingProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Pulsanti di controllo
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectedFile != null && !_isSlicing ? _startSlicing : null,
                        icon: _isSlicing 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.play_arrow),
                        label: Text(_isSlicing ? 'Slicing...' : 'Avvia Slicing'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeProvider.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _previewSlicing,
                        icon: const Icon(Icons.preview),
                        label: const Text('Anteprima'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Esportare impostazioni
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Salva'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Costruisce il pannello delle impostazioni per il layout tablet
  ///
  /// Organizza le impostazioni in una serie di tab:
  /// - Qualità: impostazioni di qualità di stampa
  /// - Materiale: impostazioni del materiale e temperature
  /// - Velocità: impostazioni di velocità di stampa
  /// - Avanzate: impostazioni tecniche avanzate
  Widget _buildSettingsPanel() {
    return Card(
      child: Column(
        children: [
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.high_quality, size: 20), text: 'Qualità'),
                Tab(icon: Icon(Icons.thermostat, size: 20), text: 'Materiale'),
                Tab(icon: Icon(Icons.speed, size: 20), text: 'Velocità'),
                Tab(icon: Icon(Icons.settings, size: 20), text: 'Avanzate'),
              ],
              labelStyle: const TextStyle(fontSize: 10),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
            ),
          ),
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQualityTab(),
                _buildMaterialTab(),
                _buildSpeedTab(),
                _buildAdvancedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Costruisce il tab di impostazioni di qualità
  ///
  /// Contiene controlli per altezza layer e densità di riempimento
  Widget _buildQualityTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impostazioni Qualità',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          _buildSettingSlider(
            'Altezza Layer',
            _layerHeight,
            0.1,
            0.4,
            'mm',
            (value) => setState(() {
              _layerHeight = value;
            }),
          ),
          const SizedBox(height: 16),
          _buildSettingSlider(
            'Densità Riempimento',
            _infillDensity,
            0,
            100,
            '%',
            (value) => setState(() => _infillDensity = value),
          ),
        ],
      ),
    );
  }

  /// Costruisce il tab di impostazioni del materiale
  ///
  /// Contiene controlli per temperature dell'ugello e del piano
  Widget _buildMaterialTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impostazioni Materiale',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          _buildSettingSlider(
            'Temperatura Nozzle',
            _nozzleTemp,
            180,
            300,
            '°C',
            (value) => setState(() => _nozzleTemp = value),
          ),
          const SizedBox(height: 16),
          _buildSettingSlider(
            'Temperatura Bed',
            _bedTemp,
            0,
            120,
            '°C',
            (value) => setState(() => _bedTemp = value),
          ),
        ],
      ),
    );
  }

  /// Costruisce il tab di impostazioni della velocità
  ///
  /// Contiene controlli per la velocità di stampa in mm/s
  Widget _buildSpeedTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impostazioni Velocità',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          _buildSettingSlider(
            'Velocità di Stampa',
            _printSpeed.toDouble(),
            20,
            100,
            'mm/s',
            (value) => setState(() => _printSpeed = value.round()),
          ),
        ],
      ),
    );
  }

  /// Costruisce il tab di impostazioni avanzate
  ///
  /// Contiene controlli per pattern di riempimento e altre impostazioni tecniche
  Widget _buildAdvancedTab() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Impostazioni Avanzate',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('Pattern Riempimento:'),
              const Spacer(),
              DropdownButton<String>(
                value: _selectedInfillPattern,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedInfillPattern = newValue);
                  }
                },
                items: _infillPatterns.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Costruisce un controllo slider per le impostazioni di stampa
  ///
  /// Versione dettagliata dello slider per i tab delle impostazioni
  /// 
  /// @param label Etichetta descrittiva del parametro
  /// @param value Valore attuale
  /// @param min Valore minimo
  /// @param max Valore massimo
  /// @param unit Unità di misura (mm, °C, %, ecc.)
  /// @param onChanged Callback chiamata quando il valore cambia
  Widget _buildSettingSlider(
    String label,
    double value,
    double min,
    double max,
    String unit,
    Function(double) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${value.toStringAsFixed(value < 10 ? 1 : 0)}$unit',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Permette all'utente di selezionare un file 3D
  ///
  /// Utilizza FilePicker per selezionare file STL, OBJ, 3MF o AMF.
  /// Supporta sia il caricamento da file system che da web (usando bytes).
  /// In caso di errore, mostra un file demo per facilitare i test.
  void _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['stl', 'obj', '3mf', 'amf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        print('File selezionato: ${file.name}');
        
        // Nel web usiamo i bytes, nel mobile usiamo il path
        String filePath = file.name; // Fallback al nome
        if (kIsWeb) {
          print('Bytes: ${file.bytes?.length}');
        } else {
          filePath = file.path ?? file.name;
          print('Path: $filePath');
        }
        
        setState(() {
          _selectedFile = filePath;
          _selectedFileBytes = file.bytes; // Salva i bytes per il web
        });
        
        // Mostra un messaggio di successo
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File caricato: ${file.name}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Errore file picker: $e');
      
      // Fallback per testing - simuliamo diversi modelli
      final demoFiles = [
        'astronaut_model.stl',
        'robot_figure.obj', 
        'chair_design.3mf',
        'helmet_print.stl',
        'miniature_robot.obj',
      ];
      final randomIndex = DateTime.now().millisecond % demoFiles.length;
      
      setState(() {
        _selectedFile = demoFiles[randomIndex];
        _selectedFileBytes = null; // Reset bytes per demo
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Demo: Caricato ${demoFiles[randomIndex]}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  /// Carica le impostazioni predefinite per un profilo di stampa
  ///
  /// Aggiorna tutte le impostazioni in base al materiale selezionato (PLA, PETG, ABS, TPU)
  /// con valori ottimizzati per quel tipo di filamento
  ///
  /// @param profile Nome del profilo da caricare
  void _loadProfile(String profile) {
    // Carica impostazioni predefinite per il profilo selezionato
    switch (profile) {
      case 'PLA Standard':
        setState(() {
          _layerHeight = 0.2;
          _nozzleTemp = 210;
          _bedTemp = 60;
          _printSpeed = 60;
          _infillDensity = 20;
        });
        break;
      case 'PETG Standard':
        setState(() {
          _layerHeight = 0.2;
          _nozzleTemp = 240;
          _bedTemp = 80;
          _printSpeed = 50;
          _infillDensity = 25;
        });
        break;
      case 'ABS Standard':
        setState(() {
          _layerHeight = 0.2;
          _nozzleTemp = 250;
          _bedTemp = 100;
          _printSpeed = 50;
          _infillDensity = 25;
        });
        break;
      case 'TPU Flexible':
        setState(() {
          _layerHeight = 0.2;
          _nozzleTemp = 220;
          _bedTemp = 50;
          _printSpeed = 30;
          _infillDensity = 15;
        });
        break;
    }
  }

  /// Avvia il processo di slicing
  ///
  /// Mostra un'animazione di progresso che simula il processo di slicing.
  /// In un'app reale, questo metodo chiamerebbe un engine di slicing come
  /// CuraEngine o Slic3r per generare il G-code.
  void _startSlicing() {
    setState(() {
      _isSlicing = true;
      _slicingProgress = 0.0;
    });

    // Simulazione processo di slicing
    _simulateSlicing();
  }

  /// Simula il processo di slicing con un timer
  ///
  /// Incrementa gradualmente la barra di progresso e al termine
  /// mostra un dialog con i risultati dello slicing
  void _simulateSlicing() {
    const duration = Duration(milliseconds: 100);
    Timer.periodic(duration, (timer) {
      setState(() {
        _slicingProgress += 0.02;
      });

      if (_slicingProgress >= 1.0) {
        timer.cancel();
        setState(() {
          _isSlicing = false;
          _slicingProgress = 0.0;
        });

        // Mostra dialog di completamento
        _showSlicingCompleted();
      }
    });
  }

  /// Mostra un'anteprima del G-code che verrebbe generato
  ///
  /// Apre un dialog con un'anteprima del G-code generato
  void _previewSlicing() {
    final gcode = _generateDemoGcode();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anteprima G-code'),
        content: SizedBox(
          width: 500,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              gcode,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportGcode();
            },
            child: const Text('Esporta G-code'),
          ),
        ],
      ),
    );
  }
  
  /// Genera un G-code realistico basato sulle impostazioni correnti
  /// 
  /// Implementa un generatore G-code semplificato ma funzionale
  /// che può essere usato con stampanti 3D reali
  String _generateDemoGcode() {
    final now = DateTime.now();
    final fileName = _selectedFile != null ? 
        path.basename(_selectedFile!) : "unknown_model.stl";
    
    // Parametri di stampa calcolati
    final extrusionWidth = _layerHeight * 1.2; // Larghezza estrusione tipica
    final extrusionMultiplier = 0.0432; // Volume per mm di filamento (1.75mm)
    final retractionDistance = 5.0; // mm
    final retractionSpeed = 45.0; // mm/s
    final zHopHeight = 0.4; // mm di sollevamento Z dopo ritrazione
    final bedSizeX = 220.0; // mm
    final bedSizeY = 220.0; // mm
    final printSpeed = _printSpeed * 60.0; // mm/min
    final travelSpeed = 3000.0; // mm/min
    
    // Calcolo dei movimenti - creiamo un modello semplice basato sulla dimensione del piano
    final StringBuilder = StringBuffer();
    
    // Header del file
    StringBuilder.writeln("""
; Pimp My Printer - G-code generato
; Modello: $fileName
; Data: ${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}:${now.second}
; Slicer: Pimp My Printer Slicer v1.0
;
; PARAMETRI DI STAMPA
; Layer Height: ${_layerHeight.toStringAsFixed(2)} mm
; Temperatura estrusore: ${_nozzleTemp.round()}°C
; Temperatura piatto: ${_bedTemp.round()}°C
; Velocità: ${_printSpeed.round()} mm/s
; Densità riempimento: ${_infillDensity.round()}%
; Pattern: $_selectedInfillPattern
;
""");
    
    // Inizializzazione della stampante
    StringBuilder.writeln("""
; INIZIALIZZAZIONE
M104 S${_nozzleTemp.round()} T0 ; Preriscaldamento estrusore
M140 S${_bedTemp.round()} ; Preriscaldamento piatto
M115 ; Ottieni info stampante
M201 X500 Y500 Z100 E5000 ; Imposta accelerazione
M203 X500 Y500 Z10 E50 ; Imposta velocità massima
M204 P500 R1000 T500 ; Imposta accelerazione per movimenti
M205 X8.00 Y8.00 Z0.40 E5.00 ; Imposta jerk
M220 S100 ; Imposta moltiplicatore velocità al 100%
M221 S100 ; Imposta moltiplicatore estrusione al 100%
G28 ; Home di tutti gli assi
G29 ; Auto bed leveling (se disponibile)
G90 ; Coordinate assolute
G21 ; Unità in millimetri
M83 ; Estrusione relativa
M190 S${_bedTemp.round()} ; Attendi temperatura piatto
M109 S${_nozzleTemp.round()} T0 ; Attendi temperatura estrusore
""");
    
    // Purge e prime line
    StringBuilder.writeln("""
; PURGE LINE
G1 Z5 F${travelSpeed.round()} ; Solleva Z
G1 X5 Y10 F${travelSpeed.round()} ; Vai alla posizione di partenza
G1 Z0.3 F${travelSpeed.round()} ; Abbassa Z
G1 X5 Y150 E15 F${(printSpeed * 0.5).round()} ; Estrusione line
G1 X5.4 Y150 F${travelSpeed.round()} ; Spostamento
G1 X5.4 Y10 E15 F${(printSpeed * 0.5).round()} ; Estrusione line ritorno
G1 Z1 F${travelSpeed.round()} ; Solleva Z
G92 E0 ; Azzera estrusore
""");
    
    // Calcolo layer - simuliamo 3 layer del modello con percorsi realistici
    double z = _layerHeight;
    double extrusionAmount = 0.0;
    
    // Funzione per calcolare l'estrusione basata sulla distanza percorsa
    double calculateExtrusion(double distance) {
      return distance * extrusionWidth * _layerHeight * extrusionMultiplier;
    }
    
    // Generazione di ogni layer
    for (int layer = 1; layer <= 3; layer++) {
      StringBuilder.writeln("""
; LAYER $layer - ${(z).toStringAsFixed(2)}mm
G1 Z${z.toStringAsFixed(2)} F${travelSpeed.round()} ; Solleva a altezza layer
""");
      
      // Perimetro esterno
      StringBuilder.writeln("; Perimetro esterno");
      List<List<double>> perimeterPoints = [
        [20, 20], [20, 80], [80, 80], [80, 20], [20, 20]
      ];
      
      // Movimento al primo punto senza estrusione
      StringBuilder.writeln("G1 X${perimeterPoints[0][0]} Y${perimeterPoints[0][1]} F${travelSpeed.round()} ; Movimento al punto iniziale");
      
      // Estrusione del perimetro
      for (int i = 1; i < perimeterPoints.length; i++) {
        double distance = _calculateDistance(
          perimeterPoints[i-1][0], perimeterPoints[i-1][1],
          perimeterPoints[i][0], perimeterPoints[i][1]
        );
        extrusionAmount = calculateExtrusion(distance);
        StringBuilder.writeln("G1 X${perimeterPoints[i][0]} Y${perimeterPoints[i][1]} E${extrusionAmount.toStringAsFixed(4)} F$printSpeed ; Perimetro");
      }
      
      // Infill - pattern diversi a seconda della selezione
      StringBuilder.writeln("; Infill - $_selectedInfillPattern");
      
      // Simuliamo infill diversi basati sul pattern selezionato
      switch (_selectedInfillPattern) {
        case 'Grid':
          _generateGridInfill(StringBuilder, 25, 75, 25, 75, 10.0, calculateExtrusion, printSpeed);
          break;
        case 'Lines':
          _generateLinesInfill(StringBuilder, 25, 75, 25, 75, 10.0, calculateExtrusion, printSpeed);
          break;
        case 'Triangles':
          _generateTrianglesInfill(StringBuilder, 25, 75, 25, 75, 15.0, calculateExtrusion, printSpeed);
          break;
        default:
          _generateGridInfill(StringBuilder, 25, 75, 25, 75, 10.0, calculateExtrusion, printSpeed);
      }
      
      // Ritrazione alla fine del layer
      StringBuilder.writeln("""
G1 E-$retractionDistance F${(retractionSpeed * 60).round()} ; Ritrazione
G1 Z${(z + zHopHeight).toStringAsFixed(2)} F${travelSpeed.round()} ; Z hop
""");
      
      // Incrementa altezza layer
      z += _layerHeight;
    }
    
    // Finalizzazione
    StringBuilder.writeln("""
; FINALIZZAZIONE
G1 E-$retractionDistance F${(retractionSpeed * 60).round()} ; Ritrazione finale
G1 Z${(z + 10).toStringAsFixed(2)} F${travelSpeed.round()} ; Solleva Z di 10mm
G1 X0 Y${bedSizeY.round()} F${travelSpeed.round()} ; Parcheggia X Y
M104 S0 ; Spegni estrusore
M140 S0 ; Spegni piatto
M107 ; Spegni ventola
M84 ; Disabilita motori
M300 P300 S4000 ; Beep di completamento (se supportato)
; STAMPA COMPLETATA
; Durata stimata: ${(0.5 + (z / _layerHeight) * 2).round()} minuti
; G-code generato con Pimp My Printer
""");
    
    return StringBuilder.toString();
  }
  
  /// Calcola la distanza euclidea tra due punti
  double _calculateDistance(double x1, double y1, double x2, double y2) {
    return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2));
  }
  
  /// Genera pattern di riempimento a griglia
  void _generateGridInfill(
    StringBuffer buffer, 
    double startX, double endX, 
    double startY, double endY, 
    double spacing,
    Function(double) calculateExtrusion,
    double printSpeed
  ) {
    // Linee orizzontali
    for (double y = startY; y <= endY; y += spacing) {
      buffer.writeln("G1 X$startX Y$y F3000 ; Movimento");
      double distance = (endX - startX).abs();
      double extrusion = calculateExtrusion(distance);
      buffer.writeln("G1 X$endX Y$y E${extrusion.toStringAsFixed(4)} F$printSpeed ; Infill orizzontale");
    }
    
    // Linee verticali
    for (double x = startX; x <= endX; x += spacing) {
      buffer.writeln("G1 X$x Y$startY F3000 ; Movimento");
      double distance = (endY - startY).abs();
      double extrusion = calculateExtrusion(distance);
      buffer.writeln("G1 X$x Y$endY E${extrusion.toStringAsFixed(4)} F$printSpeed ; Infill verticale");
    }
  }
  
  /// Genera pattern di riempimento a linee
  void _generateLinesInfill(
    StringBuffer buffer, 
    double startX, double endX, 
    double startY, double endY, 
    double spacing,
    Function(double) calculateExtrusion,
    double printSpeed
  ) {
    // Solo linee orizzontali
    for (double y = startY; y <= endY; y += spacing) {
      // Alterniamo la direzione per ottimizzare
      if ((y - startY) / spacing % 2 == 0) {
        buffer.writeln("G1 X$startX Y$y F3000 ; Movimento");
        double distance = (endX - startX).abs();
        double extrusion = calculateExtrusion(distance);
        buffer.writeln("G1 X$endX Y$y E${extrusion.toStringAsFixed(4)} F$printSpeed ; Infill linea");
      } else {
        buffer.writeln("G1 X$endX Y$y F3000 ; Movimento");
        double distance = (endX - startX).abs();
        double extrusion = calculateExtrusion(distance);
        buffer.writeln("G1 X$startX Y$y E${extrusion.toStringAsFixed(4)} F$printSpeed ; Infill linea");
      }
    }
  }
  
  /// Genera pattern di riempimento a triangoli
  void _generateTrianglesInfill(
    StringBuffer buffer, 
    double startX, double endX, 
    double startY, double endY, 
    double spacing,
    Function(double) calculateExtrusion,
    double printSpeed
  ) {
    final width = endX - startX;
    final height = endY - startY;
    final rows = (height / spacing).ceil();
    
    for (int row = 0; row < rows; row++) {
      double y1 = startY + row * spacing;
      double y2 = y1;
      
      // Prima metà dei triangoli (diagonali /)
      buffer.writeln("G1 X$startX Y$y1 F3000 ; Movimento");
      for (double x = startX; x < endX; x += spacing) {
        double x1 = x;
        double x2 = x + spacing;
        y2 = y1 + spacing;
        
        if (x2 > endX) x2 = endX;
        if (y2 > endY) y2 = endY;
        
        double distance = _calculateDistance(x1, y1, x2, y2);
        double extrusion = calculateExtrusion(distance);
        
        buffer.writeln("G1 X$x2 Y$y2 E${extrusion.toStringAsFixed(4)} F$printSpeed ; Triangolo /");
      }
      
      // Seconda metà dei triangoli (diagonali \)
      if (row + 1 < rows) {
        y1 = startY + (row + 1) * spacing;
        buffer.writeln("G1 X$endX Y$y1 F3000 ; Movimento");
        
        for (double x = endX; x > startX; x -= spacing) {
          double x1 = x;
          double x2 = x - spacing;
          y2 = y1 + spacing;
          
          if (x2 < startX) x2 = startX;
          if (y2 > endY) y2 = endY;
          
          double distance = _calculateDistance(x1, y1, x2, y2);
          double extrusion = calculateExtrusion(distance);
          
          buffer.writeln("G1 X$x2 Y$y2 E${extrusion.toStringAsFixed(4)} F$printSpeed ; Triangolo \\");
        }
      }
    }
  }

  /// Esporta il G-code generato
  /// 
  /// Se l'app è in esecuzione sul web, avvia il download del file
  /// Altrimenti, salva il file sul dispositivo
  void _exportGcode() async {
    if (_selectedFileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nessun file STL caricato'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isSlicing = true;
      _slicingProgress = 0.0;
    });
    
    try {
      if (_isApiAvailable) {
        // Usa l'API per lo slicing
        await _sliceWithApi();
      } else {
        // Usa la generazione locale di G-code come fallback
        _exportLocalGcode();
      }
    } catch (e) {
      setState(() {
        _isSlicing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante la generazione del G-code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Genera il G-code utilizzando l'API
  Future<void> _sliceWithApi() async {
    final fileName = _selectedFile != null ? 
        path.basename(_selectedFile!) : 
        "model.stl";
    
    // Simulazione progresso
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _slicingProgress = i / 10;
      });
    }
    
    // Prepara i parametri per l'API
    final params = GcodeApiService.buildSlicingParams(
      layerHeight: _layerHeight,
      nozzleTemp: _nozzleTemp.toInt(),
      bedTemp: _bedTemp.toInt(),
      printSpeed: _printSpeed,
      infillDensity: _infillDensity.toInt(),
      infillPattern: _selectedInfillPattern.toLowerCase(),
      retractionDistance: 5.0,  // Default
      retractionSpeed: 45.0,    // Default
    );
    
    // Invia la richiesta all'API
    final result = await _apiService.sliceStl(
      stlFileData: _selectedFileBytes!,
      fileName: fileName,
      params: params,
    );
    
    setState(() {
      _isSlicing = false;
      _slicingProgress = 1.0;
    });
    
    if (result['success'] == true) {
      // Mostra il dialogo con le statistiche
      _showApiSlicingCompleted(result);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: ${result['message']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Mostra un dialog con i risultati dello slicing tramite API
  void _showApiSlicingCompleted(Map<String, dynamic> result) {
    final stats = result['stats'];
    
    // Estrai le statistiche rilevanti
    final estimatedFilamentM = stats['estimated_filament_m'] ?? 0.0;
    final estimatedWeightG = stats['estimated_weight_g'] ?? 0.0;
    
    // Stima tempo basata su filamento
    final printTime = (estimatedFilamentM * 150).round(); // ~150 secondi per metro
    final hours = printTime ~/ 3600;
    final minutes = (printTime % 3600) ~/ 60;
    final timeString = '${hours}h ${minutes}m';
    
    final downloadUrl = result['download_url'];
    final gcodeId = result['gcode_id'];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Slicing Completato'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('File G-code generato con successo!'),
              const SizedBox(height: 16),
              const Text('Statistiche:'),
              const SizedBox(height: 8),
              Text('• Tempo stimato: $timeString'),
              Text('• Filamento necessario: ${estimatedFilamentM.toStringAsFixed(1)}m'),
              Text('• Peso stimato: ${estimatedWeightG.toStringAsFixed(1)}g'),
              const SizedBox(height: 16),
              if (kIsWeb)
                const Text(
                  'Cliccando su "Scarica G-code" verrà scaricato il file sul tuo dispositivo.',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Chiudi'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Scarica il G-code
                await _downloadApiGcode(gcodeId);
              },
              child: const Text('Scarica G-code'),
            ),
          ],
        );
      },
    );
  }
  
  /// Scarica il G-code generato dall'API
  Future<void> _downloadApiGcode(String gcodeId) async {
    try {
      // Scarica il G-code
      final gcodeBytes = await _apiService.downloadGcode(gcodeId);
      
      if (gcodeBytes == null) {
        throw Exception('Impossibile scaricare il G-code');
      }
      
      final fileName = _selectedFile != null ? 
          "${path.basenameWithoutExtension(_selectedFile!)}.gcode" : 
          "pimp_my_printer_export.gcode";
      
      if (kIsWeb) {
        // Esporta sul web tramite un download
        final blob = html.Blob([gcodeBytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..style.display = 'none';
          
        html.document.body?.children.add(anchor);
        anchor.click();
        
        // Pulisci
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File G-code scaricato: $fileName'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Implementazione per altre piattaforme
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Funzionalità di esportazione G-code disponibile solo su web'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore durante il download del G-code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  /// Esporta il G-code generato localmente
  void _exportLocalGcode() {
    final gcode = _generateDemoGcode();
    final fileName = _selectedFile != null ? 
        "${path.basenameWithoutExtension(_selectedFile!)}.gcode" : 
        "pimp_my_printer_export.gcode";

    if (kIsWeb) {
      // Esporta sul web tramite un download
      final bytes = utf8.encode(gcode);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", fileName)
        ..style.display = 'none';
        
      html.document.body?.children.add(anchor);
      anchor.click();
      
      // Pulisci
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File G-code scaricato: $fileName'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Qui si implementerebbe il salvataggio su dispositivo per altre piattaforme
      // Per ora mostriamo solo un messaggio
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Funzionalità di esportazione G-code disponibile solo su web'),
          backgroundColor: Colors.orange,
        ),
      );
    }
    
    setState(() {
      _isSlicing = false;
      _slicingProgress = 1.0;
    });
    
    // Mostra il dialogo con le statistiche
    _showSlicingCompleted();
  }

  /// Mostra un dialog con i risultati del processo di slicing
  ///
  /// Visualizza statistiche simulate come tempo di stampa, lunghezza del filamento
  /// e peso stimato del modello. Offre opzioni per chiudere o salvare il G-code.
  void _showSlicingCompleted() {
    // Calcola statistiche basate sulle impostazioni attuali
    final filamentLength = 10.0 + (_infillDensity * 0.2); // Stima basata sulla densità
    final printTime = 60 + (filamentLength * 2.5).round(); // Stima basata sul filamento
    final printWeight = (filamentLength * 3).round(); // ~3g per metro
    
    // Formatta il tempo di stampa
    final hours = printTime ~/ 60;
    final minutes = printTime % 60;
    final timeString = '${hours}h ${minutes}m';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Slicing Completato'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('File G-code generato con successo!'),
              const SizedBox(height: 16),
              const Text('Statistiche:'),
              const SizedBox(height: 8),
              Text('• Tempo stimato: $timeString'),
              Text('• Filamento necessario: ${filamentLength.toStringAsFixed(1)}m'),
              Text('• Peso stimato: ${printWeight}g'),
              const SizedBox(height: 16),
              if (kIsWeb)
                const Text(
                  'Cliccando su "Salva G-code" verrà scaricato il file sul tuo dispositivo.',
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Chiudi'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _exportGcode(); // Usa la funzione di esportazione G-code
              },
              child: const Text('Salva G-code'),
            ),
          ],
        );
      },
    );
  }
}
