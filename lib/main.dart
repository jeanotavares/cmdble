import 'package:cmdble/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
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
}

// Énumération pour les types de menu
enum MenuType { plats, boissons, desserts }

// Énumération pour les statuts de commande
enum OrderStatus {
  pending('En attente'),
  preparing('En préparation'),
  ready('Prête'),
  delivered('Livrée'),
  cancelled('Annulée');

  const OrderStatus(this.displayName);
  final String displayName;
}

// Modèle de données pour les éléments du menu
class MenuItem {
  final String id;
  final String image;
  final String nom;
  final String description;
  final String prix;

  MenuItem({
    required this.id,
    required this.image,
    required this.nom,
    required this.description,
    required this.prix,
  });

  // Constructeur pour créer un objet depuis Firestore
  factory MenuItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return MenuItem(
      id: doc.id,
      image: data['image'] ?? '',
      nom: data['nom'] ?? '',
      description: data['description'] ?? '',
      prix: data['prix'] ?? '',
    );
  }

  // Méthode pour convertir en Map pour Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'image': image,
      'nom': nom,
      'description': description,
      'prix': prix,
    };
  }

  @override
  String toString() {
    return 'MenuItem(id: $id, nom: $nom, prix: $prix)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MenuItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Classe pour représenter un article dans le panier
class CartItem {
  final MenuItem menuItem;
  final String category;
  int quantity;

  CartItem({required this.menuItem, required this.category, this.quantity = 1});

  // Clé unique pour identifier l'article dans le panier
  String get uniqueKey => '${category}_${menuItem.id}';

  Map<String, dynamic> toFirestore() {
    return {
      'menuItem': menuItem.toFirestore(),
      'category': category,
      'quantity': quantity,
      'itemId': menuItem.id,
      'itemName': menuItem.nom,
      'itemPrice': menuItem.prix,
    };
  }
}

// Modèle de données pour les commandes (MODIFIÉ pour utiliser le numéro de table)
class Order {
  final String id;
  final String tableNumber; // Remplace clientId
  final List<CartItem> items;
  final double totalAmount;
  final OrderStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Order({
    required this.id,
    required this.tableNumber,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory Order.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    List<CartItem> items = [];
    if (data['items'] != null) {
      for (var itemData in data['items']) {
        MenuItem menuItem = MenuItem(
          id: itemData['itemId'] ?? '',
          image: itemData['menuItem']['image'] ?? '',
          nom: itemData['itemName'] ?? '',
          description: itemData['menuItem']['description'] ?? '',
          prix: itemData['itemPrice'] ?? '',
        );
        items.add(
          CartItem(
            menuItem: menuItem,
            category: itemData['category'] ?? '',
            quantity: itemData['quantity'] ?? 1,
          ),
        );
      }
    }

    return Order(
      id: doc.id,
      tableNumber:
          data['tableNumber'] ??
          data['clientId'] ??
          '', // Compatibilité avec l'ancien format
      items: items,
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      status: OrderStatus.values.firstWhere(
        (status) => status.name == data['status'],
        orElse: () => OrderStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tableNumber': tableNumber,
      'items': items.map((item) => item.toFirestore()).toList(),
      'totalAmount': totalAmount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}

// Service Firebase pour gérer les données (MODIFIÉ avec nouvelles méthodes)
class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Noms des collections
  static const String _platsCollection = 'plats';
  static const String _boissonsCollection = 'boissons';
  static const String _dessertsCollection = 'desserts';
  static const String _ordersCollection = 'orders';

  // Récupérer les plats
  Stream<List<MenuItem>> getPlats() {
    return _firestore
        .collection(_platsCollection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => MenuItem.fromFirestore(doc)).toList(),
        );
  }

  // Récupérer les boissons
  Stream<List<MenuItem>> getBoissons() {
    return _firestore
        .collection(_boissonsCollection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => MenuItem.fromFirestore(doc)).toList(),
        );
  }

  // Récupérer les desserts
  Stream<List<MenuItem>> getDesserts() {
    return _firestore
        .collection(_dessertsCollection)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => MenuItem.fromFirestore(doc)).toList(),
        );
  }

  // Récupérer les éléments par type
  Stream<List<MenuItem>> getMenuItemsByType(MenuType type) {
    switch (type) {
      case MenuType.plats:
        return getPlats();
      case MenuType.boissons:
        return getBoissons();
      case MenuType.desserts:
        return getDesserts();
    }
  }

  // Obtenir le nom de la collection selon le type
  String getCollectionName(MenuType type) {
    switch (type) {
      case MenuType.plats:
        return _platsCollection;
      case MenuType.boissons:
        return _boissonsCollection;
      case MenuType.desserts:
        return _dessertsCollection;
    }
  }

  // Méthodes pour les commandes
  Future<String> createOrder(Order order) async {
    try {
      DocumentReference docRef = await _firestore
          .collection(_ordersCollection)
          .add(order.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Erreur lors de la création de la commande: $e');
      rethrow;
    }
  }

  Stream<List<Order>> getAllOrders() {
    try {
      return _firestore
          .collection(_ordersCollection)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList(),
          );
    } catch (e) {
      print('Erreur lors de la récupération de toutes les commandes: $e');
      return Stream.value([]);
    }
  }

  // NOUVELLE MÉTHODE : Récupérer les commandes d'une table spécifique
  Stream<List<Order>> getOrdersByTable(String tableNumber) {
    try {
      return _firestore
          .collection(_ordersCollection)
          .where('tableNumber', isEqualTo: tableNumber)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList(),
          );
    } catch (e) {
      print('Erreur lors de la récupération des commandes de la table: $e');
      return Stream.value([]);
    }
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).update({
        'status': status.name,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
      rethrow;
    }
  }

  // NOUVELLE MÉTHODE : Supprimer une commande spécifique
  Future<void> deleteOrder(String orderId) async {
    try {
      await _firestore.collection(_ordersCollection).doc(orderId).delete();
    } catch (e) {
      print('Erreur lors de la suppression de la commande: $e');
      rethrow;
    }
  }

  // NOUVELLE MÉTHODE : Supprimer toutes les commandes
  Future<void> deleteAllOrders() async {
    try {
      WriteBatch batch = _firestore.batch();
      QuerySnapshot snapshot = await _firestore
          .collection(_ordersCollection)
          .get();

      for (DocumentSnapshot doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Erreur lors de la suppression de toutes les commandes: $e');
      rethrow;
    }
  }
}

