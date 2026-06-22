// upupa_frontend/lib/features/collections/pages/collection_rules_screen.dart
import 'dart:developer';
import 'package:flutter/material.dart';

import '../models/collection.dart';
import '../models/rule.dart';
import '../services/collection_service.dart';

class CollectionRulesScreen extends StatefulWidget {
  final Collection collection;
  final VoidCallback onUpdate;

  const CollectionRulesScreen({
    super.key,
    required this.collection,
    required this.onUpdate,
  });

  @override
  State<CollectionRulesScreen> createState() => _CollectionRulesScreenState();
}

class _CollectionRulesScreenState extends State<CollectionRulesScreen> {
  late List<Rule> _rules;
  late CollectionService _service;
  late Collection _currentCollection;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentCollection = widget.collection;
    _rules = List.from(_currentCollection.rules);
    _service = CollectionService(_currentCollection.name);
  }

  void _onRuleToggle(int index, bool enabled) {
    if (!mounted) return;
    setState(() {
      _rules[index] = _rules[index].copyWith(enabled: enabled);
    });
  }

  void _saveRules() async {
    if (_isSaving) return;

    if (!mounted) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final updatedCollection = await _service.updateCollectionRules(_rules);

      if (!mounted) return;
      setState(() {
        _currentCollection = updatedCollection;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rules updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onUpdate();
    } catch (e) {
      log('Rules update error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentCollection.name} Rules'),
        actions: [
          _isSaving
              ? const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.save),
            onPressed: _currentCollection.system || _isSaving
                ? null
                : _saveRules,
          ),
        ],
      ),
      body: _currentCollection.system
          ? const Center(
        child: Text(
          'Cannot modify the rules of system collections.',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      )
          : ListView.builder(
        itemCount: _rules.length,
        itemBuilder: (context, index) {
          final rule = _rules[index];
          return ListTile(
            title: Text(rule.name),
            subtitle: Text('${rule.type}: ${rule.condition}'),
            trailing: Switch(
              value: rule.enabled,
              onChanged: (enabled) => _onRuleToggle(index, enabled),
            ),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Rule editing is not yet implemented.'),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _currentCollection.system
          ? null
          : FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adding new rules is not yet implemented.'),
            ),
          );
        },
        tooltip: 'Add New Rule',
        child: const Icon(Icons.add),
      ),
    );
  }
}