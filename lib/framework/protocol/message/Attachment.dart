class Attachment {
  final String? url;
  final String? name;
  final int? size;
  final String? type;

  Attachment({this.url, this.name, this.size, this.type});

  factory Attachment.fromJson(Map<String, dynamic> json) => Attachment(
    url: json['url'],
    name: json['name'],
    size: json['size'],
    type: json['type'],
  );

  Map<String, dynamic> toJson() => {'url': url, 'name': name, 'size': size, 'type': type};
}