// NOUVELLE PAGE : Page des commandes pour le client (MODIFIÉE pour utiliser le numéro de table)
class ClientOrdersPage extends StatefulWidget {
  final String tableNumber;

  const ClientOrdersPage({Key? key, required this.tableNumber})
    : super(key: key);

  @override
  _ClientOrdersPageState createState() => _ClientOrdersPageState();
}

class _ClientOrdersPageState extends State<ClientOrdersPage> {
  final MenuService _menuService = MenuService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Commandes - Table ${widget.tableNumber}'),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<List<Order>>(
        stream: _menuService.getOrdersByTable(widget.tableNumber),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.orange),
                  SizedBox(height: 16),
                  Text('Chargement de vos commandes...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                  SizedBox(height: 16),
                  Text(
                    'Vérifiez les règles Firestore pour la collection "orders".',
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune commande trouvée pour la table ${widget.tableNumber}',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Passez votre première commande !',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          List<Order> orders = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildClientOrderCard(orders[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildClientOrderCard(Order order) {
    Color statusColor = _getStatusColor(order.status);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(Icons.receipt, color: Colors.white),
        ),
        title: Text('Commande #${order.id.substring(0, 8)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Table: ${order.tableNumber}'),
            Text('Total: ${order.totalAmount.toStringAsFixed(0)} Fcfa'),
            Text('Statut: ${order.status.displayName}'),
            Text('Date: ${_formatDate(order.createdAt)}'),
          ],
        ),
        onTap: () {
          _showClientOrderDetails(order);
        },
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.delivered:
        return Colors.grey;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showClientOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Détails de ma commande'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Commande #${order.id.substring(0, 8)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Table: ${order.tableNumber}'),
                Text('Date: ${_formatDate(order.createdAt)}'),
                Text('Statut: ${order.status.displayName}'),
                SizedBox(height: 16),
                Text(
                  'Articles:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...order.items.map(
                  (item) => Padding(
                    padding: EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      '${item.quantity}x ${item.menuItem.nom} - ${item.menuItem.prix}',
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Total: ${order.totalAmount.toStringAsFixed(0)} Fcfa',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}

// Page de connexion admin
class AdminLoginPage extends StatefulWidget {
  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/admin-dashboard');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur de connexion: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connexion Administrateur'),
        backgroundColor: Colors.orange,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.admin_panel_settings, size: 80, color: Colors.orange),
              SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer votre mot de passe';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Se connecter',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Dashboard administrateur (MODIFIÉ avec fonctionnalités de suppression)
class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final MenuService _menuService = MenuService();

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Administrateur'),
        backgroundColor: Colors.orange,
        actions: [
          // NOUVEAU : Bouton pour supprimer toutes les commandes
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: () => _showDeleteAllConfirmation(),
            tooltip: 'Supprimer toutes les commandes',
          ),
          IconButton(icon: Icon(Icons.logout), onPressed: _signOut),
        ],
      ),
      body: StreamBuilder<List<Order>>(
        stream: _menuService.getAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                  SizedBox(height: 16),
                  Text(
                    'Vérifiez les règles Firestore pour la collection "orders"',
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Aucune commande trouvée',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          List<Order> orders = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              return _buildOrderCard(orders[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    Color statusColor = _getStatusColor(order.status);

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: Icon(Icons.receipt, color: Colors.white),
        ),
        title: Text('Commande #${order.id.substring(0, 8)}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Table: ${order.tableNumber}'),
            Text('Total: ${order.totalAmount.toStringAsFixed(0)} Fcfa'),
            Text('Statut: ${order.status.displayName}'),
            Text('Date: ${_formatDate(order.createdAt)}'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (String action) {
            if (action.startsWith('status_')) {
              OrderStatus status = OrderStatus.values.firstWhere(
                (s) => s.name == action.substring(7),
              );
              _updateOrderStatus(order.id, status);
            } else if (action == 'delete') {
              _showDeleteConfirmation(order);
            }
          },
          itemBuilder: (BuildContext context) {
            List<PopupMenuEntry<String>> items = [];

            // Ajouter les options de statut
            items.addAll(
              OrderStatus.values.map((OrderStatus status) {
                return PopupMenuItem<String>(
                  value: 'status_${status.name}',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                        size: 16,
                        color: _getStatusColor(status),
                      ),
                      SizedBox(width: 8),
                      Text(status.displayName),
                    ],
                  ),
                );
              }).toList(),
            );

            // Ajouter un séparateur
            items.add(PopupMenuDivider());

            // NOUVEAU : Ajouter l'option de suppression
            items.add(
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            );

            return items;
          },
          child: Icon(Icons.more_vert),
        ),
        onTap: () {
          _showOrderDetails(order);
        },
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.delivered:
        return Colors.grey;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _updateOrderStatus(String orderId, OrderStatus status) async {
    try {
      await _menuService.updateOrderStatus(orderId, status);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut de la commande mis à jour'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // NOUVELLE MÉTHODE : Confirmation de suppression d'une commande
  void _showDeleteConfirmation(Order order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Confirmer la suppression'),
            ],
          ),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer la commande #${order.id.substring(0, 8)} de la table ${order.tableNumber} ?\n\nCette action est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteOrder(order.id);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Supprimer', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // NOUVELLE MÉTHODE : Confirmation de suppression de toutes les commandes
  void _showDeleteAllConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Supprimer toutes les commandes'),
            ],
          ),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer TOUTES les commandes ?\n\nCette action supprimera définitivement toutes les commandes de la base de données et ne peut pas être annulée.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAllOrders();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(
                'Supprimer tout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // NOUVELLE MÉTHODE : Supprimer une commande
  Future<void> _deleteOrder(String orderId) async {
    try {
      await _menuService.deleteOrder(orderId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Commande supprimée avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // NOUVELLE MÉTHODE : Supprimer toutes les commandes
  Future<void> _deleteAllOrders() async {
    try {
      await _menuService.deleteAllOrders();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Toutes les commandes ont été supprimées'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOrderDetails(Order order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Détails de la commande'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ID: ${order.id}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Table: ${order.tableNumber}'),
                Text('Date: ${_formatDate(order.createdAt)}'),
                Text('Statut: ${order.status.displayName}'),
                SizedBox(height: 16),
                Text(
                  'Articles:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...order.items.map(
                  (item) => Padding(
                    padding: EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                      '${item.quantity}x ${item.menuItem.nom} - ${item.menuItem.prix}',
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Total: ${order.totalAmount.toStringAsFixed(0)} Fcfa',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fermer'),
            ),
          ],
        );
      },
    );
  }
}

