import 'dart:developer' as developer;

import 'package:bloc/bloc.dart';
import 'package:community/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:community/features/community/data/models/comment_model.dart';
import 'package:community/features/community/data/models/post_model.dart';
import 'package:community/features/community/service/community_service.dart';
import 'package:equatable/equatable.dart';

part 'community_event.dart';
part 'community_state.dart';

class CommunityBloc extends Bloc<CommunityEvent, CommunityState> {
  final CommunityService _communityService;
  final AuthRepositoryImpl _authRepository;

  CommunityBloc({
    required CommunityService communityService,
    required AuthRepositoryImpl authRepository,
  })  : _communityService = communityService,
        _authRepository = authRepository,
        super(CommunityInitial()) {
    on<FetchCommunityPosts>(_onFetchCommunityPosts);
    on<TogglePostLike>(_onTogglePostLike);
    on<ToggleCommentLike>(_onToggleCommentLike);
    on<LoadSinglePost>(_onLoadSinglePost);
    on<AddComment>(_onAddComment);
    on<LoadComments>(_onLoadComments);
    on<VoteOnPoll>(_onVoteOnPoll);
  }

  Future<void> _onVoteOnPoll(
      VoteOnPoll event, Emitter<CommunityState> emit) async {
    if (state is PostLoaded) {
      final currentState = state as PostLoaded;
      final post = currentState.post;

      try {
        // Emit loading state
        emit(CommentsLoading(post: post));

        // Vote on the poll
        await _communityService.voteOnPoll(event.postId, event.optionIndex);

        // Update the post with the new vote
        final updatedPost = post.copyWith(
          pollOptions: post.pollOptions.map((option) {
            if (option.option == event.optionIndex) {
              return option.copyWith(votes: option.votes + 1);
            }
            return option;
          }).toList(),
        );

        // Emit loaded state with updated post
        emit(PostLoaded(
          post: updatedPost,
          comments: currentState.comments,
        ));
      } catch (e) {
        emit(CommunityError(message: 'Failed to vote on poll: ${e.toString()}'));
      }
    }
  }


  Future<void> _onLoadSinglePost(
      LoadSinglePost event, Emitter<CommunityState> emit) async {
    emit(CommentsLoading(post: event.post));

    try {
      final comments = await _communityService.getPostComments(event.post.id);
      final userId = await _authRepository.getCurrentUserId();
      final userLikedCommentIds =
          await _communityService.getUserLikedCommentIds(userId);
      final commentLikecounts = await _communityService
          .getCommentLikeCounts(comments.map((c) => c.id).toList());

      // Update the comments with the user's liked status
      for (int i = 0; i < comments.length; i++) {
        if (userLikedCommentIds.contains(comments[i].id)) {
          comments[i] = comments[i].copyWith(isLiked: true);
        }

        // Update the like count for each comment
        if (commentLikecounts.containsKey(comments[i].id)) {
          comments[i] = comments[i].copyWith(
            likeCount: commentLikecounts[comments[i].id] ?? 0,
          );
        }
      }

      emit(PostLoaded(
        post: event.post,
        comments: comments,
      ));
    } catch (e) {
      emit(CommunityError(message: 'Failed to load comments: ${e.toString()}'));
    }
  }

  Future<void> _onAddComment(
      AddComment event, Emitter<CommunityState> emit) async {
    // Get the current state
    if (state is PostLoaded) {
      final currentState = state as PostLoaded;
      final post = currentState.post;
      final currentComments = currentState.comments;

      try {
        // Get user info
        final username = await _authRepository.getCurrentUserName();

        // Actually save the comment
        final comment = await _communityService.addComment(
            post.id, event.commentText, username);

        // Create a new list of comments with the new comment added
        final updatedComments = List<CommentModel>.from(currentComments)
          ..add(comment);

        // Emit success
        emit(CommentAdded(
          post: post,
          comments: updatedComments,
          message: 'Comment added successfully',
        ));

        // Reload comments to get server-generated ID and ensure consistency
        final refreshedComments =
            await _communityService.getPostComments(event.postId);

        emit(PostLoaded(
          post: post,
          comments: refreshedComments,
        ));
      } catch (e) {
        emit(CommunityError(message: 'Failed to add comment: ${e.toString()}'));

        // Return to previous state
        emit(PostLoaded(
          post: post,
          comments: currentComments,
        ));
      }
    }
  }

// Load comments for a post
  Future<void> _onLoadComments(
      LoadComments event, Emitter<CommunityState> emit) async {
    if (state is PostLoaded || state is CommentsLoading) {
      final post = state is PostLoaded
          ? (state as PostLoaded).post
          : (state as CommentsLoading).post;

      try {
        // Emit loading state
        emit(CommentsLoading(post: post));

        // Load comments
        final comments = await _communityService.getPostComments(event.postId);

        // Emit loaded state
        emit(PostLoaded(
          post: post,
          comments: comments,
        ));
      } catch (e) {
        emit(CommunityError(
            message: 'Failed to load comments: ${e.toString()}'));
      }
    }
  }

  Future<void> _onFetchCommunityPosts(
      FetchCommunityPosts event, Emitter<CommunityState> emit) async {
    emit(CommunityLoading());

    try {
      // Get community posts from service
      final posts = await _communityService.getPosts(
        limit: event.limit,
        sortByLatest: event.sortByLatest,
      );

      // Get current user ID
      final userId = await _authRepository.getCurrentUserId();

      // Get user's liked posts (if logged in)
      Set<String> likedPostIds = {};
      if (userId != 'anonymous') {
        // Get liked posts
        final likedPosts = await _communityService.getUserLikedPosts(userId);
        likedPostIds = likedPosts.map((post) => post.id).toSet();

        // Update post models with liked status
        for (int i = 0; i < posts.length; i++) {
          if (likedPostIds.contains(posts[i].id)) {
            posts[i] = posts[i].copyWith(isLiked: true);
          }
        }
      }

      emit(CommunityLoaded(
        posts: posts,
        likedPosts: likedPostIds,
      ));
    } catch (e) {
      emit(CommunityError(message: e.toString()));
    }
  }

