# cmdble
Système de commande numérique via Bluetooth 
=======

A new Flutter project.
Main.dart :
1.1. Structure générale et initialisation

Le code commence par l'initialisation de Firebase dans la fonction main():
""" Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MaterialApp(
      home: MyApp(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/admin': (context) => AdminLoginPage(),
        '/admin-dashboard': (context) => AdminDashboard(),
      },
    ),
  );
} """
Cette section configure l'application Flutter et initialise Firebase, ce qui est essentiel pour la communication avec Firestore. Les routes définies (/admin, /admin-dashboard) suggèrent une interface d'administration pour la gestion du restaurant.

1.2. Modèles de données

Le fichier définit plusieurs classes de modèles de données qui représentent les entités de l'application:
• MenuType (Enumération): Définit les catégories de menu (plats, boissons, desserts).
• OrderStatus (Enumération): Définit les différents statuts possibles pour une commande (en attente, en préparation, prête, livrée, annulée).
• MenuItem (Classe): Représente un élément individuel du menu avec des propriétés comme id, image, nom, description, et prix. Il inclut des méthodes fromFirestore et toFirestore pour la sérialisation et désérialisation des données depuis/vers Firestore.
• CartItem (Classe): Représente un article dans le panier d'achat, incluant un MenuItem, sa category et la quantity.
• Order (Classe): Représente une commande client, incluant un id, un tableNumber (remplaçant clientId), une liste de CartItem, le totalAmount, le status, et les timestamps createdAt et updatedAt. Similaire à MenuItem, elle possède des méthodes fromFirestore et toFirestore.
Ces modèles sont cruciaux pour structurer les données échangées avec Firestore et sont répliqués, dans une certaine mesure, dans le fichier Python pour assurer la compatibilité des données.

1.3. Service Firebase (MenuService)

La classe MenuService est le cœur de l'interaction avec Firestore. Elle encapsule la logique pour:
• Récupérer les listes de plats, boissons et desserts (getPlats, getBoissons, getDesserts, getMenuItemsByType). Ces méthodes retournent des Streams, permettant une mise à jour en temps réel de l'interface utilisateur lorsque les données changent dans Firestore.
• Créer de nouvelles commandes (createOrder).
• Récupérer toutes les commandes (getAllOrders) ou les commandes spécifiques à une table (getOrdersByTable).
• Mettre à jour le statut d'une commande (updateOrderStatus).
• Supprimer des commandes (deleteOrder, deleteAllOrders).
Ce service est essentiel pour la gestion backend des données de l'application.

1.4. Interface utilisateur (Pages et Widgets)

Le fichier contient également des composants d'interface utilisateur:
• ClientOrdersPage: Une page dédiée à l'affichage des commandes pour une table spécifique. Elle utilise un StreamBuilder pour écouter les changements de commandes depuis Firestore et met à jour l'UI en conséquence. Elle affiche les détails de la commande et son statut.
• AdminLoginPage: Une page de connexion pour les administrateurs, utilisant Firebase Authentication pour l'authentification par email et mot de passe.
• AdminDashboard: Le tableau de bord de l'administrateur (le code complet n'est pas fourni dans l'extrait, mais sa présence est indiquée par la route et l'utilisation de AdminDashboard).

En résumé, main.dart est une application Flutter complète pour la gestion des commandes et des menus d'un restaurant via Firebase. Il est conçu pour être le client qui consomme des données.


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
