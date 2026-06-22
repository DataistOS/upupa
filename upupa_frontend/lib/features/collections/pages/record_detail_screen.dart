// upupa_frontend/lib/features/collections/pages/record_detail_screen.dart
import 'dart:developer';
import 'package:flutter/material.dart';

import '../models/collection.dart';
import '../models/record.dart';
import '../services/collection_service.dart';
import '../widgets/record_form.dart';

class RecordDetailScreen extends StatefulWidget {
  final Collection collection;
  final String? recordId;

  const RecordDetailScreen({
    super.key,
    required this.collection,
    this.recordId,
  });

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
  final GlobalKey<RecordFormState> _recordFormKey = GlobalKey<RecordFormState>();
  Record? _record;
  bool _isLoading = true;
  bool get _isEditMode => widget.recordId != null;
  late CollectionService _service;

  @override
  void initState() {
    super.initState();
    _service = CollectionService(widget.collection.name);
    if (_isEditMode) {
      _fetchRecord();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _fetchRecord() async {
    try {
      final record = await _service.getRecord(widget.recordId!);
      if (!mounted) return;
      setState(() {
        _record = record;
        _isLoading = false;
      });
    } catch (e) {
      log('Error fetching record: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load record: ${e.toString()}')),
      );
    }
  }

  Future<void> _saveRecord() async {
    if (_recordFormKey.currentState == null) return;

    try {
      final data = _recordFormKey.currentState!.getFormData();

      if (!mounted) return;
      setState(() {
        _isLoading = true;
      });

      Record savedRecord;
      if (_isEditMode && _record != null) {
        savedRecord = await _service.updateRecord(_record!.id, data);
      } else {
        savedRecord = await _service.createRecord(data);
      }

      if (!mounted) return;
      setState(() {
        _record = savedRecord;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode
              ? 'Record updated successfully!'
              : 'Record created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      log('Save record error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save record: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Record' : 'New Record'),
        actions: [
          _isLoading
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
            onPressed: _saveRecord,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RecordForm(
        key: _recordFormKey,
        collection: widget.collection,
        record: _record,
      ),
    );
  }
}