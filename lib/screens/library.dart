import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:musictranscriptiontools/models/audioFile.dart';
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
  var _appDocDir;
  late final Box box;

  // Add the information about the audio file uploaded to the 'audioFileData' Hive box
  _addAudioFileToHive(AudioFile audioFile) async {
    AudioFileData newAudioFileData = new AudioFileData(
        name: audioFile.name,
        author: audioFile.author,
        filepath: audioFile.filepath,
        waveformBinPath: audioFile.waveformBinPath);
    box.add(newAudioFileData);
    print('newAudioFileData added to box!');
  }

  @override
  void initState() {
    super.initState();
    // Initialize Hive box
    box = Hive.box('audioFileData');
    _init();
  }

  @override
  void dispose() {
    // Closes all Hive boxes
    Hive.close();
    super.dispose();
  }

  Future<void> _init() async {
    _appDocDir = await getApplicationDocumentsDirectory();
  }

  // Uploads audio file, adds it to the current library state and to the Hive box
  Future<bool> uploadAudioFile() async {
    AudioFile? file = await selectFileForPlayer(_appDocDir);
    if (file != null) {
      var library = context.read<LibraryModel>();
      library.addAudioFile(file);
      _addAudioFileToHive(file);
      setState(() {});
      // If we got a new file return true
      return true;
    }
    setState(() {});
    // if it's a duplicate file, return false and show the dialog box
    return false;
  }

  // Dialog box to show when the user uploads a duplicate file
  void showMyDialog(context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
        title: const Text('Duplicate File'),
        content: SingleChildScrollView(
          child: ListBody(
            children: const <Widget>[
              Text('It seems you have already uploaded this file.'),
              Text(''),
              Text('Please try to upload a new one.'),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Ok'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      )
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (await uploadAudioFile() == false) return showMyDialog(context);
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
                  (context, index) => _MyListItem(index, box),
                  childCount: box.length),
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
                if (await uploadAudioFile() == false) return showMyDialog(context);
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
  final currentBox;

  const _MyListItem(this.index, this.currentBox, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var audioFileData = currentBox.getAt(index)!;
    var item = context.select<LibraryModel, AudioFile>(
        (library) => library.getAllAudioFiles()[index]);

    return GestureDetector(
        onTap: () {
          MusicPlayer player = new MusicPlayer(audioFile: item);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MusicPlayerScreen(player: player),
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
                    child: Text(audioFileData.name),
                  ),
                ],
              )),
        ));
  }
}
