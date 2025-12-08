import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../../core/services/http_appwrite_service.dart';

class AddAnnouncementForm extends StatefulWidget {
  const AddAnnouncementForm({super.key});

  @override
  AddAnnouncementFormState createState() => AddAnnouncementFormState();
}

class AddAnnouncementFormState extends State<AddAnnouncementForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final appwriteService = AppwriteService();

      final data = {
        'title': _titleController.text,
        'content': _contentController.text,
        'date': DateTime.now().toIso8601String(),
      };

      try {
        developer.log('Creating announcement payload: $data');
        final result = await appwriteService.createDocument(
          collectionId: "announcements",
          data: data,
          documentId: 'unique()',
        );

        developer.log('Create announcement response: $result');

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Announcement added successfully!')),
        );
        Navigator.of(context).pop();
      } catch (e, st) {
        developer.log('Failed to create announcement: $e', error: e, stackTrace: st);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add announcement: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Announcement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Content'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the content';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
