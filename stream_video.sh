#!/bin/bash

VIDEO_URL="http://ffmpeg-server.nexslice.svc.cluster.local:8080/videos/video.mp4"
CHUNK_SIZE=1000000   # 1 Mo
INTERVAL=0.5         # Pause entre deux requêtes (s)
PUSHGATEWAY_URL="http://pushgateway.monitoring.svc.cluster.local:9091/metrics/job/video_stream"

# Fichier CSV pour sauvegarder les métriques localement
METRICS_FILE="/tmp/video_metrics.csv"

echo "Démarrage du streaming vidéo incrémental..."
echo "Serveur : $VIDEO_URL"
echo "Chunk size : $CHUNK_SIZE bytes"

# Initialisation CSV
if [ ! -f "$METRICS_FILE" ]; then
    echo "timestamp,latency_s,bandwidth_MBps,jitter_s" > $METRICS_FILE
fi

LATENCY_PREV=0
UE_NAME="ue1"  # Label pour identifier l'UE

while true; do
    START=$(date +%s.%N)
    HTTP_CODE=$(curl -s -w "%{http_code}" -r 0-$CHUNK_SIZE "$VIDEO_URL" -o /dev/null)
    END=$(date +%s.%N)

    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

    if [[ "$HTTP_CODE" != "200" && "$HTTP_CODE" != "206" ]]; then
        echo "[ERROR] Chunk non reçu (HTTP $HTTP_CODE) à $TIMESTAMP"
    else
        LATENCY=$(echo "$END - $START" | bc -l)
        BANDWIDTH=$(echo "$CHUNK_SIZE / $LATENCY / 1024 / 1024" | bc -l)

        # Calcul du jitter approximatif
        if (( $(echo "$LATENCY_PREV > 0" | bc -l) )); then
            JITTER=$(echo "$LATENCY - $LATENCY_PREV" | bc -l)
        else
            JITTER=0
        fi
        LATENCY_PREV=$LATENCY

        echo "[OK] Chunk reçu à $TIMESTAMP | Latence: ${LATENCY}s | Débit: ${BANDWIDTH} MB/s | Jitter: ${JITTER}s"

        # Sauvegarde CSV
        echo "$TIMESTAMP,$LATENCY,$BANDWIDTH,$JITTER" >> $METRICS_FILE

        # Envoi à Prometheus Pushgateway
        if [ ! -z "$PUSHGATEWAY_URL" ]; then
            TMP_FILE=$(mktemp)
            cat <<EOF > $TMP_FILE
video_chunk_latency_seconds{ue="$UE_NAME"} $LATENCY
video_chunk_bandwidth_mbps{ue="$UE_NAME"} $BANDWIDTH
video_chunk_jitter_seconds{ue="$UE_NAME"} $JITTER
EOF
            curl -s -X POST --data-binary @$TMP_FILE $PUSHGATEWAY_URL
            rm $TMP_FILE
        fi
    fi

    sleep $INTERVAL
done

