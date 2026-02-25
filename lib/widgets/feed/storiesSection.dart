import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/feedModel.dart';

class StoriesSection extends StatelessWidget {
  const StoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Create story card
          _buildCreateStoryCard(),
          const SizedBox(width: 12),
          
          // Story cards
          ...MockData.stories.map((story) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildStoryCard(story),
          )),
        ],
      ),
    );
  }

  Widget _buildCreateStoryCard() {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF18181B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.slate900),
      ),
      child: Stack(
        children: [
          // User image at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 123, // 65% of 190
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                MockData.currentUser.avatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.slate800,
                    child: const Icon(Icons.person, color: Colors.white),
                  );
                },
              ),
            ),
          ),

          // Bottom section
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 67, // 35% of 190
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF18181B),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: const Center(
                child: Text(
                  'Tạo tin',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Plus button
          Positioned(
            bottom: 47, // Position at the border
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF18181B),
                    width: 4,
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryCard(Story story) {
    return Container(
      width: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.slate900.withOpacity(0.5),
        ),
      ),
      child: Stack(
        children: [
          // Story image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              story.image,
              width: 110,
              height: 190,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppTheme.slate800,
                  child: const Icon(Icons.image, color: Colors.white),
                );
              },
            ),
          ),

          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),

          // User avatar
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 36,
              height: 36,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: story.isSeen ? AppTheme.slate500 : Colors.blue,
              ),
              child: ClipOval(
                child: Image.network(
                  story.user.avatar,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.slate800,
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 16,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // User name
          Positioned(
            bottom: 12,
            left: 8,
            right: 8,
            child: Text(
              story.user.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 4,
                    color: Colors.black,
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}