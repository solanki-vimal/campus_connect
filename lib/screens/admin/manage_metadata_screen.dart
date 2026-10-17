import 'package:flutter/material.dart';
import '../../services/admin_settings_service.dart';
import '../../widgets/confirm_delete_dialog.dart';

class ManageMetadataScreen extends StatefulWidget {
  final String title;
  final String collectionPath;
  final String itemLabel;
  final IconData icon;

  const ManageMetadataScreen({
    super.key,
    required this.title,
    required this.collectionPath,
    required this.itemLabel,
    required this.icon,
  });

  @override
  State<ManageMetadataScreen> createState() => _ManageMetadataScreenState();
}

class _ManageMetadataScreenState extends State<ManageMetadataScreen> {
  final AdminSettingsService _settingsService = AdminSettingsService();
  late final Stream<List<String>> _dataStream;

  @override
  void initState() {
    super.initState();
    _dataStream = _settingsService.streamNames(widget.collectionPath);
  }

  Future<void> _showAddDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String enteredText = '';
        return AlertDialog(
          title: Text('Add New ${widget.itemLabel}'),
          content: TextField(
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: '${widget.itemLabel} Name',
              border: const OutlineInputBorder(),
            ),
            onChanged: (val) => enteredText = val,
            onSubmitted: (val) => Navigator.pop(dialogContext, val.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, enteredText.trim()),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      await _settingsService.addName(widget.collectionPath, result);
    }
  }

  Future<void> _showEditDialog(String oldName) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String enteredText = oldName;
        return AlertDialog(
          title: Text('Edit ${widget.itemLabel}'),
          content: TextFormField(
            initialValue: oldName,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: '${widget.itemLabel} Name',
              border: const OutlineInputBorder(),
            ),
            onChanged: (val) => enteredText = val,
            onFieldSubmitted: (val) => Navigator.pop(dialogContext, val.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, enteredText.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty && result != oldName) {
      await _settingsService.updateName(widget.collectionPath, oldName, result);
    }
  }

  Future<void> _confirmDelete(String name) async {
    final confirm = await showDeleteConfirmDialog(
      context,
      itemLabel: widget.itemLabel,
      itemName: name,
    );

    if (confirm == true) {
      await _settingsService.deleteName(widget.collectionPath, name);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder<List<String>>(
        stream: _dataStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading data'));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Text(
                'No ${widget.itemLabel}s found.\nTap + to add one.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final name = items[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Icon(widget.icon),
                ),
                title: Text(name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                      tooltip: 'Edit',
                      onPressed: () => _showEditDialog(name),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(name),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
