class Category {
  final String id;
  final String name;
  final String description;
  final String? icon;
  final String? imageUrl;

  Category({
    required this.id,
    required this.name,
    required this.description,
    this.icon = '',
    this.imageUrl,
  });

  factory Category.fromContentful(Map<String, dynamic> entry) {
    final fields = entry['fields'] as Map<String, dynamic>;
    String? imageUrl;
    
    // Safely extract the image URL with proper null checking
    if (fields.containsKey('image') && fields['image'] != null) {
      final image = fields['image'];
      if (image is Map && image.containsKey('fields')) {
        final imageFields = image['fields'];
        if (imageFields is Map && imageFields.containsKey('file')) {
          final file = imageFields['file'];
          if (file is Map && file.containsKey('url')) {
            imageUrl = file['url'];
            // Prepend https: if the URL starts with //
            if (imageUrl != null && imageUrl.startsWith('//')) {
              imageUrl = 'https:$imageUrl';
            }
          }
        }
      }
    }
    
    return Category(
      id: entry['sys']['id'],
      name: fields['name'] ?? '',
      description: fields['description'] ?? '',
      icon: fields['icon'],
      imageUrl: imageUrl,
    );
  }
} 