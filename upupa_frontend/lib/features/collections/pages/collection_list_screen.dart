// upupa_frontend/lib/features/collections/pages/collection_list_screen.dart
import 'dart:developer';
import 'package:flutter/material.dart';

import '../../auth/services/auth_service.dart';
import '../models/collection.dart';
import '../services/collection_service.dart';
import '../widgets/collection_list_item.dart';
import '../widgets/create_collection_dialog.dart';
import 'collection_schema_screen.dart';
import 'collection_rules_screen.dart';
import 'record_list_screen.dart';

class CollectionListScreen extends StatefulWidget {
  const CollectionListScreen({super.key});

  @override
  State<CollectionListScreen> createState() => _CollectionListScreenState();
}

class _CollectionListScreenState extends State<CollectionListScreen> {
  late Future<List<Collection>> _collectionsFuture;

  @override
  void initState() {
    super.initState();
    _fetchCollections();
  }

  void _fetchCollections() {
    setState(() {
      _collectionsFuture = CollectionService.getCollections();
    });
  }

  void _refreshCollections() {
    _fetchCollections();
  }

  void _navigateToRecords(Collection collection) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordListScreen(collection: collection),
      ),
    );
    if (result == true) {
      _refreshCollections();
    }
  }

  void _navigateToSchema(Collection collection) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionSchemaScreen(
          collection: collection,
          onUpdate: _refreshCollections,
        ),
      ),
    );
    _refreshCollections();
  }

  void _navigateToRules(Collection collection) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CollectionRulesScreen(
          collection: collection,
          onUpdate: _refreshCollections,
        ),
      ),
    );
    _refreshCollections();
  }

  void _showCreateDialog() {
    showDialog<String>(
      context: context,
      builder: (context) => const CreateCollectionDialog(),
    ).then((collectionName) async {
      if (collectionName != null && collectionName.isNotEmpty) {
        try {
          await CollectionService.createCollection(collectionName);
          _refreshCollections();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Collection "$collectionName" created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          log('Collection creation error: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  void _deleteCollection(Collection collection) {
    if (collection.system) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete system collections.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
            'Are you sure you want to delete the collection "${collection.name}" and all its records?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          final service = CollectionService(collection.name);
          await service.deleteCollection();

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
              Text('Collection "${collection.name}" deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _refreshCollections();
        } catch (e) {
          log('Collection deletion error: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshCollections,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService().logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Collection>>(
        future: _collectionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            log('Error loading collections: ${snapshot.error}');
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${snapshot.error.toString().split(':').last.trim()}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshCollections,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No collections found. Start by creating one!'),
            );
          } else {
            final collections = snapshot.data!;
            return ListView.builder(
              itemCount: collections.length,
              itemBuilder: (context, index) {
                final collection = collections[index];

                return CollectionListItem(
                  collection: collection,
                  onRecordsTap: () => _navigateToRecords(collection),
                  onSchemaEdit: () => _navigateToSchema(collection),
                  onRulesEdit: () => _navigateToRules(collection),
                  onDelete: () => _deleteCollection(collection),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        tooltip: 'Create New Collection',
        child: const Icon(Icons.add),
      ),
    );
  }
}