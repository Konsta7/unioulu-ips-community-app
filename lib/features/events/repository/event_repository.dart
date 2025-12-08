
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:appwrite/appwrite.dart';
import 'package:community/features/events/data/models/event_like_model.dart';

import '../data/models/event_model.dart';
import 'package:community/core/services/http_appwrite_service.dart';

class EventRepository {
  final AppwriteService appwriteService = AppwriteService();
  
  
 // Fetch all events
  Future<List<EventModel>> getEvents() async {
    try {
      final response = await appwriteService.listDocuments(
        collectionId: "events",
      );

      // Parse the response
      if (response.containsKey('documents') && response['documents'] is List) {
        final documents = response['documents'] as List;
        developer.log('Successfully fetched ${documents.length} events');

        return documents
            .map((doc) {
              try {
                if (doc is Map<String, dynamic>) {
                  return EventModel.fromMap(doc['data'] ?? doc);
                }
                return EventModel.fromMap(jsonDecode(jsonEncode(doc))['data'] ??
                    jsonDecode(jsonEncode(doc)));
              } catch (e) {
                developer.log('Error parsing event document: $e');
                return null;
              }
            })
            .whereType<EventModel>()
            .toList();
      } else {
        throw Exception('Failed to fetch events: ${response.toString()}');
      }
    } catch (e) {
      throw Exception('Failed to fetch events: ${e.toString()}');
    }
  }
  
// Get user's liked events
  Future<List<EventModel>> getUserLikedEvents(String userId) async {
    if (userId == 'anonymous') {
      developer.log('Anonymous user has no likes');
      return []; // Anonymous users have no likes
    }

    try {
      developer.log('Fetching liked events for user $userId');
      final response = await appwriteService.listDocuments(
        collectionId: "event_likes",
        queries: [
          Query.equal('userId', userId),
        ],
      );

      // Parse the response
      if (response.containsKey('documents') && response['documents'] is List) {
        final eventLikes = response['documents'] as List;
        developer.log('Successfully fetched ${eventLikes.length} events');

        if (eventLikes.isEmpty) {
          developer.log('No liked events found');
          return [];
        }

        // Extract the event IDs that the user has liked
        final likedEventIds = eventLikes.map((doc) => doc['eventId']).toList();

        // Query the 'events' collection to fetch the full event data for each liked event
        final eventsResponse = await appwriteService.listDocuments(
          collectionId: 'events',
          queries: [
            Query.contains('\$id', likedEventIds),
          ],
        );

         // Parse and return the list of PostModel objects
      if (eventsResponse.containsKey('documents') && eventsResponse['documents'] is List) {
        final events = eventsResponse['documents'] as List;
        developer.log('Successfully fetched ${events.length} posts');

        return events
            .map((doc) {
              try {
                if (doc is Map<String, dynamic>) {
                  return EventModel.fromMap(doc['data'] ?? doc);
                }
                return EventModel.fromMap(jsonDecode(jsonEncode(doc))['data'] ??
                    jsonDecode(jsonEncode(doc)));
              } catch (e) {
                developer.log('Error parsing post document: $e');
                return null;
              }
            })
            .whereType<EventModel>()
            .toList();
      } else {
        developer.log('No posts found for liked post IDs');
        return [];
      }
    }

    developer.log('No liked posts found or invalid response format');
    return [];
    } catch (e) {
      developer.log('Failed to get liked events: ${e.toString()}');
      return []; // Return empty list on error instead of throwing
    }
  }
  
  // Toggle favorite status
  Future<void> toggleFavorite(String userId, String eventId, bool isFavorite) async {
    if (isFavorite) {
      await unlikeEvent(userId, eventId);
    } else {
      await likeEvent(userId, eventId);
    }
  }
  

   // Like an event (create a like document)
  Future<Map<String, dynamic>> likeEvent(String userId, String eventId) async {
    if (userId == 'anonymous') {
      throw Exception('Anonymous users cannot like events');
    }

    final newLike = EventLikeModel(eventId: eventId, userId: userId);

    try {
      developer.log('Creating like document for user $userId, event $eventId');
      return await appwriteService.createDocument(
        collectionId: "event_likes",
        data: newLike.toJson(),
        documentId: 'unique()',
      );
    } catch (e) {
      developer.log('Failed to like event: ${e.toString()}');
      throw Exception('Failed to like event: ${e.toString()}');
    }
  }

  // Unlike an event (delete the like document)
  Future<void> unlikeEvent(String userId, String eventId) async {
    if (userId == 'anonymous') {
      throw Exception('Anonymous users cannot unlike events');
    }

    try {
      // First find the like document
      developer.log('Finding like document for user $userId, event $eventId');
      final response = await appwriteService.listDocuments(
        collectionId: "event_likes",
        queries: [
          Query.equal('userId', userId),
          Query.equal('eventId', eventId),
        ],
      );

      // Check if document exists and delete it
      if (response.containsKey('documents') &&
          response['documents'] is List &&
          (response['documents'] as List).isNotEmpty) {
        final documentId = response['documents'][0]['\$id'];
        developer.log('Found like document with ID: $documentId, deleting...');

        // Delete the document
        await appwriteService.makeRequest(
          method: 'DELETE',
          endpointPath:
              'databases/${appwriteService.databaseId}/collections/event_likes/documents/$documentId',
        );

        developer.log('Successfully deleted like document');
      } else {
        developer.log('No like document found to delete');
      }
    } catch (e) {
      developer.log('Failed to unlike event: ${e.toString()}');
      throw Exception('Failed to unlike event: ${e.toString()}');
    }
  }

  // Get like count for an event
  Future<int> getEventLikeCount(String eventId) async {
    try {
      developer.log('Fetching like count for event $eventId');
      final response = await appwriteService.listDocuments(
        collectionId: "event_likes",
        queries: [
          Query.equal('eventId', eventId),
        ],
      );

      if (response.containsKey('documents') && response['documents'] is List) {
        final documents = response['documents'] as List;
        developer.log(
            'Successfully fetched ${documents.length} likes for event $eventId');
        return documents.length;
      } else {
        throw Exception('Failed to fetch like count: ${response.toString()}');
      }
    } catch (e) {
      developer.log('Failed to fetch like count: ${e.toString()}');
      throw Exception('Failed to fetch like count: ${e.toString()}');
    }
  }
}