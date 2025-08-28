; Pimp My Printer - G-code generato
; Data: 28/08/2025 15:45:30
; Slicer: Pimp My Printer API v1.0
;
; PARAMETRI DI STAMPA
; Layer Height: 0.2 mm
; Temperatura estrusore: 280°C
; Temperatura piatto: 120°C
; Velocità: 60 mm/s
; Densità riempimento: 20%
; Pattern: grid
;
; STATISTICHE MODELLO
; Dimensioni: 30.00 x 30.00 x 30.00 mm
; Volume: 20499.56 mm³
; Triangoli: 3414
; Peso stimato: 25.42 g
; Filamento stimato: 8.52 m
; Tempo di stampa stimato: 0h 10m
;

; INIZIALIZZAZIONE
M104 S280 T0 ; Preriscaldamento estrusore
M140 S120 ; Preriscaldamento piatto
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
M190 S120 ; Attendi temperatura piatto
M109 S280 T0 ; Attendi temperatura estrusore

; PURGE LINE
G1 Z5 F3000 ; Solleva Z
G1 X5 Y10 F3000 ; Vai alla posizione di partenza
G1 Z0.3 F3000 ; Abbassa Z
G1 X5 Y150 E15 F1800 ; Estrusione line
G1 X5.4 Y150 F3000 ; Spostamento
G1 X5.4 Y10 E15 F1800 ; Estrusione line ritorno
G1 Z1 F3000 ; Solleva Z
G92 E0 ; Azzera estrusore

; LAYER 1 - 0.2mm
G1 Z0.2 F3000 ; Solleva a altezza layer


; LAYER 1 - 0.20mm
G1 Z0.20 F3000 ; Move to layer height
G1 X10.00 Y10.00 F3000 ; Move to start
G1 X34.00 Y10.00 E0.0498 F3600 ; Perimeter
G1 X34.00 Y34.00 E0.0498 F3600 ; Perimeter
G1 X10.00 Y34.00 E0.0498 F3600 ; Perimeter
G1 X10.00 Y10.00 E0.0498 F3600 ; Perimeter
G1 X10.00 Y15.00 F3000 ; Move to infill start
G1 X34.00 Y15.00 E0.0498 F3600 ; Infill line
G1 X10.00 Y20.00 F3000 ; Move to infill start
G1 X34.00 Y20.00 E0.0498 F3600 ; Infill line
G1 X10.00 Y25.00 F3000 ; Move to infill start
G1 X34.00 Y25.00 E0.0498 F3600 ; Infill line
G1 X10.00 Y30.00 F3000 ; Move to infill start
G1 X34.00 Y30.00 E0.0498 F3600 ; Infill line
G1 X15.00 Y10.00 F3000 ; Move to infill start
G1 X15.00 Y34.00 E0.0498 F3600 ; Infill line
G1 X20.00 Y10.00 F3000 ; Move to infill start
G1 X20.00 Y34.00 E0.0498 F3600 ; Infill line
G1 X25.00 Y10.00 F3000 ; Move to infill start
G1 X25.00 Y34.00 E0.0498 F3600 ; Infill line
G1 X30.00 Y10.00 F3000 ; Move to infill start
G1 X30.00 Y34.00 E0.0498 F3600 ; Infill line
G1 E-5.00 F2700 ; Retract
G1 Z0.60 F3000 ; Z hop

; LAYER 2 - 0.40mm
G1 Z0.40 F3000 ; Move to layer height
G1 X10.00 Y10.00 F3000 ; Move to start
G1 X34.00 Y10.00 E0.0498 F3600 ; Perimeter
G1 X34.00 Y34.00 E0.0498 F3600 ; Perimeter
G1 X10.00 Y34.00 E0.0498 F3600 ; Perimeter
G1 X10.00 Y10.00 E0.0498 F3600 ; Perimeter
G1 X10.00 Y15.00 F3000 ; Move to infill start
G1 X34.00 Y15.00 E0.0498 F3600 ; Infill line
G1 X10.00 Y20.00 F3000 ; Move to infill start
G1 X34.00 Y20.00 E0.0498 F3600 ; Infill line
G1 X10.00 Y25.00 F3000 ; Move to infill start
G1 X34.00 Y25.00 E0.0498 F3600 ; Infill line
G1 X10.00 Y30.00 F3000 ; Move to infill start
G1 X34.00 Y30.00 E0.0498 F3600 ; Infill line
G1 X15.00 Y10.00 F3000 ; Move to infill start
G1 X15.00 Y34.00 E0.0498 F3600 ; Infill line
G1 X20.00 Y10.00 F3000 ; Move to infill start
G1 X20.00 Y34.00 E0.0498 F3600 ; Infill line
G1 X25.00 Y10.00 F3000 ; Move to infill start
G1 X25.00 Y34.00 E0.0498 F3600 ; Infill line
G1 X30.00 Y10.00 F3000 ; Move to infill start
G1 X30.00 Y34.00 E0.0498 F3600 ; Infill line
G1 E-5.00 F2700 ; Retract
G1 Z0.80 F3000 ; Z hop

; LAYER 3 - 0.60mm
G1 Z0.60 F3000 ; Move to layer height
G1 X10.00 Y10.00 F3000 ; Move to start
G1 X34.00 Y10.00 E0.0498 F3600 ; Perimeter
G1 X34.00 Y34.00 E0.0498 F3600 ; Perimeter
G1 X10.00 Y34.00 E0.0498 F3600 ; Perimeter
G1 X10.00 Y10.00 E0.0498 F3600 ; Perimeter
G1 X10.00 Y15.00 F3000 ; Move to infill start
G1 X34.00 Y15.00 E0.0498 F3600 ; Infill line
G1 X10.00 Y20.00 F3000 ; Move to infill start
G1 X34.00 Y20.00 E0.0498 F3600 ; Infill line
G1 X10.00 Y25.00 F3000 ; Move to infill start
G1 X34.00 Y25.00 E0.0498 F3600 ; Infill line
G1 X10.00 Y30.00 F3000 ; Move to infill start
G1 X34.00 Y30.00 E0.0498 F3600 ; Infill line
G1 X15.00 Y10.00 F3000 ; Move to infill start
G1 X15.00 Y34.00 E0.0498 F3600 ; Infill line
G1 X20.00 Y10.00 F3000 ; Move to infill start
G1 X20.00 Y34.00 E0.0498 F3600 ; Infill line
G1 X25.00 Y10.00 F3000 ; Move to infill start
G1 X25.00 Y34.00 E0.0498 F3600 ; Infill line
G1 X30.00 Y10.00 F3000 ; Move to infill start
G1 X30.00 Y34.00 E0.0498 F3600 ; Infill line
G1 E-5.00 F2700 ; Retract
G1 Z1.00 F3000 ; Z hop

; [... G-code troncato per dimostrazione ...]
; [... Il modello completo avrebbe 150 layer ...]

G1 E-5 F2700 ; Ritrazione finale
G1 Z40.0 F3000 ; Solleva Z di 10mm
G1 X0 Y220 F3000 ; Parcheggia X Y
M104 S0 ; Spegni estrusore
M140 S0 ; Spegni piatto
M107 ; Spegni ventola
M84 ; Disabilita motori
M300 P300 S4000 ; Beep di completamento (se supportato)
; STAMPA COMPLETATA
