FROM python:3.9-slim

WORKDIR /app

# Copia solo requirements.txt all'inizio per sfruttare il caching dei layer Docker
COPY requirements.txt .

# Installa le dipendenze
RUN pip install --no-cache-dir -r requirements.txt

# Copia il resto dell'applicazione
COPY . .

# Crea la directory per i file temporanei
RUN mkdir -p temp

# Imposta le variabili d'ambiente
ENV FLASK_APP=app.py
ENV FLASK_ENV=production
ENV PYTHONUNBUFFERED=1

# Esponi la porta
EXPOSE 5000

# Avvia l'applicazione con Gunicorn
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
