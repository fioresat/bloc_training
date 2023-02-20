class RedditPost {
  int id;
  String nameID;
  String title;
  String picture;
  int ups;
  String selftext;

  RedditPost({
    this.id = 0,
    required this.nameID,
    required this.ups,
    required this.selftext,
    required this.title,
    required this.picture,
  });

  RedditPost.fromJson(Map<String, dynamic> json)
      : ups = json['ups'],
        id = 0,
        selftext = json['selftext'].toString(),
        picture = json['thumbnail'].toString(),
        title = json['title'].toString(),
        nameID = json['name'].toString();

  Map<String, dynamic> toJson() => {
    'ups': ups,
    'selftext': selftext,
    'name': nameID,
    'thumbnail': picture,
    'title': title,
  };
}