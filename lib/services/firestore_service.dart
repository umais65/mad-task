import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import 'dart:async';

class FirestoreService {
  final CollectionReference _productsCollection =
      FirebaseFirestore.instance.collection('products');

  // Add Product
  Future<void> addProduct(Product product) async {
    await _productsCollection.add(product.toMap());
  }

  // Update Product
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    await _productsCollection.doc(id).update(data);
  }

  // Delete Product
  Future<void> deleteProduct(String id) async {
    await _productsCollection.doc(id).delete();
  }

  // Get Products Stream
  Stream<List<Product>> getProductsStream() {
    return _productsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}
