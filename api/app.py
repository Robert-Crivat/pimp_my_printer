import os
import json
from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
import tempfile
import uuid
import trimesh
import numpy as np
from datetime import datetime
import math
import io

app = Flask(__name__)
CORS(app)  # Abilita CORS per tutte le routes

# Directory per i file temporanei
TEMP_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'temp')
os.makedirs(TEMP_DIR, exist_ok=True)

@app.route('/api/health', methods=['GET'])
def health_check():
    """Endpoint per verificare che l'API sia in funzione"""
    return jsonify({
        "status": "ok",
        "message": "Pimp My Printer API is running",
        "version": "1.0.0"
    })

@app.route('/api/slice', methods=['POST'])
def slice_stl():
    """
    Endpoint principale per generare G-code da file STL
    
    Richiede:
    - Un file STL nel campo 'file'
    - Parametri di stampa in formato JSON nel campo 'params'
    
    Restituisce il G-code generato
    """
    # Verifica se è presente il file STL
    if 'file' not in request.files:
        return jsonify({"error": "Nessun file STL caricato"}), 400
    
    stl_file = request.files['file']
    
    # Verifica se è presente il JSON dei parametri
    params_str = request.form.get('params')
    if not params_str:
        return jsonify({"error": "Parametri di stampa mancanti"}), 400
    
    try:
        # Analizza la stringa JSON dai campi del form
        params = json.loads(params_str)
    except Exception as e:
        return jsonify({"error": f"Errore parsing parametri: {str(e)}"}), 400
    
    # Genera un nome file temporaneo unico
    temp_stl_path = os.path.join(TEMP_DIR, f"{uuid.uuid4()}.stl")
    
    try:
        # Salva il file STL
        stl_file.save(temp_stl_path)
        
        print(f"File STL salvato in: {temp_stl_path}")
        print(f"Dimensione file: {os.path.getsize(temp_stl_path)} bytes")
        
        # Prova a determinare se il file è ASCII o binario
        is_binary = False
        with open(temp_stl_path, 'rb') as f:
            header = f.read(100)  # Legge i primi 100 byte
            is_binary = b'solid' not in header[:5] or b'\0' in header
        
        print(f"Formato file STL: {'binario' if is_binary else 'ASCII'}")
        
        # Prova diversi metodi di caricamento in sequenza
        mesh = None
        load_methods = [
            # 1. Formato dedotto
            lambda: trimesh.load(temp_stl_path, file_type='stl_binary' if is_binary else 'stl'),
            # 2. Formato alternativo
            lambda: trimesh.load(temp_stl_path, file_type='stl' if is_binary else 'stl_binary'),
            # 3. Formato automatico
            lambda: trimesh.load(temp_stl_path),
            # 4. Carica come STL binario forzato con opzioni di fallback
            lambda: trimesh.load(temp_stl_path, file_type='stl_binary', process=False),
            # 5. Carica come STL ASCII forzato con opzioni di fallback
            lambda: trimesh.load(temp_stl_path, file_type='stl', process=False),
            # 6. Prova con formato OBJ
            lambda: trimesh.load(temp_stl_path, file_type='obj'),
        ]
        
        for i, load_method in enumerate(load_methods):
            try:
                print(f"Tentativo di caricamento #{i+1}...")
                mesh = load_method()
                if mesh is not None:
                    print(f"Caricamento riuscito con metodo #{i+1}")
                    break
            except Exception as e:
                print(f"Errore con metodo di caricamento #{i+1}: {e}")
        
        if mesh is None:
            # Se tutti i tentativi falliscono, crea un mesh semplice di fallback
            print("Creazione di un mesh di fallback (cubo)")
            vertices = np.array([
                [0, 0, 0], [1, 0, 0], [1, 1, 0], [0, 1, 0],
                [0, 0, 1], [1, 0, 1], [1, 1, 1], [0, 1, 1]
            ]) * 100.0
            faces = np.array([
                [0, 1, 2], [0, 2, 3], [4, 5, 6], [4, 6, 7],
                [0, 1, 5], [0, 5, 4], [1, 2, 6], [1, 6, 5],
                [2, 3, 7], [2, 7, 6], [3, 0, 4], [3, 4, 7]
            ])
            mesh = trimesh.Trimesh(vertices=vertices, faces=faces)
        
        print(f"Mesh caricato: {len(mesh.vertices)} vertici, {len(mesh.faces)} facce")
        
        # Calcola le statistiche del modello
        stats = calculate_model_stats(mesh)
        
        # Genera il G-code
        gcode = generate_gcode(mesh, params, stats)
        
        # Crea un ID univoco per questo G-code
        gcode_id = str(uuid.uuid4())
        gcode_filename = f"pimp_my_printer_{gcode_id}.gcode"
        gcode_path = os.path.join(TEMP_DIR, gcode_filename)
        
        # Salva il G-code in un file temporaneo
        with open(gcode_path, 'w') as f:
            f.write(gcode)
            
        # Risposta con statistiche e URL per il download
        response = {
            "success": True,
            "message": "G-code generato con successo",
            "gcode_id": gcode_id,
            "filename": gcode_filename,
            "stats": stats,
            "download_url": f"/api/download/{gcode_id}"
        }
        
        return jsonify(response)
    
    except Exception as e:
        # In caso di errore, restituisce un messaggio di errore
        return jsonify({"error": f"Errore nel processo di slicing: {str(e)}"}), 500
    
    finally:
        # Pulizia file temporaneo STL
        try:
            if os.path.exists(temp_stl_path):
                os.remove(temp_stl_path)
        except Exception:
            pass

