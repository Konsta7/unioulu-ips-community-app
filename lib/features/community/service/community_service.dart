import 'dart:convert';
import 'dart:developer' as developer;

import 'package:appwrite/appwrite.dart';
import 'package:community/core/services/http_appwrite_service.dart';
import 'package:community/features/community/data/models/comment_model.dart';
import 'package:community/features/community/data/models/post_model.dart';

class CommunityService {
  final AppwriteService _appwriteService;

  CommunityService({required AppwriteService appwriteService})
      : _appwriteService = appwriteService;

  // Vote on a poll
  Future<void> voteOnPoll(String postId, int optionIndex) async {
    // TODO: Implement the voting logic
  }

  // get users liked commentIds
  Future<List<dynamic>> getUserLikedCommentIds(String userId) async {
    if (userId == 'anonymous') {
      developer.log('Anonymous user has no likes');
      return [];
    }

    try {
      final response = await _appwriteService.listDocuments(
        collectionId: 'comment_likes',
        queries: [
          Query.equal('userId', userId),
        ],
      );

      if (response.containsKey('documents') && response['documents'] is List) {
        final documents = response['documents'] as List;
        return documents.map((doc) => doc['commentId']).toList();
      } else {
        throw Exception('Failed to fetch liked comment IDs');
      }
    } catch (e) {
      throw Exception('Failed to fetch liked comment IDs: $e');
    }
  }

  Future<List<PostModel>> getPosts({
    int? limit = 50,
    bool sortByLatest = true,
  }) async {
    List<String> queries = [];

    // Add sorting query
    if (sortByLatest) {
      queries.add(Query.orderDesc('\$createdAt'));
    }

    if (limit != null) {
      queries.add(Query.limit(limit));
    }

    final response = await _appwriteService.listDocuments(
      collectionId: "posts",
      queries: queries,
    );

    if (response.containsKey('documents') && response['documents'] is List) {
      final documents = response['documents'] as List;

      // Convert to PostModel objects
      final posts = documents
          .map((doc) {
            try {
              if (doc is Map<String, dynamic>) {
                return PostModel.fromMap(doc['data'] ?? doc);
              }
              return null;
            } catch (e) {
              return null;
            }
          })
          .whereType<PostModel>()
          .toList();

      // Get all post IDs
      final postIds = posts.map((p) => p.id).toList();

      // Fetch like counts for all posts at once
      final likeCounts = await getPostLikeCounts(postIds);
      
      // Fetch comment counts 
      final commentCounts = await getPostCommentCounts(postIds);

      // Update posts with like counts and comment counts
      for (int i = 0; i < posts.length; i++) {
        final likeCount = likeCounts[posts[i].id] ?? 0;
        final commentCount = commentCounts[posts[i].id] ?? 0; 
        posts[i] = posts[i].copyWith(
          likeCount: likeCount,
          commentCount: commentCount, 
        );
      }

      return posts;
    } else {
      throw Exception('Failed to fetch posts: ${response.toString()}');
    }
  }

