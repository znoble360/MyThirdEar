import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:musictranscriptiontools/models/library.dart';
import 'package:musictranscriptiontools/screens/music_player_screen.dart';
import 'package:musictranscriptiontools/screens/player.dart';
import 'package:musictranscriptiontools/utils/file_handler.dart';
import 'package:path_provider/path_provider.dart';
// ignore: implementation_imports
import 'package:provider/src/provider.dart';

class Library extends StatefulWidget {
  const Library({Key? key}) : super(key: key);

  @override
  _LibraryState createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  String _outputPath = "";

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    Directory appDocumentDir = await getApplicationDocumentsDirectory();
    String rawDocumentPath = appDocumentDir.path;
    _outputPath = rawDocumentPath;
  }

  void uploadAudioFile() async {
    print(_outputPath);
    AudioFile? file = await selectFileForPlayer(_LibraryState()._outputPath);
    if (file != null) {
      var library = context.read<LibraryModel>();
      library.addAudioFile(file);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var libraryLength = context
        .select<LibraryModel, int>((library) => library.getLibraryLength());

    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            uploadAudioFile();
          },
          child: const Icon(Icons.file_upload),
          backgroundColor: Colors.blue,
        ),
        body: CustomScrollView(
          slivers: [
            _MyAppBar(),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                  (context, index) => _MyListItem(index),
                  childCount: libraryLength),
            ),
          ],
        ),
        drawer: Drawer(
            child: ListView(
          children: <Widget>[
            Container(height: 20.0),
            ListTile(
              leading: Icon(Icons.file_upload),
              title: Text("Upload New Audio File"),
              onTap: () async {
                uploadAudioFile();
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Settings"),
            ),
          ],
        )));
  }
}

class _MyAppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      iconTheme: IconThemeData(color: Colors.blueGrey),
      backgroundColor: Colors.transparent,
      title: Text(
        'MyThirdEar',
        style: TextStyle(
          color: Colors.black,
          fontSize: 25,
        ),
      ),
      floating: true,
      pinned: true,
    );
  }
}

class _MyListItem extends StatelessWidget {
  final int index;

  const _MyListItem(this.index, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var item = context.select<LibraryModel, AudioFile>(
        (library) => library.getAllAudioFiles()[index]);

    return GestureDetector(
        onTap: () {
          MusicPlayer player = new MusicPlayer(audioFile: item);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  MusicPlayerScreen(player: player),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.only(right: 15, left: 15, bottom: 10),
          height: 90,
          child: Card(
              color: Color(0xFFBBDEFB),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  side: BorderSide(color: Colors.black, width: 0.5),
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: <Widget>[
                  Padding(padding: EdgeInsets.only(left: 10)),
                  Icon(Icons.music_note),
                  Padding(padding: EdgeInsets.only(left: 10)),
                  Expanded(
                    child: Text(item.name),
                  ),
                ],
              )),
        ));
  }
}