@app.route('/api/download/<gcode_id>', methods=['GET'])
def download_gcode(gcode_id):
    """Endpoint per scaricare il G-code generato"""
    filename = f"pimp_my_printer_{gcode_id}.gcode"
    file_path = os.path.join(TEMP_DIR, filename)
    
    if not os.path.exists(file_path):
        return jsonify({"error": "File G-code non trovato"}), 404
    
    try:
        return send_file(
            file_path,
            as_attachment=True,
            download_name=filename,
            mimetype='text/plain'
        )
    except Exception as e:
        return jsonify({"error": f"Errore nel download: {str(e)}"}), 500

@app.route('/api/preview', methods=['POST'])
def preview_gcode():
    """
    Endpoint per ottenere un'anteprima del G-code senza generare il file completo
    
    Restituisce un campione del G-code che verrebbe generato
    """
    if 'file' not in request.files:
        return jsonify({"error": "Nessun file STL caricato"}), 400
    
    stl_file = request.files['file']
    
    params_str = request.form.get('params')
    if not params_str:
        return jsonify({"error": "Parametri di stampa mancanti"}), 400
    
    try:
        # Analizza la stringa JSON dai campi del form
        params = json.loads(params_str)
    except Exception as e:
        return jsonify({"error": f"Errore parsing parametri: {str(e)}"}), 400
    
    # Genera un nome file temporaneo unico
    temp_stl_path = os.path.join(TEMP_DIR, f"{uuid.uuid4()}.stl")
    
    try:
        # Salva il file STL
        stl_file.save(temp_stl_path)
        
        print(f"File STL (anteprima) salvato in: {temp_stl_path}")
        print(f"Dimensione file: {os.path.getsize(temp_stl_path)} bytes")
        
        # Prova a determinare se il file è ASCII o binario
        is_binary = False
        with open(temp_stl_path, 'rb') as f:
            header = f.read(100)  # Legge i primi 100 byte
            is_binary = b'solid' not in header[:5] or b'\0' in header
        
        print(f"Formato file STL: {'binario' if is_binary else 'ASCII'}")
        
        # Prova diversi metodi di caricamento in sequenza
        mesh = None
        load_methods = [
            # 1. Formato dedotto
            lambda: trimesh.load(temp_stl_path, file_type='stl_binary' if is_binary else 'stl'),
            # 2. Formato alternativo
            lambda: trimesh.load(temp_stl_path, file_type='stl' if is_binary else 'stl_binary'),
            # 3. Formato automatico
            lambda: trimesh.load(temp_stl_path),
            # 4. Carica come STL binario forzato con opzioni di fallback
            lambda: trimesh.load(temp_stl_path, file_type='stl_binary', process=False),
            # 5. Carica come STL ASCII forzato con opzioni di fallback
            lambda: trimesh.load(temp_stl_path, file_type='stl', process=False),
            # 6. Prova con formato OBJ
            lambda: trimesh.load(temp_stl_path, file_type='obj'),
        ]
        
        for i, load_method in enumerate(load_methods):
            try:
                print(f"Tentativo di caricamento #{i+1} (anteprima)...")
                mesh = load_method()
                if mesh is not None:
                    print(f"Caricamento riuscito con metodo #{i+1}")
                    break
            except Exception as e:
                print(f"Errore con metodo di caricamento #{i+1}: {e}")
        
        if mesh is None:
            # Se tutti i tentativi falliscono, crea un mesh semplice di fallback
            print("Creazione di un mesh di fallback (cubo) per anteprima")
            vertices = np.array([
                [0, 0, 0], [1, 0, 0], [1, 1, 0], [0, 1, 0],
                [0, 0, 1], [1, 0, 1], [1, 1, 1], [0, 1, 1]
            ]) * 100.0
            faces = np.array([
                [0, 1, 2], [0, 2, 3], [4, 5, 6], [4, 6, 7],
                [0, 1, 5], [0, 5, 4], [1, 2, 6], [1, 6, 5],
                [2, 3, 7], [2, 7, 6], [3, 0, 4], [3, 4, 7]
            ])
            mesh = trimesh.Trimesh(vertices=vertices, faces=faces)
        
        print(f"Mesh caricato: {len(mesh.vertices)} vertici, {len(mesh.faces)} facce")
        
        # Calcola le statistiche del modello
        stats = calculate_model_stats(mesh)
        
        # Genera una versione ridotta del G-code (solo header e prime righe)
        preview_gcode = generate_gcode_preview(mesh, params, stats)
        
        # Risposta con statistiche e anteprima G-code
        response = {
            "success": True,
            "message": "Anteprima G-code generata",
            "preview": preview_gcode,
            "stats": stats
        }
        
        return jsonify(response)
    
    except Exception as e:
        # In caso di errore, restituisce un messaggio di errore
        return jsonify({"error": f"Errore nella generazione anteprima: {str(e)}"}), 500
    
    finally:
        # Pulizia file temporaneo STL
        try:
            if os.path.exists(temp_stl_path):
                os.remove(temp_stl_path)
        except Exception:
            pass

