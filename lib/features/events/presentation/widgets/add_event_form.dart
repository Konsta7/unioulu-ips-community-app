import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/http_appwrite_service.dart';
import '../../../../core/utils/config.dart';

class EventForm extends StatefulWidget {
  const EventForm({super.key});

  @override
  EventFormState createState() => EventFormState();
}

class EventFormState extends State<EventForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleEnController = TextEditingController();
  final _titleFiController = TextEditingController();
  final _titleSvController = TextEditingController();
  final _locationEnController = TextEditingController();
  final _locationFiController = TextEditingController();
  final _locationSvController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _priceController = TextEditingController();
  final _organizerNameController = TextEditingController();
  final _detailsEnController = TextEditingController();
  final _detailsFiController = TextEditingController();
  final _detailsSvController = TextEditingController();
  final _ticketDetailsEnController = TextEditingController();
  final _ticketDetailsFiController = TextEditingController();
  final _ticketDetailsSvController = TextEditingController();
  final _locationUrlController = TextEditingController();
  List<Map<String, dynamic>> _topics = [];
  List<String> _selectedTags = [];
  File? _selectedPosterPhoto;

  @override
  void initState() {
    super.initState();
    _fetchTopics();
  }

  void _fetchTopics() async {
    final appwriteService = AppwriteService();
    final response = await appwriteService.listDocuments(
        collectionId: "topics");

      final List<dynamic> jsonData = response['documents'];
      setState(() {
        _topics = jsonData
            .map((json) => {'id': json['\$id'], 'text': json['text_en']})
            .toList();
      });
    
  }

  @override
  void dispose() {
    _titleEnController.dispose();
    _titleFiController.dispose();
    _titleSvController.dispose();
    _locationEnController.dispose();
    _locationFiController.dispose();
    _locationSvController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _priceController.dispose();
    _organizerNameController.dispose();
    _detailsEnController.dispose();
    _detailsFiController.dispose();
    _detailsSvController.dispose();
    _ticketDetailsEnController.dispose();
    _ticketDetailsFiController.dispose();
    _ticketDetailsSvController.dispose();
    _locationUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickPosterPhoto() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _selectedPosterPhoto = File(result.files.single.path!);
      });
    }
  }

  Future<String?> _uploadPosterPhoto(AppwriteService appwriteService) async {
    if (_selectedPosterPhoto == null) return null;

    // Replace storage with the actual ID of your Appwrite storage bucket
    final response = await appwriteService.uploadFile(
        bucketId: appwriteBucketId,
        file: _selectedPosterPhoto!,
        fileId: "unique()"
        );

      final fileId = response['\$id'];
      return '${appwriteService.endpoint}/storage/buckets/$appwriteBucketId/files/$fileId/view?project=$appwriteProjectId';
   
  }

  void _submitForm() async {
  if (_formKey.currentState!.validate()) {
    final currentContext = context;
    final appwriteService = AppwriteService();

    // Validate required fields that are not covered by TextForm validators:
    if (_selectedPosterPhoto == null) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Please select a poster photo.')),
      );
      return;
    }

    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Please select at least one topic.')),
      );
      return;
    }

    if (_dateController.text.isEmpty) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Please select a date.')),
      );
      return;
    }

    if (_timeController.text.isEmpty) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Please enter a time.')),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Adding event...')),
      );

      // Upload poster and get URL (throws on failure)
      final posterPhotoUrl = await _uploadPosterPhoto(appwriteService);

      if (!mounted) return;
      if (posterPhotoUrl == null) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Failed to upload poster photo.')),
        );
        return;
      }

      // Build the full data map expected by Appwrite (include required keys)
      final data = {
        'posterPhotoUrl': posterPhotoUrl,
        'topics': _selectedTags.join(','), // store as comma-separated string
        'title_en': _titleEnController.text.trim().isNotEmpty
            ? _titleEnController.text.trim()
            : 'Untitled event',
        'title_fi': _titleFiController.text.trim(),
        'title_sv': _titleSvController.text.trim(),
        'location_en': _locationEnController.text.trim(),
        'location_fi': _locationFiController.text.trim(),
        'location_sv': _locationSvController.text.trim(),
        // Appwrite expects datetime strings for datetime attributes
        'date': _dateController.text,
        'time': _timeController.text.trim(),
        'organizerName': _organizerNameController.text.trim(),
        'details_en': _detailsEnController.text.trim(),
        'details_fi': _detailsFiController.text.trim(),
        'details_sv': _detailsSvController.text.trim(),
        'ticketDetails_en': _ticketDetailsEnController.text.trim(),
        'ticketDetails_fi': _ticketDetailsFiController.text.trim(),
        'ticketDetails_sv': _ticketDetailsSvController.text.trim(),
        'locationUrl': _locationUrlController.text.trim(),
        'price': _priceController.text.trim(),
      };

      // Send to Appwrite — wrap fields under 'data' as Appwrite HTTP API expects
      await appwriteService.createDocument(
        collectionId: "events",
        data: {
          'documentId': 'unique()',
          'data': data,
        },
        documentId: 'unique()',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(currentContext).clearSnackBars();
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Event added successfully!')),
      );
      Navigator.of(currentContext).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('Error adding event: ${e.toString()}')),
      );
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Event'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: _pickPosterPhoto,
                  child: const Text('Select Poster Photo'),
                ),
                if (_selectedPosterPhoto != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child:
                        Text('Selected Photo: ${_selectedPosterPhoto!.path}'),
                  ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  items: _topics.map((topic) {
                    return DropdownMenuItem<String>(
                      value: topic['id'],
                      child: Text(topic['text']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedTags = value != null ? [value] : [];
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Select Topic'),
                  isExpanded: true,
                  initialValue: _selectedTags.isNotEmpty ? _selectedTags.first : null,
                ),
                TextFormField(
                  controller: _titleEnController,
                  decoration:
                      const InputDecoration(labelText: 'Title (English)'),
                ),
                TextFormField(
                  controller: _titleFiController,
                  decoration:
                      const InputDecoration(labelText: 'Title (Finnish)'),
                ),
                TextFormField(
                  controller: _titleSvController,
                  decoration:
                      const InputDecoration(labelText: 'Title (Swedish)'),
                ),
                TextFormField(
                  controller: _locationEnController,
                  decoration:
                      const InputDecoration(labelText: 'Location (English)'),
                ),
                TextFormField(
                  controller: _locationFiController,
                  decoration:
                      const InputDecoration(labelText: 'Location (Finnish)'),
                ),
                TextFormField(
                  controller: _locationSvController,
                  decoration:
                      const InputDecoration(labelText: 'Location (Swedish)'),
                ),
                TextFormField(
                  controller: _dateController,
                  decoration: const InputDecoration(labelText: 'Date'),
                  onTap: () async {
                    DateTime? dateTime = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2050),
                    );
                    setState(() {
                      _dateController.text = dateTime!.toIso8601String();
                    });
                  },
                ),
                TextFormField(
                  controller: _timeController,
                  decoration: const InputDecoration(labelText: 'Time'),
                ),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                ),
                TextFormField(
                  controller: _organizerNameController,
                  decoration:
                      const InputDecoration(labelText: 'Organizer Name'),
                ),
                TextFormField(
                  controller: _detailsEnController,
                  decoration:
                      const InputDecoration(labelText: 'Details (English)'),
                ),
                TextFormField(
                  controller: _detailsFiController,
                  decoration:
                      const InputDecoration(labelText: 'Details (Finnish)'),
                ),
                TextFormField(
                  controller: _detailsSvController,
                  decoration:
                      const InputDecoration(labelText: 'Details (Swedish)'),
                ),
                TextFormField(
                  controller: _ticketDetailsEnController,
                  decoration: const InputDecoration(
                      labelText: 'Ticket Details (English)'),
                ),
                TextFormField(
                  controller: _ticketDetailsFiController,
                  decoration: const InputDecoration(
                      labelText: 'Ticket Details (Finnish)'),
                ),
                TextFormField(
                  controller: _ticketDetailsSvController,
                  decoration: const InputDecoration(
                      labelText: 'Ticket Details (Swedish)'),
                ),
                TextFormField(
                  controller: _locationUrlController,
                  decoration: const InputDecoration(labelText: 'Location URL'),
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
