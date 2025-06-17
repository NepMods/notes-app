import 'package:flutter/material.dart';
import 'package:notes/Api/api.dart';
import 'package:notes/EncryptedDatabase/EncryptedDatabase.dart';
import 'package:notes/Models/note.dart';
import 'package:sonner_flutter/sonner_flutter.dart';

class NoteEdit extends StatefulWidget {
  final Note? editingNote;
  NoteEdit({Key? key, this.editingNote}) : super(key: key);

  @override
  _NoteEditState createState() => _NoteEditState();
}

class _NoteEditState extends State<NoteEdit> {
  TextEditingController title = new TextEditingController();
  TextEditingController body = new TextEditingController();
  bool editing = false;

  @override
  void initState() {
    super.initState();
    if (widget.editingNote != null) {
      editing = true;
      title.text = widget.editingNote!.title;
      body.text = widget.editingNote!.body;
    }
  }

  Future<void> add() async {
    final note = new Note(
      title: title.text,
      body: body.text,
      id: "",
      uploaded: false,
      edited: false,
    );
    if (note.body == "" || note.title == "") {
      Toast.info(context, "Empty Note, Skipping save");

      Navigator.pushNamed(context, "/notes");
      return;
    }

    final rawList = EncryptedDatabase.instance.read("notesCache");
    List<Note> cachedNotes = rawList.cast<Note>();
    cachedNotes.add(note);

    EncryptedDatabase.instance.write("notesCache", cachedNotes);

    Toast.success(context, "Note added");
    Navigator.pushNamed(context, "/notes");
  }

  Future<void> update() async {
    final note = new Note(
      title: title.text,
      body: body.text,
      id: widget.editingNote!.id,
      uploaded: false,
      edited: true,
    );

    if (note.body.isEmpty || note.title.isEmpty) {
      Toast.info(context, "Empty Note, Skipping update");

      Navigator.pushNamed(context, "/notes");
      return;
    }

    final rawList = EncryptedDatabase.instance.read("notesCache");
    List<Note> cachedNotes = rawList.cast<Note>();

    for (Note note in cachedNotes) {
      if (note.id == widget.editingNote!.id) {
        note.title = title.text;
        note.body = body.text;
        note.edited = true;
      }
    }
    EncryptedDatabase.instance.write("notesCache", cachedNotes);
    Toast.success(context, "Note updated");
    Navigator.pushNamed(context, "/notes");
  }

  Future<void> save() async {
    if (editing) {
      await update();
    } else {
      await add();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: save,
        child: Icon(Icons.save),
      ),
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: save),
        title: TextField(
          controller: title,
          decoration: InputDecoration(
            hintText: 'Title',
            hintStyle: TextStyle(fontSize: 18),
          ),
        ),
      ),
      body: Padding(
        
        padding: EdgeInsets.all(
           MediaQuery.of(context).size.height * 0.02,
        ),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.onSecondary), borderRadius: BorderRadius.circular(7)),
          height: double.infinity,
          child: TextField(
            controller: body,
            maxLines: null,
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.center,
            decoration: InputDecoration(
            
              border: InputBorder.none,
              hintText: 'Write your Notes here...',
              hintStyle: TextStyle(fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}
