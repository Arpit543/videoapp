class Song {
  final String title;
  final String artist;
  final String artwork;
  final String url;
  final String id;

  Song({
    required this.title,
    required this.artist,
    required this.artwork,
    required this.url,
    required this.id,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      title: json['title'],
      artist: json['artist'],
      artwork: json['artwork'],
      url: json['url'],
      id: json['id'],
    );
  }
}