// Application principale (MODIFIÉE pour utiliser le numéro de table)
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() {
    return MyAppState();
  }
}

class MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  final MenuService _menuService = MenuService();
  String _tableNumber = '5'; // Remplace _clientId

  // Panier avec les articles complets (STRUCTURE INCHANGÉE)
  Map<String, CartItem> _cart = {};

  // Types de menu correspondant aux onglets
  final List<MenuType> _menuTypes = [
    MenuType.plats,
    MenuType.boissons,
    MenuType.desserts,
  ];

  // Titres pour chaque type de menu
  final Map<MenuType, String> _menuTitles = {
    MenuType.plats: 'Plats',
    MenuType.boissons: 'Boissons',
    MenuType.desserts: 'Desserts',
  };

  @override
  void initState() {
    super.initState();
    _loadTableNumber();
  }

  // NOUVELLE MÉTHODE : Charger ou demander le numéro de table
  Future<void> _loadTableNumber() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedTableNumber = prefs.getString('tableNumber');

    if (storedTableNumber == null) {
      // Demander le numéro de table à l'utilisateur
      await _askForTableNumber();
    } else {
      _tableNumber = storedTableNumber;
      setState(() {});
    }
  }

  // NOUVELLE MÉTHODE : Demander le numéro de table
  Future<void> _askForTableNumber() async {
    final _tableController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Numéro de Table'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Veuillez entrer le numéro de votre table ou scanner le QR code.',
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _tableController,
                decoration: InputDecoration(
                  labelText: 'Numéro de table',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.table_restaurant),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (_tableController.text.isNotEmpty) {
                  _tableNumber = _tableController.text;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('tableNumber', _tableNumber);
                  Navigator.of(context).pop();
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text('Confirmer', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // En-tête (STRUCTURE INCHANGÉE)
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(150),
        child: AppBar(
          title: Center(
            child: Text(
              "Menu Restaurant - ${_menuTitles[_menuTypes[_selectedIndex]]}",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/accueil.png"),
                fit: BoxFit.fill,
              ),
            ),
          ),
          actions: [
            // MODIFIÉ : Bouton "Mes Commandes" utilise maintenant le numéro de table
            IconButton(
              icon: Icon(Icons.receipt_long, color: Colors.white),
              onPressed: () {
                if (_tableNumber.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Numéro de table non défini'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ClientOrdersPage(tableNumber: _tableNumber),
                  ),
                );
              },
            ),
            // Bouton Admin (INCHANGÉ)
            IconButton(
              icon: Icon(Icons.admin_panel_settings, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, '/admin');
              },
            ),
          ],
        ),
      ),
      // Corps (STRUCTURE INCHANGÉE)
      body: _buildMenuContent(),
      // Bouton flottant (STRUCTURE INCHANGÉE)
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: () {
          _showCartSummary();
        },
        child: Badge(
          label: Text("${_getTotalItems()}"),
          backgroundColor: Colors.deepOrangeAccent,
          child: Icon(Icons.room_service),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
      // Barre de navigation (STRUCTURE INCHANGÉE)
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu),
            label: "Plats",
          ),
          NavigationDestination(icon: Icon(Icons.local_bar), label: "Boissons"),
          NavigationDestination(icon: Icon(Icons.icecream), label: "Desserts"),
        ],
      ),
    );
  }

  // Construire le contenu du menu selon l'onglet sélectionné (STRUCTURE INCHANGÉE)
  Widget _buildMenuContent() {
    MenuType currentMenuType = _menuTypes[_selectedIndex];

    return StreamBuilder<List<MenuItem>>(
      stream: _menuService.getMenuItemsByType(currentMenuType),
      builder: (context, snapshot) {
        // État de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        // Gestion des erreurs
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error);
        }

        // Aucune donnée
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(currentMenuType);
        }

        // Affichage des données
        List<MenuItem> menuItems = snapshot.data!;
        return _buildMenuList(menuItems);
      },
    );
  }

  // État de chargement (INCHANGÉ)
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.orange),
          SizedBox(height: 16),
          Text(
            'Chargement du menu...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // État d'erreur (INCHANGÉ)
  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            'Erreur de connexion',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Vérifiez votre connexion internet',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {}); // Relancer le build pour retry
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  // État vide (INCHANGÉ)
  Widget _buildEmptyState(MenuType menuType) {
    String menuName = _menuTitles[menuType]!.toLowerCase();
    IconData icon;

    switch (menuType) {
      case MenuType.plats:
        icon = Icons.restaurant_menu;
        break;
      case MenuType.boissons:
        icon = Icons.local_bar;
        break;
      case MenuType.desserts:
        icon = Icons.icecream;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Aucun $menuName disponible',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Revenez plus tard',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Liste des éléments du menu (INCHANGÉ)
  Widget _buildMenuList(List<MenuItem> menuItems) {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        return _buildMenuCard(menuItems[index]);
      },
    );
  }

  // Carte d'un élément du menu (INCHANGÉ)
  Widget _buildMenuCard(MenuItem item) {
    //String currentCategory = _menuTypes[_selectedIndex].name;
    //String uniqueKey = '${currentCategory}_${item.id}';
    //int quantity = _cart[uniqueKey]?.quantity ?? 0;

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 2,
      child: ListTile(
        leading: _buildItemImage(item.image),
        title: Text(
          item.nom,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.description,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            SizedBox(height: 4),
            Text(
              item.prix,
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        trailing: _buildCounterWidget(item),
        onTap: () {
          _showItemDetails(item);
        },
      ),
    );
  }

  // Image de l'élément (INCHANGÉ)
  Widget _buildItemImage(String imagePath) {
    if (imagePath.isEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }

    // Si l'image commence par http, c'est une URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: Icon(Icons.broken_image, color: Colors.grey),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                color: Colors.grey[200],
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            },
          ),
        ),
      );
    } else {
      // Sinon, c'est un asset local
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: Icon(Icons.broken_image, color: Colors.grey),
              );
            },
          ),
        ),
      );
    }
  }

  // Widget compteur avec gestion du panier (INCHANGÉ)
  Widget _buildCounterWidget(MenuItem item) {
    String currentCategory = _menuTypes[_selectedIndex].name;
    String uniqueKey = '${currentCategory}_${item.id}';
    int quantity = _cart[uniqueKey]?.quantity ?? 0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: quantity > 0
                  ? () {
                      _removeFromCart(item);
                    }
                  : null,
              iconSize: 20,
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '$quantity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                _addToCart(item);
              },
              iconSize: 20,
            ),
          ],
        ),
      ],
    );
  }

  // Ajouter un article au panier (INCHANGÉ)
  void _addToCart(MenuItem item) {
    String currentCategory = _menuTypes[_selectedIndex].name;
    String uniqueKey = '${currentCategory}_${item.id}';

    setState(() {
      if (_cart.containsKey(uniqueKey)) {
        _cart[uniqueKey]!.quantity++;
      } else {
        _cart[uniqueKey] = CartItem(
          menuItem: item,
          category: currentCategory,
          quantity: 1,
        );
      }
    });

    // Afficher un message de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.add_shopping_cart, color: Colors.white),
            SizedBox(width: 8),
            Text('${item.nom} ajouté au panier'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  // Retirer un article du panier (INCHANGÉ)
  void _removeFromCart(MenuItem item) {
    String currentCategory = _menuTypes[_selectedIndex].name;
    String uniqueKey = '${currentCategory}_${item.id}';

    setState(() {
      if (_cart.containsKey(uniqueKey)) {
        if (_cart[uniqueKey]!.quantity > 1) {
          _cart[uniqueKey]!.quantity--;
        } else {
          _cart.remove(uniqueKey);
        }
      }
    });

    // Afficher un message de confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.remove_shopping_cart, color: Colors.white),
            SizedBox(width: 8),
            Text('${item.nom} retiré du panier'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 1),
      ),
    );
  }

  // Afficher les détails d'un élément (INCHANGÉ)
  void _showItemDetails(MenuItem item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(item.nom),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.image.isNotEmpty)
                Container(
                  height: 200,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildItemImage(item.image),
                  ),
                ),
              SizedBox(height: 16),
              Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(item.description),
              SizedBox(height: 8),
              Text(
                'Prix: ${item.prix}',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  // Afficher le résumé du panier (STRUCTURE INCHANGÉE)
  void _showCartSummary() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.shopping_cart, color: Colors.orange),
              SizedBox(width: 8),
              Text('Panier (${_getTotalItems()} articles)'),
            ],
          ),
          content: _cart.isEmpty
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Votre panier est vide',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                )
              : Container(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Liste des articles avec détails
                      Container(
                        constraints: BoxConstraints(maxHeight: 300),
                        child: SingleChildScrollView(
                          child: Column(children: _buildCartItemsList()),
                        ),
                      ),
                      SizedBox(height: 16),
                      // Résumé total
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Articles:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${_getTotalItems()}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Prix total:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _formatPrice(_getTotalPrice()),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[800],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          actions: _cart.isEmpty
              ? [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Fermer'),
                  ),
                ]
              : [
                  // Bouton Supprimer tout
                  TextButton.icon(
                    onPressed: () {
                      _showDeleteConfirmation(context);
                    },
                    icon: Icon(Icons.delete, color: Colors.red),
                    label: Text(
                      'Supprimer',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  // Bouton Commander tout
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _processOrder();
                    },
                    icon: Icon(Icons.shopping_bag),
                    label: Text('Commander'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
        );
      },
    );
  }

  // Construire la liste des articles du panier avec détails (INCHANGÉ)
  List<Widget> _buildCartItemsList() {
    return _cart.values.map((cartItem) {
      MenuItem item = cartItem.menuItem;
      int quantity = cartItem.quantity;
      String categoryName = cartItem.category;

      return Card(
        margin: EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Container(
            width: 50,
            height: 50,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildItemImage(item.image),
            ),
          ),
          title: Text(item.nom, style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$categoryName - ${item.description}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12),
              ),
              Text(
                item.prix,
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          trailing: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'x$quantity',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  // Afficher la confirmation de suppression (INCHANGÉ)
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 8),
              Text('Confirmer la suppression'),
            ],
          ),
          content: Text(
            'Êtes-vous sûr de vouloir vider votre panier ? Cette action supprimera tous les articles ajoutés.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fermer la confirmation
                Navigator.of(context).pop(); // Fermer le panier
                _clearCart();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Panier vidé avec succès'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Supprimer', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Traiter la commande (MODIFIÉ pour ne plus demander nom/téléphone)
  void _processOrder() {
    if (_tableNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Numéro de table non défini'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Passer directement la commande sans demander nom/téléphone
    _placeOrder();
  }

  // Passer la commande (MODIFIÉ pour utiliser le numéro de table et afficher le prix total)
  Future<void> _placeOrder() async {
    try {
      double totalPrice = _getTotalPrice(); // Calculer le prix total

      Order order = Order(
        id: '',
        tableNumber: _tableNumber, // Utilise le numéro de table
        items: _cart.values.toList(),
        totalAmount: totalPrice,
        status: OrderStatus.pending,
        createdAt: DateTime.now(),
      );

      String orderId = await _menuService.createOrder(order);

      setState(() {
        _cart.clear();
      });

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Commande confirmée'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Votre commande a été confirmée avec succès !',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Numéro de commande:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '#${orderId.substring(0, 8)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Table: $_tableNumber',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      SizedBox(height: 8),
                      // NOUVEAU : Affichage du prix total dans la confirmation
                      Text(
                        'Montant total: ${_formatPrice(totalPrice)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.restaurant, color: Colors.white),
                          SizedBox(width: 8),
                          Text('Commande en préparation...'),
                        ],
                      ),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 3),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la commande: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Obtenir le nombre total d'articles (INCHANGÉ)
  int _getTotalItems() {
    return _cart.values.fold(0, (sum, cartItem) => sum + cartItem.quantity);
  }

  // Obtenir le prix total du panier (INCHANGÉ)
  double _getTotalPrice() {
    return _cart.values.fold(0.0, (sum, cartItem) {
      // Extraire le prix numérique de la chaîne (ex: "3000 Fcfa" -> 3000.0)
      String priceString = cartItem.menuItem.prix.replaceAll(
        RegExp(r'[^0-9.]'),
        '',
      );
      double price = double.tryParse(priceString) ?? 0.0;
      return sum + (price * cartItem.quantity);
    });
  }

  // Formater le prix pour l'affichage (INCHANGÉ)
  String _formatPrice(double price) {
    return '${price.toStringAsFixed(0)} Fcfa';
  }

  // Vider le panier (INCHANGÉ)
  void _clearCart() {
    setState(() {
      _cart.clear();
    });
  }
}