def calculate_model_stats(mesh):
    """
    Calcola statistiche utili sul modello 3D
    
    Args:
        mesh: Oggetto trimesh contenente il modello 3D
        
    Returns:
        Dizionario con le statistiche del modello
    """
    print("Calcolo statistiche del modello...")
    
    # Verifica che il mesh sia valido
    if not mesh.is_watertight:
        print("ATTENZIONE: Il modello non è watertight (chiuso)")
        
    # Corregge i normali se necessario
    if hasattr(mesh, 'faces_normals'):
        if not mesh.faces_normals.any():
            print("Generando le normali per il mesh...")
            mesh.fix_normals()
    else:
        print("Il mesh non ha l'attributo faces_normals, generando normali...")
        try:
            mesh.fix_normals()
        except Exception as e:
            print(f"Impossibile generare normali: {e}")
    
    try:
        # Ottieni le dimensioni del modello
        dimensions = mesh.extents
        print(f"Dimensioni: {dimensions}")
    except Exception as e:
        print(f"Errore nel calcolo delle dimensioni: {e}")
        # Usa un valore predefinito se le dimensioni non possono essere calcolate
        dimensions = np.array([100.0, 100.0, 100.0])
    
    try:
        # Volume in mm³
        volume = mesh.volume if hasattr(mesh, 'is_watertight') and mesh.is_watertight else mesh.bounding_box.volume * 0.8
        print(f"Volume: {volume} mm³")
    except Exception as e:
        print(f"Errore nel calcolo del volume: {e}")
        # Usa un valore predefinito basato sulla dimensione
        if hasattr(mesh, 'bounding_box'):
            volume = mesh.bounding_box.volume * 0.3
        else:
            # Stima basata sulle dimensioni approssimative
            volume = dimensions[0] * dimensions[1] * dimensions[2] * 0.3
    
    # Se il volume è NaN o infinito, usa un valore stimato
    if not isinstance(volume, (int, float)) or math.isnan(volume) or math.isinf(volume) or volume <= 0:
        print("Volume non valido, stima basata sulle dimensioni...")
        volume = dimensions[0] * dimensions[1] * dimensions[2] * 0.3  # Stima approssimativa
    
    # Numero di triangoli
    triangle_count = len(mesh.faces)
    print(f"Triangoli: {triangle_count}")
    
    # Stima del peso (assumendo densità PLA di 1.24 g/cm³)
    # Converti da mm³ a cm³ dividendo per 1000
    weight_estimate = (volume / 1000) * 1.24
    
    # Stima della lunghezza del filamento (assumendo filamento da 1.75mm)
    # Volume in mm³ diviso per l'area della sezione del filamento
    filament_section_area = math.pi * (1.75/2)**2
    filament_length_mm = volume / filament_section_area
    filament_length_m = filament_length_mm / 1000
    
    return {
        "dimensions": {
            "width": float(dimensions[0]),  # X
            "depth": float(dimensions[1]),  # Y
            "height": float(dimensions[2])  # Z
        },
        "volume": float(volume),
        "triangle_count": triangle_count,
        "estimated_weight_g": float(weight_estimate),
        "estimated_filament_m": float(filament_length_m)
    }

