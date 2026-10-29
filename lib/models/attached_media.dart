import 'media_type.dart';

class AttachedMedia {
  const AttachedMedia({
    required this.type,
    required this.externalId,
    required this.title,
    this.imageUrl,
  });

  final MediaType type;
  final int externalId;
  final String title;
  final String? imageUrl;
}
