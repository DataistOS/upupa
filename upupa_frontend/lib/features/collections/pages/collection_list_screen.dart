// upupa_frontend/lib/features/collections/pages/collection_list_screen.dart
import 'dart:developer';
import 'package:flutter/material.dart';

import '../../auth/services/auth_service.dart';
import '../../auth/pages/profile_screen.dart';
import '../../settings/pages/settings_screen.dart';
import '../../logs/pages/logs_screen.dart';

import '../models/collection.dart';
import '../services/collection_service.dart';
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
  Collection? _selectedCollection;
  bool _showLogs = false;

  @override
  void initState() {
    super.initState();
    _fetchCollections();
  }

  void _fetchCollections() {
    setState(() {
      _collectionsFuture = CollectionService.getCollections().then((
        collections,
      ) {
        return collections;
      });
    });
  }

  void _refreshCollections() {
    _fetchCollections();
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
              content: Text(
                'Collection "$collectionName" created successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          log('Collection creation error: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 260,
            color: const Color(0xFF1F2937),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCollection = null;
                            _showLogs = false;
                          });
                        },
                        child: const Text(
                          'Upupa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.person_outline,
                              color: Colors.white70,
                              size: 20,
                            ),
                            tooltip: 'Profile & Overview',
                            onPressed: () {
                              setState(() {
                                _selectedCollection = null;
                                _showLogs = false;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.show_chart,
                              color: Colors.white70,
                              size: 20,
                            ),
                            tooltip: 'Request Logs',
                            onPressed: () {
                              setState(() {
                                _selectedCollection = null;
                                _showLogs = true;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.settings_outlined,
                              color: Colors.white70,
                              size: 20,
                            ),
                            tooltip: 'Settings',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.logout,
                              color: Colors.white70,
                              size: 20,
                            ),
                            tooltip: 'Logout',
                            onPressed: () {
                              AuthService().logout();
                              Navigator.of(
                                context,
                              ).pushReplacementNamed('/login');
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Collections',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white54,
                          size: 16,
                        ),
                        onPressed: _refreshCollections,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Collection>>(
                    future: _collectionsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white54,
                          ),
                        );
                      } else if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'No collections',
                            style: TextStyle(color: Colors.white54),
                          ),
                        );
                      }

                      final collections = snapshot.data!;
                      return ListView.builder(
                        itemCount: collections.length,
                        itemBuilder: (context, index) {
                          final collection = collections[index];
                          final isSelected =
                              _selectedCollection?.id == collection.id;

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: Colors.blue.withValues(
                              alpha: 0.2,
                            ),
                            leading: Icon(
                              collection.system
                                  ? Icons.lock
                                  : Icons.folder_outlined,
                              color: isSelected
                                  ? Colors.blueAccent
                                  : Colors.white70,
                              size: 20,
                            ),
                            title: Text(
                              collection.name,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white70,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _selectedCollection = collection;
                                _showLogs = false;
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    onPressed: _showCreateDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New collection'),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _selectedCollection != null
                ? Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        color: Colors.white,
                        child: Row(
                          children: [
                            Text(
                              'Collections / ${_selectedCollection!.name}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF374151),
                              ),
                            ),
                            const Spacer(),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _navigateToSchema(_selectedCollection!),
                              icon: const Icon(Icons.code, size: 16),
                              label: const Text('Schema'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _navigateToRules(_selectedCollection!),
                              icon: const Icon(Icons.rule, size: 16),
                              label: const Text('API Rules'),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, thickness: 1),
                      Expanded(
                        child: RecordListScreen(
                          key: ValueKey(_selectedCollection!.id),
                          collection: _selectedCollection!,
                        ),
                      ),
                    ],
                  )
                : _showLogs
                ? const LogsScreen()
                : const ProfileScreen(),
          ),
        ],
      ),
    );
  }
}
