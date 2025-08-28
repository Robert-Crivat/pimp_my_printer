# Pimp My Printer API

API in Python per la generazione di G-code da file STL.

## Requisiti

- Python 3.9+
- Flask
- Trimesh
- NumPy

## Installazione

```bash
pip install -r requirements.txt
```

## Esecuzione

```bash
python app.py
```

L'API sarà disponibile all'indirizzo `http://localhost:5000`.

## Utilizzo con Docker

Costruire l'immagine:

```bash
docker build -t pimp-my-printer-api .
```

Avviare il container:

```bash
docker run -p 5000:5000 pimp-my-printer-api
```

## Endpoints API

### `GET /api/health`

Verifica che l'API sia in esecuzione.

**Risposta**:
```json
{
    "status": "ok",
    "message": "Pimp My Printer API is running",
    "version": "1.0.0"
}
```

### `POST /api/slice`

Genera il G-code da un file STL.

**Parametri**:
- `file`: File STL (multipart/form-data)
- `params`: JSON con i parametri di stampa

Esempio di parametri:
```json
{
    "layer_height": 0.2,
    "nozzle_temp": 210,
    "bed_temp": 60,
    "print_speed": 60,
    "infill_density": 20,
    "infill_pattern": "grid",
    "retraction_distance": 5.0,
    "retraction_speed": 45.0
}
```

**Risposta**:
```json
{
    "success": true,
    "message": "G-code generato con successo",
    "gcode_id": "1a2b3c4d-5e6f-7g8h-9i0j",
    "filename": "pimp_my_printer_1a2b3c4d-5e6f-7g8h-9i0j.gcode",
    "stats": {
        "dimensions": {
            "width": 100.0,
            "depth": 100.0,
            "height": 100.0
        },
        "volume": 1000000.0,
        "triangle_count": 1000,
        "estimated_weight_g": 1240.0,
        "estimated_filament_m": 15.5
    },
    "download_url": "/api/download/1a2b3c4d-5e6f-7g8h-9i0j"
}
```

### `GET /api/download/<gcode_id>`

Scarica il G-code generato.

**Parametri**:
- `gcode_id`: ID del G-code da scaricare

**Risposta**: File G-code

### `POST /api/preview`

Genera un'anteprima del G-code da un file STL.

**Parametri**:
- `file`: File STL (multipart/form-data)
- `params`: JSON con i parametri di stampa (come per /api/slice)

**Risposta**:
```json
{
    "success": true,
    "message": "Anteprima G-code generata",
    "preview": "; Pimp My Printer - G-code generato\n...",
    "stats": {
        "dimensions": {
            "width": 100.0,
            "depth": 100.0,
            "height": 100.0
        },
        "volume": 1000000.0,
        "triangle_count": 1000,
        "estimated_weight_g": 1240.0,
        "estimated_filament_m": 15.5
    }
}
```

## Integrazione con Flutter

Per integrare questa API con l'app Flutter Pimp My Printer, è necessario:

1. Avviare l'API in un container Docker o su un server
2. Configurare l'app Flutter per inviare richieste all'API
3. Implementare l'interfaccia per caricare file STL e impostare i parametri di stampa

Vedere la documentazione dell'app Flutter per maggiori dettagli sull'integrazione.
