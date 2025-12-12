import 'package:flutter/material.dart';
import '../../../../core/services/http_appwrite_service.dart';
import '../../../../core/utils/icon_map.dart';
import '../../../../core/utils/icon_names.dart';

class TopicForm extends StatefulWidget {
  const TopicForm({super.key});

  @override
  TopicFormState createState() => TopicFormState();
}

class TopicFormState extends State<TopicForm> {
  final _formKey = GlobalKey<FormState>();
  final _textEnController = TextEditingController();
  final _textFiController = TextEditingController();
  final _textSvController = TextEditingController();
  String? _selectedIconName;

  @override
  void dispose() {
    _textEnController.dispose();
    _textFiController.dispose();
    _textSvController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    // Store context before async gap
    final currentContext = context;

    if (_formKey.currentState!.validate()) {
      try {
        // Show loading indicator
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Adding topic...')),
        );

        // Retrieve the AppwriteService instance
        final appwriteService = AppwriteService();

        // Create the data object to send
        final data = {
          'text_en': _textEnController.text,
          'text_fi': _textFiController.text,
          'text_sv': _textSvController.text,
          'icon': _selectedIconName ?? '📋', // Default icon
        };

        // Make an HTTP request to add a new topic
        await appwriteService.createDocument(
          collectionId: 'topics',
          data: data,
          documentId: 'unique()', // Pass as separate parameter
        );

        // Check if widget is still in the tree before using context
        if (!mounted) return;

        // Show success message and navigate back
        ScaffoldMessenger.of(currentContext).clearSnackBars();
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Topic added successfully!')),
        );
        Navigator.of(currentContext).pop(); // Close the form on success
      } catch (e) {
        // Check if widget is still in the tree before using context
        if (!mounted) return;

        // Show error message
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Error adding topic: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Topic'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _textEnController,
                  decoration:
                      const InputDecoration(labelText: 'Text (English)'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the text in English';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _textFiController,
                  decoration:
                      const InputDecoration(labelText: 'Text (Finnish)'),
                ),
                TextFormField(
                  controller: _textSvController,
                  decoration:
                      const InputDecoration(labelText: 'Text (Swedish)'),
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  initialValue: _selectedIconName,
                  items: iconNames.map((iconName) {
                    return DropdownMenuItem<String>(
                      value: iconName,
                      child: Center(
                          child: Icon(iconMap[iconName] ?? Icons.help,
                              size: 40.0)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedIconName = value;
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Select Icon'),
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
