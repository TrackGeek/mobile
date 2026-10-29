class GalleryItem {
  const GalleryItem({
    required this.url,
    this.title,
    this.description,
    this.videoUrl,
  });

  final String url;
  final String? title;
  final String? description;
  final String? videoUrl;
}