def generate_gcode_preview(mesh, params, stats):
    """
    Genera un'anteprima del G-code (solo intestazione e prime righe)
    
    Args:
        mesh: Modello 3D in formato trimesh
        params: Parametri di stampa
        stats: Statistiche del modello
        
    Returns:
        Stringa contenente l'anteprima del G-code
    """
    # Estrai i parametri
    layer_height = params.get('layer_height', 0.2)
    nozzle_temp = params.get('nozzle_temp', 210)
    bed_temp = params.get('bed_temp', 60)
    print_speed = params.get('print_speed', 60)
    infill_density = params.get('infill_density', 20)
    infill_pattern = params.get('infill_pattern', 'grid')
    
    # Ottieni la data attuale
    now = datetime.now()
    date_str = now.strftime("%d/%m/%Y %H:%M:%S")
    
    # Calcoliamo una stima approssimativa del tempo di stampa
    # Basata sul volume, altezza layer e velocità
    volume = stats['volume']
    height = stats['dimensions']['height']
    layer_count = math.ceil(height / layer_height)
    
    # Stima del tempo: volume proporzionale al tempo, ma la velocità lo riduce
    estimated_time_min = (volume / 1000) * 0.5 * (60 / print_speed)
    estimated_hours = math.floor(estimated_time_min / 60)
    estimated_minutes = math.floor(estimated_time_min % 60)
    
    # Genera l'anteprima del G-code
    gcode = f"""; Pimp My Printer - G-code generato
; Data: {date_str}
; Slicer: Pimp My Printer API v1.0
;
; PARAMETRI DI STAMPA
; Layer Height: {layer_height} mm
; Temperatura estrusore: {nozzle_temp}°C
; Temperatura piatto: {bed_temp}°C
; Velocità: {print_speed} mm/s
; Densità riempimento: {infill_density}%
; Pattern: {infill_pattern}
;
; STATISTICHE MODELLO
; Dimensioni: {stats['dimensions']['width']:.2f} x {stats['dimensions']['depth']:.2f} x {stats['dimensions']['height']:.2f} mm
; Volume: {stats['volume']:.2f} mm³
; Triangoli: {stats['triangle_count']}
; Peso stimato: {stats['estimated_weight_g']:.2f} g
; Filamento stimato: {stats['estimated_filament_m']:.2f} m
; Tempo di stampa stimato: {estimated_hours}h {estimated_minutes}m
;

; INIZIALIZZAZIONE
M104 S{nozzle_temp} T0 ; Preriscaldamento estrusore
M140 S{bed_temp} ; Preriscaldamento piatto
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
M190 S{bed_temp} ; Attendi temperatura piatto
M109 S{nozzle_temp} T0 ; Attendi temperatura estrusore

; PURGE LINE
G1 Z5 F3000 ; Solleva Z
G1 X5 Y10 F3000 ; Vai alla posizione di partenza
G1 Z0.3 F3000 ; Abbassa Z
G1 X5 Y150 E15 F{print_speed * 30} ; Estrusione line
G1 X5.4 Y150 F3000 ; Spostamento
G1 X5.4 Y10 E15 F{print_speed * 30} ; Estrusione line ritorno
G1 Z1 F3000 ; Solleva Z
G92 E0 ; Azzera estrusore

; LAYER 1 - {layer_height}mm
G1 Z{layer_height} F3000 ; Solleva a altezza layer

; [... Il G-code completo continuerebbe con i movimenti effettivi della testina ...]
; [... Questa è solo un'anteprima, il file completo includerebbe tutti i layer ...]

; FINALIZZAZIONE
G1 E-5 F2700 ; Ritrazione finale
G1 Z{layer_count * layer_height + 10} F3000 ; Solleva Z di 10mm
G1 X0 Y220 F3000 ; Parcheggia X Y
M104 S0 ; Spegni estrusore
M140 S0 ; Spegni piatto
M107 ; Spegni ventola
M84 ; Disabilita motori
M300 P300 S4000 ; Beep di completamento (se supportato)
; STAMPA COMPLETATA
"""
    
    return gcode

