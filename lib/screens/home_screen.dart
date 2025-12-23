import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'add_edit_product_screen.dart';
import 'login_screen.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ShopEase'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Sign out and clear prefs
              await context.read<FirebaseService>().signOut();
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', false);

              if (context.mounted) {
                 Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Greeting Section
          if (user != null)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, snapshot) {
                String name = user.email ?? 'User';
                if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                   final data = snapshot.data!.data() as Map<String, dynamic>?;
                   if (data != null && data.containsKey('name')) {
                     name = data['name'];
                   }
                }
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.blue.shade50,
                  child: Text(
                    'Welcome, $name!',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          
          // Products List
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: firestoreService.getProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final products = snapshot.data ?? [];

                if (products.isEmpty) {
                  return const Center(child: Text('No products available.'));
                }

                return ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: Hero(
                          tag: product.id,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              image: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(product.imageUrl!),
                                      fit: BoxFit.cover)
                                  : null,
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(8),
                            ),
                             child: product.imageUrl == null || product.imageUrl!.isEmpty
                                ? const Icon(Icons.shopping_bag)
                                : null,
                          ),
                        ),
                        title: Text(product.name),
                        subtitle: Text('\$${product.price}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddEditProductScreen(product: product),
                                  ),
                                );
                              },
                            ),
                             IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                firestoreService.deleteProduct(product.id);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                           Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditProductScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
