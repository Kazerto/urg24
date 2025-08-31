import 'package:flutter/foundation.dart';
import '../models/pharmacy_model.dart';
import '../models/stock_model.dart';

class CartItem {
  final String productId;
  final String productName;
  final double unitPrice;
  int quantity;
  final String category;
  final String description;

  CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
    required this.category,
    required this.description,
  });

  double get totalPrice => unitPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'category': category,
      'description': description,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      quantity: map['quantity'] ?? 0,
      category: map['category'] ?? '',
      description: map['description'] ?? '',
    );
  }
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};
  PharmacyModel? _selectedPharmacy;

  Map<String, CartItem> get cartItems => {..._items};
  
  PharmacyModel? get selectedPharmacy => _selectedPharmacy;

  int get itemCount {
    return _items.values.fold(0, (total, item) => total + item.quantity);
  }

  double get totalAmount {
    return _items.values.fold(0.0, (total, item) => total + item.totalPrice);
  }

  List<CartItem> get itemsList => _items.values.toList();

  bool get isEmpty => _items.isEmpty;

  CartItem? getCartItem(String productId) {
    return _items[productId];
  }

  void setSelectedPharmacy(PharmacyModel pharmacy) {
    _selectedPharmacy = pharmacy;
    notifyListeners();
  }

  void addToCart(StockModel product) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity++;
    } else {
      _items[product.id] = CartItem(
        productId: product.id,
        productName: product.medicamentName,
        unitPrice: product.price,
        quantity: 1,
        category: product.category,
        description: product.description,
      );
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void incrementQuantity(String productId) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(String productId) {
    if (_items.containsKey(productId)) {
      if (_items[productId]!.quantity > 1) {
        _items[productId]!.quantity--;
      } else {
        _items.remove(productId);
      }
      notifyListeners();
    }
  }

  void updateQuantity(String productId, int quantity) {
    if (_items.containsKey(productId)) {
      if (quantity <= 0) {
        _items.remove(productId);
      } else {
        _items[productId]!.quantity = quantity;
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _selectedPharmacy = null;
    notifyListeners();
  }

  // Méthodes pour la sauvegarde et restauration du panier
  Map<String, dynamic> toMap() {
    return {
      'items': _items.map((key, item) => MapEntry(key, item.toMap())),
      'selectedPharmacy': _selectedPharmacy?.toMap(),
    };
  }

  void fromMap(Map<String, dynamic> map) {
    _items.clear();
    
    if (map['items'] != null) {
      final itemsMap = Map<String, dynamic>.from(map['items']);
      itemsMap.forEach((key, value) {
        _items[key] = CartItem.fromMap(Map<String, dynamic>.from(value));
      });
    }

    if (map['selectedPharmacy'] != null) {
      _selectedPharmacy = PharmacyModel.fromMap(
        Map<String, dynamic>.from(map['selectedPharmacy']),
        map['selectedPharmacy']['id'] ?? ''
      );
    }

    notifyListeners();
  }
}