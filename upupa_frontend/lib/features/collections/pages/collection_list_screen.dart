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
import '../widgets/collection_list_item.dart';
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

  final Set<String> _pinnedCollectionIds = {};

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
        if (_selectedCollection != null) {
          final exists = collections.any(
            (c) => c.id == _selectedCollection!.id,
          );
          if (!exists) {
            _selectedCollection = null;
          }
        }
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
    if (!mounted) return;
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
    if (!mounted) return;
    _refreshCollections();
  }

  void _togglePin(Collection collection) {
    setState(() {
      if (_pinnedCollectionIds.contains(collection.id)) {
        _pinnedCollectionIds.remove(collection.id);
      } else {
        _pinnedCollectionIds.add(collection.id);
      }
    });
  }

  void _showRenameDialog(Collection collection) {
    final controller = TextEditingController(text: collection.name);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Rename Collection: ${collection.name}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty && newName != collection.name) {
                final messenger = ScaffoldMessenger.of(dialogContext);
                Navigator.pop(dialogContext);

                try {
                  await CollectionService(
                    collection.name,
                  ).renameCollection(newName);

                  if (!mounted) return;
                  _refreshCollections();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Collection renamed successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Collection collection) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Collection'),
        content: Text(
          'Are you sure you want to delete "${collection.name}"? All related records will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(dialogContext);
              Navigator.pop(dialogContext);

              try {
                await CollectionService(collection.name).deleteCollection();

                if (!mounted) return;
                if (_selectedCollection?.id == collection.id) {
                  setState(() {
                    _selectedCollection = null;
                  });
                }
                _refreshCollections();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Collection deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() async {
    final collectionName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const CreateCollectionDialog(),
    );

    if (!mounted) return;

    if (collectionName != null && collectionName.isNotEmpty) {
      final messenger = ScaffoldMessenger.of(context);

      try {
        await CollectionService.createCollection(collectionName);

        if (!mounted) return;
        _refreshCollections();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Collection "$collectionName" created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        log('Collection creation error: $e');
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.person_outline,
                              color: Colors.white70,
                              size: 18,
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
                              size: 18,
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
                              size: 18,
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
                              size: 18,
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
                        tooltip: 'Refresh Collections',
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

                      var collections = snapshot.data!;

                      collections.sort((a, b) {
                        final aPinned = _pinnedCollectionIds.contains(a.id);
                        final bPinned = _pinnedCollectionIds.contains(b.id);
                        if (aPinned && !bPinned) return -1;
                        if (!aPinned && bPinned) return 1;
                        return 0;
                      });

                      return ListView.builder(
                        itemCount: collections.length,
                        itemBuilder: (context, index) {
                          final collection = collections[index];
                          final isPinned = _pinnedCollectionIds.contains(
                            collection.id,
                          );

                          return CollectionListItem(
                            collection: collection,
                            isPinned: isPinned,
                            onRecordsTap: () {
                              setState(() {
                                _selectedCollection = collection;
                                _showLogs = false;
                              });
                            },
                            onSchemaEdit: () => _navigateToSchema(collection),
                            onRulesEdit: () => _navigateToRules(collection),
                            onRename: () => _showRenameDialog(collection),
                            onPinToggle: () => _togglePin(collection),
                            onDelete: () => _confirmDelete(collection),
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
