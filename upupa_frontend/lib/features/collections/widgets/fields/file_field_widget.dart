// upupa_frontend/lib/features/collections/widgets/fields/file_field_widget.dart
import 'package:flutter/material.dart';
import 'base_field_widget.dart';

class FileFieldWidget extends StatelessWidget {
  final String name;
  final bool required;
  final String fileName;
  final bool isUploading;
  final VoidCallback onUploadPressed;

  const FileFieldWidget({
    super.key,
    required this.name,
    required this.required,
    required this.fileName,
    required this.isUploading,
    required this.onUploadPressed,
  });

  @override
  Widget build(BuildContext context) {
    return BaseFieldLayout(
      label: name,
      required: required,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: name,
          suffixText: required ? '*' : '',
          border: const OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                fileName.isNotEmpty ? fileName : 'No file selected',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fileName.isNotEmpty ? Colors.black : Colors.grey,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: isUploading ? null : onUploadPressed,
              icon: isUploading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file, size: 16),
              label: const Text('Upload'),
            ),
          ],
        ),
      ),
    );
  }
}
