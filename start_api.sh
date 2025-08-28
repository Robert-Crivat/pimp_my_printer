#!/bin/bash

# Script per avviare l'API di Pimp My Printer

# Controlla se è disponibile Python
if ! command -v python3 &> /dev/null
then
    echo "Python3 non trovato. È necessario installare Python 3.9 o superiore."
    exit 1
fi

# Controlla se esiste la directory api
if [ ! -d "api" ]
then
    echo "Directory 'api' non trovata. Esegui questo script dalla directory principale del progetto."
    exit 1
fi

# Controlla se Docker è disponibile
HAS_DOCKER=false
if command -v docker &> /dev/null
then
    HAS_DOCKER=true
fi

# Menu per scegliere come avviare l'API
echo "=== Pimp My Printer API ==="
echo "Come vuoi avviare l'API?"
echo "1) Direttamente con Python"
if [ "$HAS_DOCKER" = true ]; then
    echo "2) Con Docker"
    echo "3) Costruisci solo l'immagine Docker"
fi
echo "0) Esci"

read -p "Scelta: " choice

case $choice in
    1)
        echo "Avvio dell'API con Python..."
        cd api
        
        # Controlla se esiste l'ambiente virtuale
        if [ ! -d "venv" ]
        then
            echo "Creazione di un ambiente virtuale..."
            python3 -m venv venv
        fi
        
        # Attiva l'ambiente virtuale
        echo "Attivazione dell'ambiente virtuale..."
        source venv/bin/activate
        
        # Installa le dipendenze
        echo "Installazione delle dipendenze..."
        pip install -r requirements.txt
        
        # Avvia l'API
        echo "Avvio dell'API su http://localhost:5000"
        python app.py
        ;;
    2)
        if [ "$HAS_DOCKER" = true ]; then
            echo "Avvio dell'API con Docker..."
            
            # Controlla se l'immagine esiste già
            if ! docker images | grep -q pimp-my-printer-api; then
                echo "Costruzione dell'immagine Docker..."
                docker build -t pimp-my-printer-api api
            fi
            
            echo "Avvio del container Docker..."
            docker run --rm -p 5000:5000 pimp-my-printer-api
        else
            echo "Docker non è disponibile sul sistema."
        fi
        ;;
    3)
        if [ "$HAS_DOCKER" = true ]; then
            echo "Costruzione dell'immagine Docker..."
            docker build -t pimp-my-printer-api api
            echo "Immagine Docker 'pimp-my-printer-api' creata con successo."
        else
            echo "Docker non è disponibile sul sistema."
        fi
        ;;
    0)
        echo "Uscita..."
        exit 0
        ;;
    *)
        echo "Scelta non valida."
        exit 1
        ;;
esac
