import 'package:community/core/theme/theme_constants.dart';
import 'package:community/features/community/presentation/pages/single_community_post_page.dart';
import 'package:flutter/material.dart';
import '../../data/models/post_model.dart';

class CommunityPostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onLikePressed;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onLikePressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SingleCommunityPostPage(
              post: post,
            ),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: AppRoundness.largeBorderRadius,
        ),
        color: Theme.of(context).cardColor,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundImage:
                        NetworkImage('https://thispersondoesnotexist.com'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          post.authorTitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Post content
              Text(
                post.postTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                post.content,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              // Actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          post.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: post.isLiked ? Colors.red : null,
                        ),
                        onPressed: onLikePressed,  // Use the callback parameter
                      ),
                      Text('${post.likeCount}'),  // Like count placeholder
                    ],
                  ),
                  const SizedBox(width: AppSpacing.smallPadding),
                  Row(
                    children: [
                      const Icon(Icons.mode_comment_outlined),
                      const SizedBox(width: AppSpacing.smallPadding),
                      Text('${post.commentCount}'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}