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



## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

(Premiere sauvegarde sur Git)