  Future<void> _onToggleCommentLike(
      ToggleCommentLike event, Emitter<CommunityState> emit) async {
    if (state is! PostLoaded) {
      emit(CommunityError(message: 'Comments not loaded'));
      return;
    }

    try {
      final userId = await _authRepository.getCurrentUserId();
      if (userId == 'anonymous') {
        emit(CommunityError(message: 'Please log in to like comments'));
        return;
      }

      // Check if the comment exists in the current state

      final currentState = state as PostLoaded;
      final post = currentState.post;
      final comments = currentState.comments;
      final commentIndex = comments.indexWhere((c) => c.id == event.commentId);

      if (commentIndex == -1) {
        emit(CommunityError(message: 'Comment not found'));
        emit(currentState);
        return;
      }

      final comment = comments[commentIndex];
      final isLiked = comment.isLiked;
      final updatedComments = List<CommentModel>.from(comments);
      updatedComments[commentIndex] = comment.copyWith(
        isLiked: !isLiked,
        likeCount: comment.likeCount + (isLiked ? -1 : 1),
      );

      if (isLiked) {
        await _communityService.unlikeComment(userId, event.commentId);
      } else {
        await _communityService.likeComment(userId, event.commentId);
      }

      // Return to the updated state (this is important)
      emit(PostLoaded(
        post: post,
        comments: updatedComments,
      ));
    } catch (e) {
      emit(CommunityError(
          message: 'Failed to toggle comment like: ${e.toString()}'));
      return;
    }
  }

  Future<void> _onTogglePostLike(
      TogglePostLike event, Emitter<CommunityState> emit) async {
    // Only proceed if we're in a loaded state
    if (state is CommunityLoaded || state is PostLoaded) {
      try {
        // Get current user ID
        final userId = await _authRepository.getCurrentUserId();

        // Check if user is anonymous
        if (userId == 'anonymous') {
          emit(CommunityError(message: 'Please log in to like posts'));
          emit(state); // Re-emit the current state
          return;
        }

        // Branch handling for CommunityLoaded state
        if (state is CommunityLoaded) {
          final currentState = state as CommunityLoaded;
          final posts = currentState.posts;
          final likedPosts = currentState.likedPosts;

          // Find the post that needs to be updated
          final postIndex = posts.indexWhere((p) => p.id == event.postId);
          if (postIndex == -1) {
            emit(CommunityError(message: 'Post not found'));
            emit(currentState);
            return;
          }

          final post = posts[postIndex];
          final isLiked = post.isLiked;

          // Create a new posts list with the updated post
          final updatedPosts = List<PostModel>.from(posts);
          updatedPosts[postIndex] = post.copyWith(
            isLiked: !isLiked,
            likeCount: post.likeCount + (isLiked ? -1 : 1),
          );

          // Update the set of liked post IDs
          final updatedLikedPosts = Set<String>.from(likedPosts);
          if (isLiked) {
            updatedLikedPosts.remove(event.postId);
          } else {
            updatedLikedPosts.add(event.postId);
          }

          // Optimistically emit the updated state
          emit(CommunityLoaded(
            posts: updatedPosts,
            likedPosts: updatedLikedPosts,
          ));

          // Call the API to update the like on the backend
          if (isLiked) {
            await _communityService.unlikePost(userId, event.postId);
          } else {
            await _communityService.likePost(userId, event.postId);
          }

          // Optionally emit a success notification
          emit(CommunityActionSuccess(
            message: isLiked ? 'Post unliked' : 'Post liked',
            postId: event.postId,
          ));

          // Re-emit the updated state
          emit(CommunityLoaded(
            posts: updatedPosts,
            likedPosts: updatedLikedPosts,
          ));
        }
        // Branch handling for CommentsLoaded state
        else if (state is PostLoaded) {
          final currentState = state as PostLoaded;
          // Check if the loaded post is the one we're toggling
          if (currentState.post.id != event.postId) {
            emit(CommunityError(
                message: 'Post not found in current comments view'));
            emit(currentState);
            return;
          }

          final post = currentState.post;
          final isLiked = post.isLiked;

          // Create an updated post with toggled like values
          final updatedPost = post.copyWith(
            isLiked: !isLiked,
            likeCount: post.likeCount + (isLiked ? -1 : 1),
          );

          // Optimistically emit the updated CommentsLoaded state
          emit(PostLoaded(
            post: updatedPost,
            comments: currentState.comments,
          ));

          // Call the API to update the like status on the backend
          if (isLiked) {
            await _communityService.unlikePost(userId, event.postId);
          } else {
            await _communityService.likePost(userId, event.postId);
          }

          // Optionally emit a success notification
          emit(CommunityActionSuccess(
            message: isLiked ? 'Post unliked' : 'Post liked',
            postId: event.postId,
          ));

          // Re-emit the final updated state
          emit(PostLoaded(
            post: updatedPost,
            comments: currentState.comments,
          ));
        }
      } catch (e) {
        developer.log('Error toggling like: ${e.toString()}');
        emit(CommunityError(message: 'Failed to update like: ${e.toString()}'));
        emit(state); // Revert to previous state
      }
    }
  }
}