  // Add a comment to a post
  Future<CommentModel> addComment(
      String postId, String text, String username) async {
    if (username == 'anonymous') {
      throw Exception('Anonymous users cannot add comments');
    }

    try {
      final response = await _appwriteService.createDocument(
        collectionId: 'comments',
        data: {
          'postId': postId,
          'text': text,
          'username': username,
          'dateTime': DateTime.now().toIso8601String(),
        },
        documentId: 'unique()',
      );
      return response.containsKey('data')
          ? CommentModel.fromMap(response['data'])
          : CommentModel.fromMap(response);
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

// Get comments for a post
  Future<List<CommentModel>> getPostComments(String postId) async {
    try {
      final response = await _appwriteService.listDocuments(
        collectionId: 'comments',
        queries: [
          Query.equal('postId', postId),
        ],
      );

      if (response.containsKey('documents') && response['documents'] is List) {
        final documents = response['documents'] as List;
        return documents
            .map((doc) {
              try {
                if (doc is Map<String, dynamic>) {
                  return CommentModel.fromMap(doc['data'] ?? doc);
                }
                return null;
              } catch (e) {
                return null;
              }
            })
            .whereType<CommentModel>()
            .toList();
      } else {
        throw Exception('Failed to fetch comments: ${response.toString()}');
      }
    } catch (e) {
      throw Exception('Failed to fetch comments: ${e.toString()}');
    }
  }

// Get like count for a post
  Future<int> getPostLikeCount(String postId) async {
    try {
      final response = await _appwriteService.listDocuments(
        collectionId: 'post_likes',
        queries: [
          Query.equal('postId', postId),
        ],
      );

      if (response.containsKey('documents') && response['documents'] is List) {
        return (response['documents'] as List).length;
      } else {
        throw Exception('Failed to fetch like count: ${response.toString()}');
      }
    } catch (e) {
      throw Exception('Failed to fetch like count: ${e.toString()}');
    }
  }

// Get posts liked by a user
  Future<List<PostModel>> getUserLikedPosts(String userId) async {
    if (userId == 'anonymous') {
      developer.log('Anonymous user has no likes');
      return [];
    }

    try {
      // Step 1: Get all liked post IDs from the 'post_likes' collection
      final response = await _appwriteService.listDocuments(
        collectionId: 'post_likes',
        queries: [
          Query.equal('userId', userId),
        ],
      );

      if (response.containsKey('documents') && response['documents'] is List) {
        final postLikes = response['documents'] as List;

        if (postLikes.isEmpty) {
          developer.log('No likes found for user');
          return [];
        }

        // Extract the post IDs that the user has liked
        final likedPostIds = postLikes.map((doc) => doc['postId']).toList();

        // Query the 'posts' collection to fetch the full post data for each liked post
        final postsResponse = await _appwriteService.listDocuments(
          collectionId: 'posts',
          queries: [
            Query.contains('\$id', likedPostIds),
          ],
        );

        // Parse and return the list of PostModel objects
        if (postsResponse.containsKey('documents') &&
            postsResponse['documents'] is List) {
          final posts = postsResponse['documents'] as List;
          developer.log('Successfully fetched ${posts.length} posts');

          return posts
              .map((doc) {
                try {
                  if (doc is Map<String, dynamic>) {
                    return PostModel.fromMap(doc);
                  }
                  return PostModel.fromMap(jsonDecode(jsonEncode(doc)));
                } catch (e) {
                  developer.log('Error parsing post document: $e');
                  return null;
                }
              })
              .whereType<PostModel>()
              .toList();
        } else {
          developer.log('No posts found for liked post IDs');
          return [];
        }
      }

      developer.log('No liked posts found or invalid response format');
      return [];
    } catch (e) {
      developer.log('Failed to get liked posts: ${e.toString()}');
      return [];
    }
  }

  // Lika a commment (create a like document)
  Future<Map<String, dynamic>> likeComment(
      String userId, String commentId) async {
    if (userId == 'anonymous') {
      throw Exception('Anonymous users cannot like comments');
    }

    final newLike = {
      'commentId': commentId,
      'userId': userId,
    };

    try {
      return await _appwriteService.createDocument(
        collectionId: 'comment_likes',
        data: newLike,
        documentId: 'unique()',
      );
    } catch (e) {
      throw Exception('Failed to like comment: $e');
    }
  }

  // Like a post (create a like document)
  Future<Map<String, dynamic>> likePost(String userId, String postId) async {
    if (userId == 'anonymous') {
      throw Exception('Anonymous users cannot like posts');
    }

    final newLike = {
      'postId': postId,
      'userId': userId,
    };

    try {
      return await _appwriteService.createDocument(
        collectionId: 'post_likes',
        data: newLike,
        documentId: 'unique()',
      );
    } catch (e) {
      throw Exception('Failed to like post: $e');
    }
  }

  // Unlike a comment (delete a like document)
  Future<void> unlikeComment(String userId, String commentId) async {
    if (userId == 'anonymous') {
      throw Exception('Anonymous users cannot unlike comments');
    }

    try {
      final response = await _appwriteService.listDocuments(
        collectionId: 'comment_likes',
        queries: [
          Query.and([
            Query.equal('commentId', commentId),
            Query.equal('userId', userId),
          ]),
        ],
      );

      if (response.containsKey('documents') && response['documents'] is List) {
        final documents = response['documents'] as List;

        if (documents.isEmpty) {
          throw Exception('Like document not found');
        }

        final likeDocument = documents.first;
        final likeDocumentId = likeDocument['\$id'];

        await _appwriteService.deleteDocument(
          collectionId: 'comment_likes',
          documentId: likeDocumentId,
        );
      } else {
        throw Exception(
            'Failed to fetch like document: ${response.toString()}');
      }
    } catch (e) {
      throw Exception('Failed to unlike comment: $e');
    }
  }

  // Unlike a post (delete a like document)
  Future<void> unlikePost(String userId, String postId) async {
    if (userId == 'anonymous') {
      throw Exception('Anonymous users cannot unlike posts');
    }

    try {
      final response = await _appwriteService.listDocuments(
        collectionId: 'post_likes',
        queries: [
          Query.and([
            Query.equal('postId', postId),
            Query.equal('userId', userId),
          ]),
        ],
      );

      if (response.containsKey('documents') && response['documents'] is List) {
        final documents = response['documents'] as List;

        if (documents.isEmpty) {
          throw Exception('Like document not found');
        }

        final likeDocument = documents.first;
        final likeDocumentId = likeDocument['\$id'];

        await _appwriteService.deleteDocument(
          collectionId: 'post_likes',
          documentId: likeDocumentId,
        );
      } else {
        throw Exception(
            'Failed to fetch like document: ${response.toString()}');
      }
    } catch (e) {
      throw Exception('Failed to unlike post: $e');
    }
  }

  Future<Map<String, int>> getCommentLikeCounts(List<String> commentIds) async {
    try {
      // Create a map to hold counts
      Map<String, int> likeCounts = {};

      // For each comment ID, initialize to 0
      for (final id in commentIds) {
        likeCounts[id] = 0;
      }

      final response = await _appwriteService.listDocuments(
        collectionId: 'comment_likes',
      );

      if (response.containsKey('documents') && response['documents'] is List) {
        final likes = response['documents'] as List;

        // Process all likes
        for (final like in likes) {
          final commentId = like['commentId'];

          if (likeCounts.containsKey(commentId)) {
            likeCounts[commentId] = (likeCounts[commentId] ?? 0) + 1;
          }
        }
      }

      return likeCounts;
    } catch (e) {
      throw Exception('Failed to fetch like counts: ${e.toString()}');
    }
  }

  Future<Map<String, int>> getPostLikeCounts(List<String> postIds) async {
    try {
      // Create a map to hold counts
      Map<String, int> likeCounts = {};

      // For each post ID, initialize to 0
      for (final id in postIds) {
        likeCounts[id] = 0;
      }

      final response = await _appwriteService.listDocuments(
        collectionId: 'post_likes',
      );

      if (response.containsKey('documents') && response['documents'] is List) {
        final likes = response['documents'] as List;

        // Process all likes
        for (final like in likes) {
          final postId = like['postId'];

          if (likeCounts.containsKey(postId)) {
            likeCounts[postId] = (likeCounts[postId] ?? 0) + 1;
          }
        }
      }

      return likeCounts;
    } catch (e) {
      throw Exception('Failed to fetch like counts: ${e.toString()}');
    }
  }

  Future<Map<String, int>> getPostCommentCounts(List<String> postIds) async {
    try {
      Map<String, int> commentCounts = {};

      // Initialize all post IDs to 0
      for (final id in postIds) {
        commentCounts[id] = 0;
      }

      // Fetch all comments and count them by postId
      final response = await _appwriteService.listDocuments(
        collectionId: 'comments',
      );

      if (response.containsKey('documents') && response['documents'] is List) {
        final comments = response['documents'] as List;

        // Count comments per post
        for (final comment in comments) {
          final postId = comment['postId'];
          if (commentCounts.containsKey(postId)) {
            commentCounts[postId] = (commentCounts[postId] ?? 0) + 1;
          }
        }
      }

      return commentCounts;
    } catch (e) {
      throw Exception('Failed to fetch comment counts: ${e.toString()}');
    }
  }

  // Get likes for a post
  Future<List<PostModel>> getPostLikes(String postId) async {
    try {
      final response = await _appwriteService
          .listDocuments(collectionId: 'post_likes', queries: [
        Query.equal('\$id', postId),
      ]);

      if (response.containsKey('documents') && response['documents'] is List) {
        final documents = response['documents'] as List;
        return documents
            .map((doc) {
              try {
                if (doc is Map<String, dynamic>) {
                  return PostModel.fromMap(doc['data'] ?? doc);
                }
                return null;
              } catch (e) {
                return null;
              }
            })
            .whereType<PostModel>() // Filter out nulls
            .toList();
      } else {
        throw Exception('Failed to fetch likes: ${response.toString()}');
      }
    } catch (e) {
      throw Exception('Failed to fetch likes: ${e.toString()}');
    }
  }
}