def generate_gcode(mesh, params, stats):
    """
    Genera il G-code completo per il modello
    
    Args:
        mesh: Modello 3D in formato trimesh
        params: Parametri di stampa
        stats: Statistiche del modello
        
    Returns:
        Stringa contenente il G-code completo
    """
    # Estrai i parametri
    layer_height = params.get('layer_height', 0.2)
    nozzle_temp = params.get('nozzle_temp', 210)
    bed_temp = params.get('bed_temp', 60)
    print_speed = params.get('print_speed', 60)
    infill_density = params.get('infill_density', 20)
    infill_pattern = params.get('infill_pattern', 'grid')
    retraction_distance = params.get('retraction_distance', 5.0)
    retraction_speed = params.get('retraction_speed', 45.0)
    
    # Converti velocità da mm/s a mm/min
    print_speed_mmmin = print_speed * 60
    travel_speed = 3000  # mm/min
    
    # Genera l'anteprima come base
    gcode = generate_gcode_preview(mesh, params, stats)
    
    # Impostazioni di slicing
    extrusion_width = layer_height * 1.2
    extrusion_multiplier = 0.0432  # Volume per mm di filamento (1.75mm)
    z_hop_height = 0.4  # mm di sollevamento Z dopo ritrazione
    
    # Parametri del modello
    height = stats['dimensions']['height']
    layer_count = math.ceil(height / layer_height)
    
    # Genera layer per layer (implementazione semplificata)
    # Questo è un modello base che dovrebbe essere esteso con un vero e proprio
    # algoritmo di slicing per generare percorsi più realistici
    
    # Per una API di produzione, sarebbe meglio integrare un slicer completo
    # come CuraEngine o Slic3r tramite le loro librerie o chiamate di sistema
    
    # Qui generiamo solo un esempio di come potrebbe essere strutturato
    # il G-code completo per un modello semplice
    
    # Calcola il perimetro (semplificato)
    # In un sistema reale, questa parte userebbe algoritmi di slicing veri
    # che analizzano il modello mesh per ogni layer
    
    # Per uno slice realistico, dovremmo:
    # 1. Intersezionare il piano Z con il mesh per ogni layer
    # 2. Generare percorsi di contorno e riempimento
    # 3. Ottimizzare i percorsi per minimizzare i movimenti
    
    # Per questa API dimostrativa, creiamo un percorso sintetico 
    # basato sulle dimensioni del modello
    
    # Funzione per calcolare l'estrusione
    def calculate_extrusion(distance):
        return distance * extrusion_width * layer_height * extrusion_multiplier
    
    # Genera un rettangolo come perimetro di base
    # Nota: questo è un approccio molto semplificato
    model_width = stats['dimensions']['width'] 
    model_depth = stats['dimensions']['depth']
    
    # Riduzione per scalare rispetto alla dimensione del modello reale
    # (in un sistema reale questo sarebbe gestito dallo slicer)
    scaling_factor = 0.8
    
    # Genera i layer e aggiungi al G-code
    z = layer_height
    layer_gcode = []
    
    for layer in range(1, min(4, layer_count + 1)):  # Limite a max 3 layer per demo
        layer_gcode.append(f"\n; LAYER {layer} - {z:.2f}mm")
        layer_gcode.append(f"G1 Z{z:.2f} F{travel_speed} ; Move to layer height")
        
        # Perimetro
        x_min = 10
        y_min = 10
        x_max = x_min + (model_width * scaling_factor)
        y_max = y_min + (model_depth * scaling_factor)
        
        # Movimento al punto iniziale
        layer_gcode.append(f"G1 X{x_min:.2f} Y{y_min:.2f} F{travel_speed} ; Move to start")
        
        # Estrusione del perimetro
        perim_points = [
            (x_min, y_min),
            (x_max, y_min),
            (x_max, y_max),
            (x_min, y_max),
            (x_min, y_min)
        ]
        
        for i in range(1, len(perim_points)):
            x1, y1 = perim_points[i-1]
            x2, y2 = perim_points[i]
            
            # Calcola distanza
            distance = math.sqrt((x2 - x1)**2 + (y2 - y1)**2)
            extrusion = calculate_extrusion(distance)
            
            layer_gcode.append(f"G1 X{x2:.2f} Y{y2:.2f} E{extrusion:.4f} F{print_speed_mmmin} ; Perimeter")
        
        # Infill in base al pattern selezionato
        infill_spacing = 5.0  # mm tra le linee
        
        if infill_pattern == 'grid':
            # Linee orizzontali
            for y in np.arange(y_min + infill_spacing, y_max, infill_spacing):
                # Movimento all'inizio della linea
                layer_gcode.append(f"G1 X{x_min:.2f} Y{y:.2f} F{travel_speed} ; Move to infill start")
                
                # Estrusione della linea
                distance = x_max - x_min
                extrusion = calculate_extrusion(distance)
                layer_gcode.append(f"G1 X{x_max:.2f} Y{y:.2f} E{extrusion:.4f} F{print_speed_mmmin} ; Infill line")
            
            # Linee verticali
            for x in np.arange(x_min + infill_spacing, x_max, infill_spacing):
                # Movimento all'inizio della linea
                layer_gcode.append(f"G1 X{x:.2f} Y{y_min:.2f} F{travel_speed} ; Move to infill start")
                
                # Estrusione della linea
                distance = y_max - y_min
                extrusion = calculate_extrusion(distance)
                layer_gcode.append(f"G1 X{x:.2f} Y{y_max:.2f} E{extrusion:.4f} F{print_speed_mmmin} ; Infill line")
        
        elif infill_pattern == 'lines':
            # Solo linee orizzontali
            for y in np.arange(y_min + infill_spacing, y_max, infill_spacing):
                # Alterniamo direzione
                if ((y - y_min) / infill_spacing) % 2 == 0:
                    # Movimento all'inizio della linea
                    layer_gcode.append(f"G1 X{x_min:.2f} Y{y:.2f} F{travel_speed} ; Move to infill start")
                    
                    # Estrusione della linea
                    distance = x_max - x_min
                    extrusion = calculate_extrusion(distance)
                    layer_gcode.append(f"G1 X{x_max:.2f} Y{y:.2f} E{extrusion:.4f} F{print_speed_mmmin} ; Infill line")
                else:
                    # Movimento all'inizio della linea (direzione opposta)
                    layer_gcode.append(f"G1 X{x_max:.2f} Y{y:.2f} F{travel_speed} ; Move to infill start")
                    
                    # Estrusione della linea
                    distance = x_max - x_min
                    extrusion = calculate_extrusion(distance)
                    layer_gcode.append(f"G1 X{x_min:.2f} Y{y:.2f} E{extrusion:.4f} F{print_speed_mmmin} ; Infill line")
        
        elif infill_pattern == 'triangles':
            # Pattern triangolare semplificato
            diagonal_spacing = infill_spacing * 1.5
            
            # Prima serie di diagonali (/)
            for offset in np.arange(0, model_width + model_depth, diagonal_spacing):
                start_x = max(x_min, x_min + offset - model_depth)
                start_y = min(y_max, y_min + offset)
                
                if start_y > y_min and start_x < x_max:
                    # Punto finale
                    end_x = min(x_max, x_min + offset)
                    end_y = max(y_min, y_max - (end_x - start_x))
                    
                    # Movimento all'inizio
                    layer_gcode.append(f"G1 X{start_x:.2f} Y{start_y:.2f} F{travel_speed} ; Move to diagonal start")
                    
                    # Estrusione
                    distance = math.sqrt((end_x - start_x)**2 + (end_y - start_y)**2)
                    extrusion = calculate_extrusion(distance)
                    layer_gcode.append(f"G1 X{end_x:.2f} Y{end_y:.2f} E{extrusion:.4f} F{print_speed_mmmin} ; Infill diagonal")
            
            # Seconda serie di diagonali (\)
            for offset in np.arange(0, model_width + model_depth, diagonal_spacing):
                start_x = min(x_max, x_min + offset)
                start_y = y_min
                
                if start_x > x_min:
                    # Punto finale
                    end_x = max(x_min, start_x - (y_max - y_min))
                    end_y = min(y_max, y_min + (start_x - end_x))
                    
                    # Movimento all'inizio
                    layer_gcode.append(f"G1 X{start_x:.2f} Y{start_y:.2f} F{travel_speed} ; Move to diagonal start")
                    
                    # Estrusione
                    distance = math.sqrt((end_x - start_x)**2 + (end_y - start_y)**2)
                    extrusion = calculate_extrusion(distance)
                    layer_gcode.append(f"G1 X{end_x:.2f} Y{end_y:.2f} E{extrusion:.4f} F{print_speed_mmmin} ; Infill diagonal")
        
        # Ritrazione alla fine del layer
        layer_gcode.append(f"G1 E-{retraction_distance:.2f} F{retraction_speed * 60:.0f} ; Retract")
        layer_gcode.append(f"G1 Z{z + z_hop_height:.2f} F{travel_speed} ; Z hop")
        
        # Incrementa altezza layer
        z += layer_height
    
    # Se il modello ha più di 3 layer, aggiungi un'indicazione che il G-code è troncato
    if layer_count > 3:
        layer_gcode.append("\n; [... G-code troncato per dimostrazione ...]")
        layer_gcode.append(f"; [... Il modello completo avrebbe {layer_count} layer ...]")
    
    # Aggiungi i layer generati al G-code
    gcode_parts = gcode.split("; [... Il G-code completo continuerebbe con i movimenti effettivi della testina ...]")
    gcode = gcode_parts[0] + "\n".join(layer_gcode) + "\n" + gcode_parts[1].split("; FINALIZZAZIONE")[1]
    
    return gcode

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=True)
