import '../enums/IMEventType.dart';

class IMEvent {
  final IMEventType type;
  final dynamic data;

  IMEvent(this.type, {this.data});

  @override
  String toString() => 'IMEvent(type: $type, data: $data)';
}
