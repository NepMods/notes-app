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
  void didPop() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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
            Toast.success(context, "Successfully Added");
          }
        }
        if ((finalThis.deleted ?? false)) {
          if ((await deleteNote(finalThis)).status) {
            Toast.success(context, "Successfully Deleted");
          }
        }
      }
      hasUnsyned = false;
      await getNotesFromServer();
    } catch (e) {
    } finally {
      await checkUnsyned();
    }
  }

  Future<void> checkUnsyned() async {
    hasUnsyned = false;
    try {
      final rawList = EncryptedDatabase.instance.read("notesCache");

      List<Note> cachedNotes = rawList.cast<Note>();
      for (int i = 0; i < cachedNotes.length; i++) {
        if (hasUnsyned) {
          break;
        }
        if (cachedNotes[i].edited ?? false) {
          setState(() {
            hasUnsyned = true;
          });
          break;
        }
        if (cachedNotes[i].deleted ?? false) {
          setState(() {
            hasUnsyned = true;
          });
          break;
        }
        if (!(cachedNotes[i].uploaded ?? true)) {
          setState(() {
            hasUnsyned = true;
          });
          break;
        }
      }
    } catch (E) {}
  }

  Future<void> _loadData() async {
    LoadingService.show();

    final rawList = EncryptedDatabase.instance.read("notesCache");
    if (rawList != null && rawList != []) {
      List<Note> cachedNotes = rawList.cast<Note>();

      List<Note> tempNotes = [];
      for (int i = 0; i < cachedNotes.length; i++) {
        Note not = cachedNotes[i];
        if (not.deleted ?? false) {
          continue;
        }
        tempNotes.add(not);
      }
      setState(() {
        notes = tempNotes;
      });
      syncToServer();
    } else {
      await getNotesFromServer();
    }

    LoadingService.hide();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _loadData();
        return true;
      },
      child: Scaffold(
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
                await syncToServer();
              },
            ),
            IconButton(
              onPressed: () async {
                Navigator.pushNamed(context, "/notes");
              },
              icon: Icon(Icons.sync),
            ),
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
                final rawList = EncryptedDatabase.instance.read("notesCache");

                List<Note> cachedNotes = rawList.cast<Note>();
                cachedNotes[index].deleted = true;
                EncryptedDatabase.instance.write("notesCache", cachedNotes);
                _loadData();
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
      ),
    );
  }
}
