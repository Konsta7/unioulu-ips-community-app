import 'package:community/core/theme/app_spacing.dart';
import 'package:community/features/events/data/models/event_model.dart';
import 'package:community/features/events/presentation/widgets/event_card.dart';
import 'package:flutter/material.dart';
import '../../../../core/services/http_appwrite_service.dart';
import '../../../events/presentation/pages/event_detail_page.dart';

class LatestEventsWidget extends StatefulWidget {
  const LatestEventsWidget({super.key});

  @override
  LatestEventsWidgetState createState() => LatestEventsWidgetState();
}

class LatestEventsWidgetState extends State<LatestEventsWidget> {
  late AppwriteService _appwriteService;
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _appwriteService = AppwriteService();
    _fetchLatestEvents();
  }

  Future<void> _fetchLatestEvents() async {
    try {
      final response = await _appwriteService.listDocuments(
        collectionId: "events",
      );

      if (!mounted) return;

      final List<dynamic> jsonData = response['documents'];

      // Sort by date if available
      final sortedEvents = jsonData
        ..sort((a, b) =>
            DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));

      // Limit to 3 latest events
      setState(() {
        _events = sortedEvents.take(3).toList().cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_hasError) {
      return const Center(child: Text('Failed to load events.'));
    }

    if (_events.isEmpty) {
      return const Center(child: Text('No upcoming events.'));
    }

    // Calculate card width once here
    final cardWidth = MediaQuery.of(context).size.width * 0.8;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.smallPadding,
            top: AppSpacing.defaultPadding,
          ),
          child: Text(
            'Latest Events',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),

        // Fix: Add a fixed height container for the ListView
        SizedBox(
          height: 250, // Set an appropriate fixed height
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.defaultPadding,
                horizontal: AppSpacing.smallPadding),
            itemCount: _events.length,
            itemBuilder: (context, index) {
              final event = EventModel.fromMap(_events[index]);
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailsPage(event: event),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.smallPadding),
                  child: EventCard(event: event),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
