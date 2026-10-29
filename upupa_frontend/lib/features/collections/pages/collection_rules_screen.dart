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
  late CollectionService _service;
  late Collection _currentCollection;
  bool _isSaving = false;

  late TextEditingController _listRuleController;
  late TextEditingController _viewRuleController;
  late TextEditingController _createRuleController;
  late TextEditingController _updateRuleController;
  late TextEditingController _deleteRuleController;

  @override
  void initState() {
    super.initState();
    _currentCollection = widget.collection;
    _service = CollectionService(_currentCollection.name);

    _listRuleController = TextEditingController(
      text: _getRuleCondition('list'),
    );
    _viewRuleController = TextEditingController(
      text: _getRuleCondition('view'),
    );
    _createRuleController = TextEditingController(
      text: _getRuleCondition('create'),
    );
    _updateRuleController = TextEditingController(
      text: _getRuleCondition('update'),
    );
    _deleteRuleController = TextEditingController(
      text: _getRuleCondition('delete'),
    );
  }

  String _getRuleCondition(String type) {
    try {
      final rule = _currentCollection.rules.firstWhere(
        (r) => r.type.toLowerCase() == type.toLowerCase(),
      );
      return rule.condition;
    } catch (_) {
      return '';
    }
  }

  bool _getRuleEnabled(String type) {
    try {
      final rule = _currentCollection.rules.firstWhere(
        (r) => r.type.toLowerCase() == type.toLowerCase(),
      );
      return rule.enabled;
    } catch (_) {
      return true;
    }
  }

  @override
  void dispose() {
    _listRuleController.dispose();
    _viewRuleController.dispose();
    _createRuleController.dispose();
    _updateRuleController.dispose();
    _deleteRuleController.dispose();
    super.dispose();
  }

  void _saveRules() async {
    if (_isSaving || _currentCollection.system) return;

    setState(() {
      _isSaving = true;
    });

    final updatedRules = [
      Rule(
        name: 'List / Search rule',
        type: 'list',
        condition: _listRuleController.text.trim(),
        action: '',
        enabled: _getRuleEnabled('list'),
      ),
      Rule(
        name: 'View rule',
        type: 'view',
        condition: _viewRuleController.text.trim(),
        action: '',
        enabled: _getRuleEnabled('view'),
      ),
      Rule(
        name: 'Create rule',
        type: 'create',
        condition: _createRuleController.text.trim(),
        action: '',
        enabled: _getRuleEnabled('create'),
      ),
      Rule(
        name: 'Update rule',
        type: 'update',
        condition: _updateRuleController.text.trim(),
        action: '',
        enabled: _getRuleEnabled('update'),
      ),
      Rule(
        name: 'Delete rule',
        type: 'delete',
        condition: _deleteRuleController.text.trim(),
        action: '',
        enabled: _getRuleEnabled('delete'),
      ),
    ];

    try {
      final updatedCollection = await _service.updateCollectionRules(
        updatedRules,
      );

      if (!mounted) return;
      setState(() {
        _currentCollection = updatedCollection;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API Rules updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      widget.onUpdate();
    } catch (e) {
      log('Rules update error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update rules: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('API Rules / ${_currentCollection.name}'),
        actions: [
          if (!_currentCollection.system)
            _isSaving
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
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
                    tooltip: 'Save changes',
                    onPressed: _saveRules,
                  ),
        ],
      ),
      body: _currentCollection.system
          ? const Center(
              child: Text(
                'Cannot modify the rules of system collections.',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'All rules follow the filter syntax and operators (e.g., @request.auth.id != "").',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  _buildRuleCard('List / Search rule', _listRuleController),
                  const SizedBox(height: 16),
                  _buildRuleCard('View rule', _viewRuleController),
                  const SizedBox(height: 16),
                  _buildRuleCard('Create rule', _createRuleController),
                  const SizedBox(height: 16),
                  _buildRuleCard('Update rule', _updateRuleController),
                  const SizedBox(height: 16),
                  _buildRuleCard('Delete rule', _deleteRuleController),
                ],
              ),
            ),
    );
  }

  Widget _buildRuleCard(String label, TextEditingController controller) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText:
                  'Leave empty for public, or enter condition (e.g. @request.auth.id != "")',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
