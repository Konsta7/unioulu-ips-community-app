import 'package:community/core/services/dependency_injection.dart';
import 'package:community/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:community/features/community/data/models/post_model.dart';
import 'package:community/features/community/presentation/bloc/community_bloc.dart';
import 'package:community/features/community/presentation/widgets/comment_input_field.dart';
import 'package:community/features/community/presentation/widgets/comment_section.dart';
import 'package:community/features/community/service/community_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SingleCommunityPostPage extends StatefulWidget {
  const SingleCommunityPostPage({
    super.key,
    required this.post,
  });

  final PostModel post;

  @override
  _SingleCommunityPostPageState createState() =>
      _SingleCommunityPostPageState();
}

class _SingleCommunityPostPageState extends State<SingleCommunityPostPage> {
  int? _selectedPollOption;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _voteOnPoll(int index) async {
    if (_selectedPollOption != null) return;
    setState(() {
      _selectedPollOption = index;
    });

    context.read<CommunityBloc>().add(
          VoteOnPoll(postId: widget.post.id, optionIndex: index),
        );
  }

  double _pollPercentage(int index) {
    final opts = widget.post.pollOptions;
    final total = opts.fold<int>(0, (sum, o) => sum + o.votes);
    return total > 0 ? opts[index].votes / total : 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CommunityBloc(
        communityService: locator<CommunityService>(),
        authRepository: locator<AuthRepositoryImpl>(),
      )..add(LoadSinglePost(post: widget.post)),
      child: BlocListener<CommunityBloc, CommunityState>(
        listener: (context, state) {
          if (state is CommunityError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is CommentAdded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Comment added successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Community Post')),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPostCard(),
                BlocBuilder<CommunityBloc, CommunityState>(
                  buildWhen: (prev, curr) => curr is PostLoaded || curr is CommentsLoading,
                  builder: (context, state) {
                    // Only show comment input after post is loaded
                    if (state is PostLoaded) {
                      return CommentInputField(
                        postId: widget.post.id,
                        onCommentSubmit: (_, commentText) =>
                            context.read<CommunityBloc>().add(
                                  AddComment(
                                      postId: widget.post.id, commentText: commentText),
                                ),
                      );
                    } else {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
                ),
                CommentsSection(postId: widget.post.id),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard() {
    return BlocBuilder<CommunityBloc, CommunityState>(
      buildWhen: (prev, curr) =>
          curr is PostLoaded ||
          curr is CommunityActionSuccess ||
          curr is CommunityLoading,
      builder: (context, state) {
        final post = state is PostLoaded ? state.post : widget.post;
        return Card(
          margin: const EdgeInsets.all(12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _authorRow(post),
                const SizedBox(height: 16),
                _postImage(post),
                const SizedBox(height: 16),
                Text(post.postTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(post.content, style: const TextStyle(fontSize: 14)),
                if (post.pollOptions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _pollSection(post),
                ],
                const SizedBox(height: 16),
                _likeRow(post),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _authorRow(PostModel post) => Row(
        children: [
          const CircleAvatar(
            radius: 28,
            child: Icon(Icons.person),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.authorName,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(post.authorTitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      );

  Widget _postImage(PostModel post) => post.imageUrl.isNotEmpty
      ? Image.network(
          post.imageUrl,
          width: double.infinity,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, size: 100, color: Colors.grey),
        )
      : Image.asset('assets/default_avatar.png',
          width: double.infinity, height: 200, fit: BoxFit.cover);

  Widget _pollSection(PostModel post) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(post.pollQuestion,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...List.generate(post.pollOptions.length, (i) {
            final opt = post.pollOptions[i];
            final isSel = _selectedPollOption == i;
            final pct = _pollPercentage(i);
            return GestureDetector(
              onTap: () => _voteOnPoll(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSel ? Colors.blue.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isSel ? Colors.blue : Colors.grey.shade300,
                      width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(opt.option,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isSel ? Colors.blue : Colors.black87)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(value: pct, minHeight: 8),
                    const SizedBox(height: 6),
                    Text(
                        '${(pct * 100).toStringAsFixed(1)}% (${opt.votes} votes)',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
            );
          }),
          if (_selectedPollOption != null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Thanks for voting!',
                  style: TextStyle(color: Colors.green)),
            ),
        ],
      );

  Widget _likeRow(PostModel post) => Row(
        children: [
          IconButton(
            icon: Icon(post.isLiked ? Icons.favorite : Icons.favorite_border,
                color: post.isLiked ? Colors.red : null),
            onPressed: () => context
                .read<CommunityBloc>()
                .add(TogglePostLike(postId: post.id)),
          ),
          Text('${post.likeCount}'),
        ],
      );
}
