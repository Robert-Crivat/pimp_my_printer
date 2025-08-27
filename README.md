# Pimp My Printer 🖨️

Un'applicazione Flutter multipiattaforma per il controllo e la gestione avanzata delle stampanti 3D. Monitora e controlla le tue stampanti 3D da qualsiasi dispositivo, prepara i tuoi modelli per la stampa e visualizza in tempo reale il processo di stampa.

## 🌟 Caratteristiche Principali

- **Dashboard unificata** - Controlla più stampanti da un'unica interfaccia
- **Visualizzatore 3D avanzato** - Visualizza modelli STL con supporto per rotazione, zoom e manipolazione
- **Slicer integrato** - Prepara i tuoi modelli 3D per la stampa direttamente nell'app
- **Monitoraggio in tempo reale** - Verifica temperature, progresso e stato della stampante
- **Controllo remoto** - Invia comandi e gestisci la tua stampante da qualsiasi luogo
- **Compatibilità multipiattaforma** - Funziona su Android, iOS, Web, Windows, macOS e Linux

## 📱 Screenshot

*Screenshot saranno aggiunti presto*

## 🚀 Iniziare

### Prerequisiti

- [Flutter](https://flutter.dev/docs/get-started/install) (versione 3.9.0 o superiore)
- Un dispositivo/emulatore Android, iOS o un browser web

### Installazione

1. Clona questo repository:
   ```bash
   git clone https://github.com/Robert-Crivat/pimp_my_printer.git
   ```

2. Naviga nella directory del progetto:
   ```bash
   cd pimp_my_printer
   ```

3. Installa le dipendenze:
   ```bash
   flutter pub get
   ```

4. Esegui l'applicazione:
   ```bash
   flutter run
   ```

## 📋 Componenti dell'App

### Schermata Principale

L'applicazione include diverse schermate accessibili dal menu laterale:

- **Dashboard** - Panoramica generale dello stato della stampante
- **Temperature** - Controllo e monitoraggio temperature dell'ugello e del piano
- **Controlli** - Movimentazione manuale degli assi e altre operazioni
- **Webcam** - Visualizzazione in tempo reale della stampante
- **Slicer** - Preparazione dei modelli 3D per la stampa
- **File G-Code** - Gestione dei file di stampa
- **Macro** - Comandi personalizzati per operazioni frequenti
- **Impostazioni** - Configurazione dell'applicazione

### Visualizzatore 3D

Il componente `STL3DViewer` consente di:

- Caricare e visualizzare modelli STL
- Ruotare, zoomare e manipolare il modello
- Visualizzare il modello con illuminazione realistica
- Funziona sia in ambiente mobile che web

### Slicer

Lo Slicer integrato permette di:

- Caricare modelli STL, OBJ, 3MF o AMF
- Configurare parametri di stampa (altezza layer, temperatura, velocità)
- Visualizzare anteprima del modello
- Generare G-code pronto per la stampa

## 🛠️ Tecnologie Utilizzate

- **Flutter** - Framework UI cross-platform
- **Provider** - Gestione dello stato
- **Custom Painters** - Rendering avanzato per il visualizzatore 3D
- **WebSockets** - Comunicazione in tempo reale con la stampante
- **File Picker** - Selezione di modelli 3D

## 🔄 Architettura

L'applicazione è strutturata seguendo un'architettura a componenti:

- **Providers** - Gestiscono lo stato dell'applicazione (tema, connessione, ecc.)
- **Screens** - Interfacce utente principali dell'applicazione
- **Widgets** - Componenti riutilizzabili (visualizzatore 3D, controlli, ecc.)
- **Utils** - Funzioni di utilità e helper
- **Models** - Strutture dati per rappresentare entità come stampanti, file, ecc.

## 🤝 Contribuire

I contributi sono benvenuti! Se desideri contribuire:

1. Fai un fork del repository
2. Crea un branch per la tua funzionalità (`git checkout -b feature/amazing-feature`)
3. Fai commit delle tue modifiche (`git commit -m 'Aggiungi una funzionalità incredibile'`)
4. Fai push al branch (`git push origin feature/amazing-feature`)
5. Apri una Pull Request

## 📝 Roadmap

- [ ] Supporto per più protocolli di stampanti (OctoPrint, Klipper, Marlin)
- [ ] Editor G-code integrato
- [ ] Supporto per telecamere multiple
- [ ] Notifiche push per eventi della stampante
- [ ] Supporto per la stampa su più materiali

## 📄 Licenza

Questo progetto è concesso in licenza con la Licenza MIT - vedere il file [LICENSE](LICENSE) per dettagli.

## 👏 Ringraziamenti

- Grazie a tutti i contributori che hanno investito tempo e impegno in questo progetto
- Grazie alla community Flutter per il supporto e le risorse condivise

---

Realizzato con ❤️ per la community di stampa 3D.
