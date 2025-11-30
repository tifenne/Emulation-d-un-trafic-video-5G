# Base légère Ubuntu
FROM ubuntu:22.04

# Installer ffmpeg, nginx et wget
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y ffmpeg nginx wget curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Créer dossier pour la vidéo
RUN mkdir -p /var/www/html/videos

# Copier une vidéo locale (optionnel) ou télécharger une vidéo d'exemple
# COPY BigBuckBunny.mp4 /var/www/html/videos/video.mp4
RUN wget http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4 \
    -O /var/www/html/videos/video.mp4

# Configurer Nginx pour servir la vidéo
RUN cat > /etc/nginx/sites-available/default <<'EOF'
server {
    listen 8080;
    location /videos/ {
        alias /var/www/html/videos/;
        add_header Access-Control-Allow-Origin *;
        types {
            video/mp4 mp4;
        }
    }
}
EOF

# Exposer le port pour le streaming
EXPOSE 8080

# Commande par défaut pour démarrer Nginx
CMD ["nginx", "-g", "daemon off;"]

