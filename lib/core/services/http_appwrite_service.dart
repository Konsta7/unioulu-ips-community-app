import 'dart:developer' as developer;
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../utils/config.dart';

/// Service class for making API calls to Appwrite backend
class AppwriteService {
  final String endpoint;
  final String projectId;
  final String apiKey;
  final String databaseId;

  /// Creates an instance of AppwriteService with necessary configuration
  AppwriteService({
    String? endpointUrl,
    String? projectIdentifier,
    String? apiKeyValue,
    String? databaseIdentifier,
  })  : endpoint = endpointUrl ?? appwriteEndpoint,
        projectId = projectIdentifier ?? appwriteProjectId,
        apiKey = apiKeyValue ?? appwriteApiKey,
        databaseId = databaseIdentifier ?? appwriteDatabaseId;

  /// Standard headers used in API requests
  Map<String, String> get _standardHeaders => {
        'Content-Type': 'application/json',
        'X-Appwrite-Project': projectId,
        'X-Appwrite-Key': apiKey,
        'X-Appwrite-Response-Format': '1.5.0',
      };

  /// Makes an HTTP request to the Appwrite API
  ///
  /// [method] - HTTP method (GET, POST, PUT, DELETE, PATCH)
  /// [endpointPath] - API endpoint path
  /// [data] - Request payload (optional)
  /// [queryParameters] - URL query parameters (optional)
  Future<http.Response> makeRequest({
    required String method,
    required String endpointPath,
    Map<String, dynamic>? data,
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse('$endpoint/$endpointPath').replace(
      queryParameters: queryParameters,
    );

    developer.log('Making $method request to $uri');

    try {
      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: _standardHeaders);
          break;
        case 'POST':
          response = await http.post(uri,
              headers: _standardHeaders,
              body: data != null ? jsonEncode(data) : null);
          break;
        case 'PUT':
          response = await http.put(uri,
              headers: _standardHeaders,
              body: data != null ? jsonEncode(data) : null);
          break;
        case 'DELETE':
          response = await http.delete(uri,
              headers: _standardHeaders,
              body: data != null ? jsonEncode(data) : null);
          break;
        case 'PATCH':
          response = await http.patch(uri,
              headers: _standardHeaders,
              body: data != null ? jsonEncode(data) : null);
          break;
        default:
          throw Exception('Invalid HTTP method: $method');
      }

      _logResponse(response);
      return response;
    } catch (e) {
      developer.log('Error making request to $uri: $e',
          error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  /// Uploads a file to the Appwrite storage
  ///
  /// [bucketId] - ID of the storage bucket
  /// [file] - File to upload
  /// [fileId] - ID to assign to the file (optional)
  /// [permissions] - File permissions (optional)
  Future<Map<String, dynamic>> uploadFile({
    required String bucketId,
    required File file,
    String? fileId,
    List<String>? permissions,
  }) async {
    final endpointPath = 'storage/buckets/$bucketId/files';
    final url = Uri.parse('$endpoint/$endpointPath');

    try {
      final request = http.MultipartRequest('POST', url)
        ..headers.addAll({
          'X-Appwrite-Project': projectId,
          'X-Appwrite-Key': apiKey,
        });

      // Add optional parameters if provided
      if (fileId != null) {
        request.fields['fileId'] = fileId;
      }

      if (permissions != null && permissions.isNotEmpty) {
        request.fields['permissions'] = jsonEncode(permissions);
      }

      // Add the file
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      developer.log('Uploading file to $url');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      _logResponse(response);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to upload file: ${response.body}');
      }
    } catch (e) {
      developer.log('Error uploading file: $e',
          error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  /// Fetches documents from a collection
  ///
  /// [collectionId] - ID of the collection
  /// [queries] - List of query constraints (optional)
  Future<Map<String, dynamic>> listDocuments({
    required String collectionId,
    List<String>? queries,
  }) async {
    // Create a Map<String, String> for query parameters
    final Map<String, String> queryParams = {};

    // Add each query to the query parameters in the correct format for Appwrite REST API
    if (queries != null && queries.isNotEmpty) {
      for (int i = 0; i < queries.length; i++) {
        queryParams['queries[$i]'] = queries[i];
      }
    }

    developer.log('List documents query params: $queryParams');

    try {
      final response = await makeRequest(
        method: 'GET',
        endpointPath:
            'databases/$databaseId/collections/$collectionId/documents',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to list documents: ${response.body}');
      }
    } catch (e) {
      developer.log('Error listing documents: $e');
      rethrow;
    }
  }

  /// Deletes a document from a collection
  /// [collectionId] - ID of the collection
  /// [documentId] - ID of the document to delete
  /// 
  Future<void> deleteDocument({
    required String collectionId,
    required String documentId,
  }) async {
    final endpointPath =
        'databases/$databaseId/collections/$collectionId/documents/$documentId';

    try {
      final response = await makeRequest(
        method: 'DELETE',
        endpointPath: endpointPath,
      );

      if (response.statusCode == 204) {
        developer.log('Document deleted successfully');
      } else {
        developer.log(
            'Failed to delete document. Status: ${response.statusCode}, Response: ${response.body}');
        throw Exception('Failed to delete document: ${response.body}');
      }
    } catch (e) {
      developer.log('Error deleting document: $e');
      rethrow;
    }
  }


  /// Creates a document in a collection
  ///
  /// [collectionId] - ID of the collection
  /// [data] - Document data
  /// [documentId] - ID to assign to the document (optional)
  Future<Map<String, dynamic>> createDocument({
    required String collectionId,
    required Map<String, dynamic> data,
    String? documentId,
  }) async {
    final endpointPath =
        'databases/$databaseId/collections/$collectionId/documents';

    // Query params (used by Appwrite to generate id when documentId == 'unique()')
    final Map<String, String> queryParams = {};
    if (documentId != null && documentId == 'unique()') {
      queryParams['documentId'] = 'unique()';
    }

    // Ensure the request body always contains a top-level 'data' key for Appwrite.
    // If caller already provided a 'data' key, keep it as-is.
    final Map<String, dynamic> requestData =
        data.containsKey('data') ? {...data} : {'data': {...data}};

    // Include documentId information in the body to be robust for proxies / appwrite versions.
    if (documentId != null) {
      if (documentId == 'unique()') {
        requestData['documentId'] = 'unique()';
      } else {
        // For explicit IDs, include both Appwrite's explicit id key and documentId for safety
        requestData['\$id'] = documentId;
        requestData['documentId'] = documentId;
      }
    }

    try {
      developer.log('Creating document with payload: $requestData');
      developer.log('Document query params: $queryParams');

      final response = await makeRequest(
        method: 'POST',
        endpointPath: endpointPath,
        data: requestData,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        developer.log(
            'Failed to create document. Status: ${response.statusCode}, Response: ${response.body}');
        throw Exception('Failed to create document: ${response.body}');
      }
    } catch (e) {
      developer.log('Error creating document: $e');
      rethrow;
    }
  }

  /// Updates a document in a collection
  ///
  /// [collectionId] - ID of the collection (e.g., 'posts')
  /// [documentId] - ID of the document you want to update
  /// [data] - Updated fields as a map
  Future<http.Response> updateDocument({
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    final endpointPath = 'databases/$databaseId/collections/$collectionId/documents/$documentId';

    return await makeRequest(
      method: 'PATCH',
      endpointPath: endpointPath,
      data: data,
    );
  }

  /// Logs the API response for debugging purposes
  void _logResponse(http.Response response) {
    final statusPrefix =
        response.statusCode >= 200 && response.statusCode < 300 ? '✅' : '❌';
    developer.log(
      '$statusPrefix Response ${response.statusCode}: ${response.reasonPhrase}',
      name: 'AppwriteService',
    );

    // Log truncated response body for debugging
    final bodyPreview = response.body.length > 500
        ? '${response.body.substring(0, 500)}...'
        : response.body;
    developer.log('Response body: $bodyPreview', name: 'AppwriteService');
  }
}