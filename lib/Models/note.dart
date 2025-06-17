import 'package:hive/hive.dart';


@HiveType(typeId: 0)
class Note extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String body;

  @HiveField(2)
  String id;

  @HiveField(3)
  bool? edited;

  @HiveField(4)
  bool? uploaded;

  Note({
    required this.title,
    required this.body,
    required this.id,
    this.edited,
    this.uploaded,
  });
}



class NoteAdapter extends TypeAdapter<Note> {
  @override
  final int typeId = 0;

  @override
  Note read(BinaryReader reader) {
    return Note(
      title: reader.readString(),
      body: reader.readString(),
      id: reader.readString(),
      edited: reader.readBool(),
      uploaded: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer.writeString(obj.title);
    writer.writeString(obj.body);
    writer.writeString(obj.id);
    writer.writeBool(obj.edited ?? false);
    writer.writeBool(obj.uploaded ?? false);
  }
}

