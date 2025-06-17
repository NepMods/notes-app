import 'package:flutter/material.dart';
import 'package:notes/Screens/NoteEditUI.dart';
import 'package:notes/Screens/Loading/LoadingService.dart';
import 'package:notes/Screens/SettingsUI.dart';
import 'package:notes/Api/api.dart';
import 'package:notes/Screens/Components/DashNoteView.dart';
import 'package:notes/EncryptedDatabase/EncryptedDatabase.dart';
import 'package:notes/Models/note.dart';

import 'package:sonner_flutter/sonner_flutter.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

class Dashboard extends StatefulWidget {
  Dashboard({Key? key}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with RouteAware {
  List<Note> notes = [];
  bool hasUnsyned = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() async {
    _loadData();
  }

  Future<void> getNotesFromServer() async {
    try {
      final data = await getNotes();
      EncryptedDatabase.instance.write("email", data.data["user"]?["email"]);

      final List<Note> localNote = [];
      for (final serverNote in data.data["note"]) {
        localNote.add(
          Note(
            title: serverNote["title"],
            body: serverNote["body"],
            id: serverNote["id"],
            uploaded: true,
            edited: false,
          ),
        );
      }

      EncryptedDatabase.instance.write("notesCache", localNote);

      setState(() {
        notes = localNote;
      });
    } catch (e) {
      Toast.error(context, "Failed to load data");
    } finally {
      LoadingService.hide();
    }
  }

  Future<void> syncToServer() async {
    try {
      final rawList = EncryptedDatabase.instance.read("notesCache");
      List<Note> cachedNotes = rawList.cast<Note>();
      for (int i = 0; i < cachedNotes.length; i++) {
        Note finalThis = cachedNotes[i];
        if (finalThis.edited ?? false) {
          
          if ((await updateNote(finalThis)).status) {
            Toast.success(context, "Successfully updated");
          }
        }
        if (!(finalThis.uploaded ?? true)) {
          if ((await addNote(finalThis)).status) {
            Toast.success(context, "Successfully updated");
          }
        }
      }
      hasUnsyned = false;
      await getNotesFromServer();
    } catch (e) {
      Toast.error(context, "Failed to sync data $e");
    } finally {
      await checkUnsyned();
    }
  }

  Future<void> checkUnsyned() async {
    hasUnsyned = false;
    for (int i = 0; i < notes.length; i++) {
      if (hasUnsyned) {
        break;
      }
      if (notes[i].edited ?? false) {
        setState(() {
          hasUnsyned = true;
        });
        break;
      }
      if (!(notes[i].uploaded ?? true)) {
        setState(() {
          hasUnsyned = true;
        });
        break;
      }
    }
  }

  Future<void> _loadData() async {
    LoadingService.show();
    notes.clear();

    final rawList = EncryptedDatabase.instance.read("notesCache");
    if (rawList != null || rawList != []) {
      List<Note> cachedNotes = rawList.cast<Note>();
      setState(() {
        notes = cachedNotes;
      });
      syncToServer();
    } else {
      getNotesFromServer();
    }

    LoadingService.hide();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Notes',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              hasUnsyned ? Icons.sync_problem : Icons.check_circle,
              color: hasUnsyned ? Colors.red : Colors.green,
              size: 45,
            ),
            onPressed: () async {
              syncToServer();
            },
          ),
          IconButton(onPressed: ()async{

              Navigator.pushNamed(context, "/notes");
          }, icon: Icon(Icons.sync)),
          IconButton(
            icon: Icon(Icons.account_circle, size: 45),
            onPressed: () {
              Navigator.pushNamed(context, "/settings");
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: notes.length,
        itemBuilder: (context, index) {
          return DashNoteView(
            note: notes[index],
            onDelete: (note) async {
              await deleteNote(note);
              await _loadData();
              Toast.success(context, "Note Deleted");
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, "/addNotes", arguments: null);
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
