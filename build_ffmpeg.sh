#!/bin/bash
set -e

# Nom de l'image
IMAGE_NAME="ffmpeg-server"
IMAGE_TAG="latest"
TAR_FILE="${IMAGE_NAME}.tar"

echo "Construire l'image Docker ${IMAGE_NAME}:${IMAGE_TAG} ==="
sudo docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .

echo "Vérifier l'image Docker ==="
sudo docker images | grep ${IMAGE_NAME}

echo "Exporter l'image en tar ==="
sudo docker save ${IMAGE_NAME}:${IMAGE_TAG} -o ${TAR_FILE}
echo "Image exportée : ${TAR_FILE}"

echo "Importer l'image dans K3s (containerd) ==="
sudo k3s ctr image import ${TAR_FILE}

echo "Vérifier que l'image est disponible dans K3s ==="
sudo k3s ctr images ls | grep ${IMAGE_NAME}

echo “Image ${IMAGE_NAME}:${IMAGE_TAG} prête pour K3s"

