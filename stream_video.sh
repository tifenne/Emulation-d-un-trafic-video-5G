#!/bin/bash

#!/bin/bash

VIDEO_URL="http://ffmpeg-server.nexslice.svc.cluster.local:8080/videos/video.mp4"
CHUNK_SIZE=1000000   # 1 Mo
INTERVAL=0.5         # Pause entre deux requêtes (s)
PUSHGATEWAY_URL="http://pushgateway:9091/metrics/job/video_stream"  # optionnel

# Fichier CSV pour sauvegarder les métriques localement
METRICS_FILE="/tmp/video_metrics.csv"

echo "Démarrage du streaming vidéo incrémental..."
echo "Serveur : $VIDEO_URL"
echo "Chunk size : $CHUNK_SIZE bytes"

# Initialisation CSV
if [ ! -f "$METRICS_FILE" ]; then
    echo "timestamp,latency_s,bandwidth_MBps" > $METRICS_FILE
fi

LATENCY_PREV=0
while true; do
    START=$(date +%s.%N)
    HTTP_CODE=$(curl -s -w "%{http_code}" -r 0-$CHUNK_SIZE "$VIDEO_URL" -o /dev/null)
    END=$(date +%s.%N)

    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    
    if [ "$HTTP_CODE" -ne 200 ]; then
        echo "[ERROR] Chunk non reçu (HTTP $HTTP_CODE) à $TIMESTAMP"
    else
        LATENCY=$(echo "$END - $START" | bc -l)
        BANDWIDTH=$(echo "$CHUNK_SIZE / $LATENCY / 1024 / 1024" | bc -l)
        
        # Calcul du jitter approximatif (différence de latence avec le chunk précédent)
        if (( $(echo "$LATENCY_PREV > 0" | bc -l) )); then
            JITTER=$(echo "$LATENCY - $LATENCY_PREV" | bc -l)
        else
            JITTER=0
        fi
        LATENCY_PREV=$LATENCY
        
        echo "[OK] Chunk reçu à $TIMESTAMP | Latence: ${LATENCY}s | Débit: ${BANDWIDTH} MB/s | Jitter: ${JITTER}s"
        
        # Sauvegarde CSV
        echo "$TIMESTAMP,$LATENCY,$BANDWIDTH" >> $METRICS_FILE
        
        # Envoi à Prometheus Pushgateway (optionnel)
        if [ ! -z "$PUSHGATEWAY_URL" ]; then
            curl -s -X POST --data "video_chunk_latency_seconds $LATENCY" $PUSHGATEWAY_URL
            curl -s -X POST --data "video_chunk_bandwidth_mbps $BANDWIDTH" $PUSHGATEWAY_URL
            curl -s -X POST --data "video_chunk_jitter_seconds $JITTER" $PUSHGATEWAY_URL
        fi
    fi
    
    sleep $INTERVAL
done

