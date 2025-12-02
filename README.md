# Emulation d'un trafic vidéo 5G
NexSlice - Emulation d'un trafic vidéo 5G

**Projet**: 2
**Groupe**: 4  
**Étudiants**: Tifenne Jupiter, Emilie Melis, Eya Walha  
**Année**: 2025-2026

# Introduction

## Contexte

La 5G introduit le **Network Slicing**, permettant de créer des réseaux virtuels logiques sur une infrastructure physique commune. Chaque slice peut être optimisé pour des cas d'usage spécifiques:

- **eMBB (SST=1)**: Enhanced Mobile Broadband → Streaming vidéo, haute débit
- **URLLC (SST=2)**: Ultra-Reliable Low Latency → Applications critiques
- **mMTC (SST=3)**: Massive Machine Type Communications → IoT massif

**Comment valider et mesurer la qualité de service (QoS) du streaming vidéo à travers un slice 5G eMBB dans un environnement simulé ?**

---

# Objectifs

Notre projet s'appuie sur l'infrastructure **NexSlice** ([lien GitHub](https://github.com/AIDY-F2N/NexSlice/tree/k3s)) qui fournit un Core 5G OAI complet déployé sur Kubernetes.
L’objectif est de déployer un serveur vidéo (FFmpeg + nginx) sur Kubernetes et de réaliser des tests de streaming vidéo sur le slice eMBB (SST = 1). Cela permettra de mesurer les performances réseau (latence, débit, jitter), de capturer et d’analyser le trafic afin de confirmer le routage via l’UPF, et de mettre en place une supervision en temps réel avec Prometheus et Grafana. Cette supervision inclura la création de tableaux de bord pour visualiser les métriques 5G et l’automatisation de l’export de ces métriques vers Prometheus.

---

# État de l'Art

## 1. Contexte général

Avec la 5G, le Network Slicing permet de découper le réseau en plusieurs tranches dédiées à différents usages (eMBB, URLLC, mMTC). Les outils classiques comme ping ou iperf3 mesurent surtout la latence ou le débit, mais ne reflètent pas vraiment le comportement réel d'applications comme le streaming vidéo HD.


C'est pourquoi de nombreux travaux cherchent aujourd'hui à mieux émuler ou analyser un trafic vidéo réaliste, afin d'évaluer l'impact du slicing sur les performances et la qualité perçue par l'utilisateur.

## 2. Expérimentations vidéo dans des environnements 5G

Des expérimentations récentes menées avec la pile OpenAirInterface (OAI) et des UEs virtuels montrent comment le débit, la latence et la stabilité vidéo interagissent, et proposent des méthodologies adaptées à des plateformes entièrement virtualisées comme NexSlice (source 1).

D'autres démonstrations autour de la vidéosurveillance en temps réel mettent en avant la capacité du slicing à réduire la latence et stabiliser le flux, illustrant l'intérêt de cette approche pour des services exigeants comme les flux eMBB (source 7).

## 3. Modélisation et estimation de la QoE

Plusieurs travaux proposent des modèles reliant les métriques réseau (débit, latence, pertes) à la QoE, ce qui permet d'interpréter les performances du réseau du point de vue de l'utilisateur final (source 3).

D'autres recherches se focalisent sur la vidéo Ultra-HD, en utilisant des indicateurs tels que PSNR, SSIM ou VMAF pour mieux caractériser la qualité perçue (source 5).

Des méthodes d'adaptation basées sur MPEG-DASH, associées à l'évaluation automatique de l'image, offrent également des pistes pour configurer efficacement des pipelines vidéo comme GStreamer dans un contexte eMBB (source 10).

## 4. Adaptation dynamique et optimisation énergétique

Des architectures intégrant la virtualisation des fonctions réseau montrent qu'il est possible d'adapter la qualité vidéo en tenant compte à la fois de la QoE et de la consommation énergétique. Ces approches s'inscrivent dans la même logique que NexSlice, qui cherche à orchestrer intelligemment les ressources selon la demande (source 2).

## 5. Fiabilité et résilience du streaming en 5G

Des études menées sur les réseaux à ondes millimétriques mettent en avant l'intérêt de la multi-connectivité et du network coding pour stabiliser le débit et réduire la variabilité du flux (source 6).

D'autres analyses montrent aussi que la congestion dans la RAN influence directement la lecture vidéo (par exemple via QUIC), en provoquant des interruptions liées aux files d'attente radio — un phénomène qu'il est possible de reproduire dans un environnement émulé comme OAI/NexSlice (source 9).

## 6. Slicing orienté QoE et isolation des services

Certaines architectures récentes de RAN slicing sont conçues pour optimiser la QoE et garantir une isolation stricte entre services. Elles insistent sur la nécessité de corréler automatiquement les métriques réseau et les indicateurs de qualité perçue afin d'allouer les ressources au bon moment. Ce principe rejoint directement les objectifs du slice eMBB dans NexSlice (source 8).

## 7. Apprentissage automatique et prédiction de la QoE

Des travaux s'appuyant sur le Machine Learning montrent qu'il est possible de prédire la QoE vidéo à partir de paramètres mesurés en temps réel (débit, gigue, rebuffering, pertes). Ces approches ouvrent la voie à une orchestration proactive du slicing, capable d'anticiper les besoins de qualité. Elles sont transférables au fonctionnement de NexSlice (source 4).

## 8. Synthèse et positionnement

L'ensemble des recherches met en évidence plusieurs tendances fortes :

- L'utilisation croissante d'environnements virtualisés (OAI, UEs logiciels) pour tester des flux vidéo réalistes
- La nécessité de combiner mesures réseau (QoS) et qualité perçue (QoE)
- L'intérêt d'utiliser de vrais pipelines vidéo (VLC, GStreamer) pour reproduire fidèlement les comportements clients
- Le développement d'approches de slicing orientées QoE, parfois couplées au Machine Learning

Le projet NexSlice s'inscrit pleinement dans cette dynamique. En intégrant un trafic vidéo applicatif dans une infrastructure OAI virtualisée, il permet d'étudier précisément comment le slicing influence la performance et la qualité perçue. Cela constitue une avancée importante vers une évaluation plus réaliste et automatisée des services eMBB.

---

# Architecture

## 1. Vue d'Ensemble
```
┌──────────────────────────────────────────────────────────────────────┐
│ Infrastructure NexSlice (Fournie par le Prof)                        │
│                                                                       │
│ ┌────────────────────────────────────────────────────────┐          │
│ │ Core 5G OAI (Kubernetes - namespace nexslice)          │          │
│ │ AMF │ SMF │ UPF │ NRF │ AUSF │ UDM │ PCF │ UDR         │          │
│ └──────────────────┬─────────────────────────────────────┘          │
│                    │                                                 │
│         ┌──────────┴──────────┐                                     │
│         │ gNB (UERANSIM)      │                                     │
│         └──────────┬──────────┘                                     │
│                    │                                                 │
│         ┌──────────┴──────────┐                                     │
│         │ UE (UERANSIM)       │                                     │
│         │ Interface: uesimtun0│                                     │
│         │ IP: 12.1.1.2        │                                     │
│         │ Slice: SST=1 (eMBB) │                                     │
│         └──────────┬──────────┘                                     │
└────────────────────┼──────────────────────────────────────────────┘
                     │
                     │ Trafic 5G via tunnel
                     │
          ┌──────────▼──────────┐
          │ UPF Gateway          │
          │ 12.1.1.1             │
          └──────────┬──────────┘
                     │
          ┌──────────▼──────────┐
          │ Serveur Vidéo        │
          │ FFmpeg + nginx       │
          │ (Kubernetes Service) │
          └──────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│ Stack de Monitoring (Notre Contribution)                             │
│                                                                       │
│ ┌────────────────────────────────────────────────────────┐          │
│ │ Namespace monitoring (Kubernetes)                       │          │
│ │                                                          │          │
│ │  ┌─────────────┐  ┌──────────────┐  ┌──────────────┐  │          │
│ │  │ Prometheus  │◄─│ Pushgateway  │◄─│ Scripts Test │  │          │
│ │  │   :30090    │  │    :30091    │  │  (export)    │  │          │
│ │  └──────┬──────┘  └──────────────┘  └──────────────┘  │          │
│ │         │                                               │          │
│ │  ┌──────▼──────┐                                       │          │
│ │  │  Grafana    │ ← Dashboard temps réel                │          │
│ │  │   :30300    │   + Alertes configurables             │          │
│ │  └─────────────┘                                       │          │
│ └────────────────────────────────────────────────────────┘          │
└──────────────────────────────────────────────────────────────────────┘
```

## 2. Composants Utilisés

| Composant | Technologie | Rôle |
|-----------|-------------|------|
| **Core 5G** | OpenAirInterface (OAI) | Fonctions réseau 5G (AMF, SMF, UPF...) |
| **RAN** | UERANSIM | Simulation gNB et UE |
| **Orchestration** | Kubernetes (k3s) | Déploiement des services |
| **Serveur Vidéo** | FFmpeg + nginx | Streaming vidéo HTTP |
| **Monitoring** | Prometheus + Grafana | Collecte et visualisation des métriques |
| **Export Métriques** | Pushgateway | Interface entre scripts et Prometheus |
| **Namespace** | `nexslice`, `monitoring` | Isolation des ressources K8s |


## 3. Fichier Vidéo de Test

- **URL**: http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4
- **Format**: MP4 (H.264 + AAC)
- **Taille**: ~158 MB
- **Durée**: ~10 minutes


---
# Expérimentation

## 1. Résultats dans l’infrastructure NexSlice (Core 5G)

Pour déployer la vidéo, nous avons testé 3 serveurs : 
- **VLC server** : échec (server instable, pas de flux exploitable).
- **GStreamer** : échec (problèmes de configuration, non finalisé).
- **FFmpeg + nginx** : **succès**.

**Conclusion  :**  
- Serveur vidéo ffmpeg dockerisé fonctionnel dans NexSlice.  

---
# Déploiement 

## 1. Pré-requis dans les pods UERANSIM

Avant d’exécuter des scripts ou faire des tests réseau, installer les utilitaires nécessaires :

```bash
sudo k3s kubectl exec -it <pod-ue> -n nexslice -- apt update
sudo k3s kubectl exec -it <pod-ue> -n nexslice -- apt install -y bc
```


## 2. Construction de l’image Docker du serveur vidéo (FFmpeg)

Construire l’image :

```bash
sudo docker build -t ffmpeg-server:latest .
```

Vérifier que l’image existe :

```bash
sudo docker images | grep ffmpeg-server
```

Pour le script d’automatisation :

```bash
chmod +x build_ffmpeg.sh
./build_ffmpeg.sh
```


## 3. Vérification du cluster K3s

S’assurer que le cluster est opérationnel :

```bash
sudo k3s kubectl get nodes
sudo k3s kubectl get ns
```


## 4. Déploiement du serveur vidéo dans Kubernetes

Déployer :

```bash
sudo k3s kubectl apply -f ffmpeg-server-deployment.yaml
```

Vérifier que les pods tournent :

```bash
sudo k3s kubectl get pods -n nexslice | grep ffmpeg
```

Consulter les logs :

```bash
sudo k3s kubectl logs -n nexslice ffmpeg-server -f
```


## 5. Test interne via un pod temporaire

Créer un pod test et vérifier l’accès HTTP :

```bash
sudo k3s kubectl run test-client --image=ubuntu:22.04 -n nexslice -it --rm -- bash
```

Dans le pod test :

```bash
apt-get update && apt-get install -y curl
curl -I http://ffmpeg-server.nexslice.svc.cluster.local:8080/videos/video.mp4
```


## 6. Configuration d’un UE UERANSIM

Lister les pods UE :

```bash
sudo k3s kubectl get pods -n nexslice | grep ueransim-ue
```

Ouvrir un shell dans un UE :

```bash
sudo k3s kubectl exec -it -n nexslice <pod-ueransim-ue1> -- bash
```

Dans le pod :

```bash
apt-get update && apt-get install -y curl
ip addr show uesimtun0
```


## 7. Émulation d’un flux vidéo depuis un UE

Créer un dossier dans le pod UE :

```bash
sudo k3s kubectl exec -it <pod-ue> -n nexslice -- mkdir -p /home/ueransim
```

Copier le script :

```bash
sudo k3s kubectl cp stream_video.sh nexslice/<pod-ue>:/home/ueransim/stream_video.sh
```

Rendre le script exécutable :

```bash
sudo k3s kubectl exec -it <pod-ue> -n nexslice -- chmod +x /home/ueransim/stream_video.sh
```

Lancer le streaming :

```bash
sudo k3s kubectl exec -it <pod-ue> -n nexslice -- /home/ueransim/stream_video.sh
```

<img width="1081" height="182" alt="Capture d&#39;écran 2025-11-30 181143" src="https://github.com/user-attachments/assets/ed8bb421-72cd-4a06-beaa-33bc670b865a" />


## 8. Monitoring – Prometheus & Grafana 

1. **Port-forward Prometheus & Grafana**

```bash
kubectl port-forward svc/prometheus -n monitoring 30090:9090
```
```bash
kubectl port-forward svc/grafana -n monitoring 30300:3000
```
Accéder à [http://localhost:30090](http://localhost:30090) et à [http://localhost:30300](http://localhost:30300) (`admin`/`admin`)


2. **Ajouter Prometheus comme datasource**
   
   URL : `http://prometheus.monitoring.svc.cluster.local:9090`
   Puis cliquez sur "Save & Test". 

3. **Vérifier les métriques Prometheus**

```bash
kubectl port-forward svc/prometheus -n monitoring 30090:9090
```

Rechercher : `video_chunk_latency_seconds`, `video_chunk_bandwidth_mbps`, `video_chunk_jitter_seconds`

4. **Créer un dashboard Grafana**

* Ajouter un panel par métrique, filtrer par UE si besoin :

```promql
video_chunk_latency_seconds{ue="ue1"}
video_chunk_bandwidth_mbps{ue="ue1"}
video_chunk_jitter_seconds{ue="ue1"}
```

* Ajuster axes et style, puis enregistrer.
  
<img width="1710" height="894" alt="Capture d&#39;écran 2025-12-02 000122" src="https://github.com/user-attachments/assets/6d5bc9a3-418e-4db8-bafa-718bef8b6c89" />
<img width="1713" height="907" alt="Capture d&#39;écran 2025-12-02 000330" src="https://github.com/user-attachments/assets/a2c56765-d9b6-4ca0-a9c1-d1e2bb8d77ec" />

---
# Résultat

- Script de streaming incrémental fonctionnel côté UE (avec CSV local pour la collecte des métriques).  
- Export automatique des métriques vers Prometheus et Grafana opérationnel.

---
# Notes

En mode “standalone” (sans infra NexSlice)

En fin de projet, l’infrastructure NexSlice n’était plus entièrement opérationnelle (problèmes de Core / UPF et d’accès à l’UE). Pour conserver une démonstration fonctionnelle, nous avons ajouté un mode **standalone** exécuté sur machine locale (macOS).

Ce mode ne passe **pas** par la 5G ni par NexSlice, mais reprend la **même logique de scripts** pour :

- tester la connectivité réseau de base : `scripts/test-connectivity-standalone.sh`  
- télécharger une vidéo HTTP : `scripts/test-video-streaming-standalone.sh`  
- mesurer latence / jitter / stats interface : `scripts/measure-performance-standalone.sh`.

Ces tests montrent que :
  - la machine a bien accès à Internet,
  - la vidéo HTTP est correctement téléchargée,
  - on peut calculer des métriques réseau de base (RTT, jitter, pertes, débit HTTP) sur **une interface locale**.
    
---

# Références

[1] Agarwal, B. et al. (2023). Analysis of real-time video streaming and throughput performance using the OpenAirInterface stack on multiple UEs. IEEE CSCN.

[2] Nightingale, J. et al. (2016). QoE-Driven, Energy-Aware Video Adaptation in 5G Networks: The SELFNET Self-Optimisation Use Case.

[3] Baena, C. et al. (2020). Estimation of Video Streaming KQIs for Radio Access Negotiation in Network Slicing Scenarios.

[4] Tiwari, V. et al. (2022). A QoE Framework for Video Services in 5G Networks with Supervised Machine Learning Approach.

[5] Aston Research Group (2018). 5G-QoE: QoE Modelling for Ultra-HD Video Streaming in 5G Networks.

[6] Drago, I. et al. (2017). Reliable Video Streaming over mmWave with Multi-Connectivity and Network Coding. arXiv.

[7] Pedreño Manresa, J. J. et al. (2021). A Latency-Aware Real-Time Video Surveillance Demo: Network Slicing for Improving Public Safety. OFC / arXiv.

[8] DeSlice Project (2023). An Architecture for QoE-Aware and Isolated RAN Slicing. Sensors.

[9] JSidhu, J. S. et al. (2025). From 5G RAN Queue Dynamics to Playback: A Performance Analysis for QUIC Video Streaming. arXiv.

[10] Kanai, K. et al. (Université Waseda). Methods for Adaptive Video Streaming and Picture Quality Assessment to Improve QoS/QoE Performances.

---
Ce projet est développé dans le cadre d'un projet académique à Telecom SudParis.




