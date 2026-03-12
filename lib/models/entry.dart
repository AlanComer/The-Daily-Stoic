class Entry {
  final String dateKey;    // MM-DD
  final String month;
  final int day;
  final String title;
  final String quote;
  final String attribution;
  final String body;

  const Entry({
    required this.dateKey,
    required this.month,
    required this.day,
    required this.title,
    required this.quote,
    required this.attribution,
    required this.body,
  });

  factory Entry.fromJson(Map<String, dynamic> json) {
    return Entry(
      dateKey: json['date_key'] as String,
      month: json['month'] as String,
      day: json['day'] as int,
      title: json['title'] as String,
      quote: json['quote'] as String,
      attribution: json['attribution'] as String,
      body: json['body'] as String,
    );
  }
}
