# cmdble
Système de commande numérique via Bluetooth 
=======

A new Flutter project.

Architecture Technique pour un Système de Commande Numérique basé sur Bluetooth
1. Composants principaux du système
Appareils des clients : Smartphones ou tablettes équipés de Bluetooth (BLE) pour accéder au menu et passer des commandes.
Serveur Bluetooth (Point central) :
Une station de réception ou un serveur local équipé d’un module Bluetooth.
Ce serveur reçoit les commandes et les envoie au système de gestion des commandes ou à la cuisine.
Balises Bluetooth (Beacons) (optionnel) :
Déployées dans différentes sections du restaurant pour élargir la portée du système.
Application mobile ou interface web :
Une application ou une interface PWA (Progressive Web App) accessible après le scan d’un QR Code. (In Memory DB like SQLite, Or use Firebase)
Système backend :
Gestion des commandes, stockage des informations et transmission vers la cuisine.
Peut être hébergé localement sur le serveur Bluetooth ou dans un serveur connecté au réseau local.

2. Processus de fonctionnement
Connexion et découverte via QR Code :
Le QR Code affiché sur la table contient :
Un lien pour télécharger l'application ou ouvrir une interface web.
Les instructions pour jumeler l'appareil via Bluetooth avec le serveur central.
Exploration du menu :
Une fois connecté au serveur Bluetooth, le client accède au menu du restaurant (sous forme de texte ou d’images légères).
Passage de la commande :
Les clients sélectionnent les plats souhaités dans l’interface.
La commande est envoyée via Bluetooth au serveur central, qui l’enregistre.
Gestion des commandes côté serveur :
Le serveur traite la commande et la transmet à la cuisine ou à l’interface des serveurs.
Une confirmation de commande est envoyée au client.
Notifications :
Le serveur peut envoyer des notifications au client via Bluetooth, comme l'état de préparation ou des offres spéciales.

3. Étapes d’implémentation
Étape 1 : Choix des technologies
Serveur Bluetooth : Utilisez des modules Bluetooth comme Raspberry Pi avec des bibliothèques Python (ex. : PyBluez, Bleak).
Application/Interface : Une application Android/iOS ou une PWA développée avec Flutter ou React.
Backend : Python (Flask/Django) ou Node.js pour le traitement des commandes.
Base de données : Firebase, SQLite ou PostgreSQL pour stocker les commandes et les informations du menu.
Étape 2 : Configuration du Bluetooth
Configurez un serveur BLE qui accepte les connexions des appareils des clients.
Implémentez le protocole GATT pour permettre l’échange de données.
Étape 3 : Développement de l’application
Inclure une interface utilisateur pour afficher les menus, ajouter des commandes et visualiser les statuts.
Intégrer une fonction de jumelage Bluetooth via l’application



TODO - Système de Commande Restaurant Bluetooth BLE

## Phase 1: Configuration du serveur Bluetooth BLE sur Raspberry Pi
- [ ] Créer la structure du projet
- [ ] Implémenter le serveur BLE avec protocole GATT
- [ ] Configurer les services et caractéristiques Bluetooth
- [ ] Ajouter la gestion des connexions multiples (minimum 2 appareils)
- [ ] Implémenter les logs de debugging
- [ ] Tester la connectivité BLE

## Phase 2: Configuration de Firebase pour la base de données
- [ ] Configurer Firebase pour les commandes
- [ ] Créer les modèles de données (menu, commandes)
- [ ] Implémenter les fonctions CRUD
- [ ] Tester la connexion Firebase

## Phase 3: Développement de l'interface client Flutter
- [ ] Créer l'application Flutter client
- [ ] Implémenter la connexion Bluetooth
- [ ] Développer l'interface menu
- [ ] Créer le système de panier
- [ ] Implémenter la validation de commande
- [ ] Ajouter le suivi de statut

## Phase 4: Développement de l'interface admin Flutter
- [ ] Créer l'application Flutter admin
- [ ] Implémenter l'authentification
- [ ] Développer l'interface de gestion des commandes
- [ ] Créer la mise à jour des statuts
- [ ] Tester l'interface admin

## Phase 5: Tests et intégration du système complet
- [ ] Tester la communication BLE complète
- [ ] Vérifier l'intégration Firebase
- [ ] Tester les notifications
- [ ] Tests de charge avec plusieurs clients

## Phase 6: Documentation et livraison du projet
- [ ] Créer la documentation technique
- [ ] Rédiger le guide d'installation
- [ ] Préparer les instructions de déploiement
- [ ] Livrer le projet complet

<img width="2138" height="252" alt="deepseek_mermaid_20250808_e6baf3" src="https://github.com/user-attachments/assets/a758e814-1d3e-49b1-b821-1d7d6ddd053e" />


(Premier Projet sur Git)
