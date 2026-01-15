import 'package:flutter/material.dart';

class MemberAvatarList extends StatelessWidget {
  final List<dynamic> members;
  final int maxVisible;
  final double size;
  final double overlap;

  const MemberAvatarList({
    super.key,
    required this.members,
    this.maxVisible = 3,
    this.size = 32,
    this.overlap = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) return const SizedBox();

    final visibleMembers = members.take(maxVisible).toList();
    final remainingCount = members.length - maxVisible;
    final widthOffset = size * (1 - overlap);

    return SizedBox(
      height: size,
      width: size + (visibleMembers.length - 1 + (remainingCount > 0 ? 1 : 0)) * widthOffset,
      child: Stack(
        children: [
          ...visibleMembers.asMap().entries.map((entry) {
            final index = entry.key;
            final member = entry.value;
            return Positioned(
              left: index * widthOffset,
              child: _buildAvatar(member, index),
            );
          }),
          if (remainingCount > 0)
            Positioned(
              left: visibleMembers.length * widthOffset,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  '+$remainingCount',
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(dynamic member, int index) {
    // Determine how to get initials and photo from member object
    String initials = 'U';
    String? photoUrl;
    Color color = Colors.blue;
    
    // Handle different member object structures (Map or Object)
    if (member is Map) {
      final name = member['username'] ?? member['name'] ?? member['realname'] ?? '';
      if (name.isNotEmpty) {
        initials = name.substring(0, 1).toUpperCase();
      }
      photoUrl = member['photo'];
    } else {
       // Assuming it's a strongly typed object, use reflection or dynamic access if needed
       // For now, simple fallback
       try {
         final name = (member as dynamic).username ?? (member as dynamic).name ?? '';
         if (name.isNotEmpty) {
           initials = name.toString().substring(0, 1).toUpperCase();
         }
         photoUrl = (member as dynamic).photo;
       } catch (_) {}
    }

    // Assign a consistent color based on initials or index if no photo
    final List<Color> colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal];
    color = colors[index % colors.length];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: photoUrl != null ? null : color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        image: photoUrl != null && photoUrl.isNotEmpty
            ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: photoUrl == null
          ? Text(
              initials,
              style: TextStyle(
                fontSize: size * 0.5,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            )
          : null,
    );
  }
}
