import 'dart:async';
import 'package:flutter/foundation.dart'; // Per kIsWeb e Uint8List
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/theme_provider.dart';
import '../widgets/grid_painter.dart';
import '../widgets/stl_3d_viewer.dart';

class SlicerScreen extends StatefulWidget {
  const SlicerScreen({super.key});

  @override
  State<SlicerScreen> createState() => _SlicerScreenState();
}

class _SlicerScreenState extends State<SlicerScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedFile;
  Uint8List? _selectedFileBytes; // Aggiunto per supporto web
  double _layerHeight = 0.2;
  double _infillDensity = 20.0;
  int _printSpeed = 60;
  double _nozzleTemp = 210.0;
  double _bedTemp = 60.0;
  String _selectedProfile = 'PLA Standard';
  bool _isSlicing = false;
  double _slicingProgress = 0.0;

  final List<String> _profiles = [
    'PLA Standard',
    'PETG Standard',
    'ABS Standard',
    'TPU Flexible',
    'Custom Profile'
  ];

  final List<String> _infillPatterns = [
    'Grid',
    'Lines',
    'Triangles',
    'Cubic',
    'Gyroid',
    'Honeycomb'
  ];

  String _selectedInfillPattern = 'Grid';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  Widget _buildCompactFilePreview() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
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


  // Metodi esistenti adattati
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

  Widget _buildFilePreview() {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
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

  void _startSlicing() {
    setState(() {
      _isSlicing = true;
      _slicingProgress = 0.0;
    });

    // Simulazione processo di slicing
    _simulateSlicing();
  }

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

  void _previewSlicing() {
    // TODO: Implementare anteprima slicing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Anteprima slicing - Funzionalità in sviluppo'),
      ),
    );
  }

  void _showSlicingCompleted() {
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
              Text('• Tempo stimato: 2h 45m'),
              Text('• Filamento necessario: 15.2m'),
              Text('• Peso stimato: 45.3g'),
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
                // TODO: Salvare il file G-code
              },
              child: const Text('Salva G-code'),
            ),
          ],
        );
      },
    );
  }
}
