import 'dart:async';
import 'dart:io';

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

  // removes audio file data from Library model, Hive box, and file system
  void removeAudioFile(AudioFile audioFile, int index) async {
    var library = context.read<LibraryModel>();
    // remove file from library model
    library.deleteAudioFile(audioFile);

    // remove file from Hive DB
    _deleteAudioFileFromHive(audioFile, index);

    String folderName = audioFile.filepath.split('/')[0];
    Directory _appDocDir = await getApplicationDocumentsDirectory();

    // delete files from file system
    Directory directory = Directory('${_appDocDir.path}/$folderName');
    directory.delete(recursive: true);
    setState(() {});
  }

  // removes AudioFileData from Hive box
  _deleteAudioFileFromHive(AudioFile audioFile, int index) {
    box.deleteAt(index);
    print('${audioFile.name} was removed from the box!');
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
            ));
  }

  getContentView() {
    if (box.length == 0) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
            (context, index) => Center(
                  child: Column(
                    children: [
                      SizedBox(height: 100),
                      Icon(
                        Icons.music_note,
                        color: Colors.black,
                        size: 60,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'No audio files yet...',
                        style: TextStyle(fontSize: 25),
                      )
                    ],
                  ),
                ),
            childCount: 1),
      );
    } else {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
            (context, index) => _MyListItem(index, box, removeAudioFile),
            childCount: box.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () async {
        //     if (await uploadAudioFile() == false) return showMyDialog(context);
        //   },
        //   child: const Icon(Icons.file_upload),
        //   backgroundColor: Colors.blue,
        // ),
        body: Stack(
          children: [
            CustomScrollView(
              slivers: [
                _MyAppBar(),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                getContentView()
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: GestureDetector(
                  onTap: () async {
                    if (await uploadAudioFile() == false)
                      return showMyDialog(context);
                  },
                  child: Container(
                    width: 150,
                    height: 50,
                    margin: EdgeInsets.only(bottom: 50, right: 15),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                        border: Border.all(color: Colors.blue, width: 1)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Upload New File'),
                        SizedBox(width: 5),
                        Icon(Icons.file_upload, color: Colors.blue)
                      ],
                    ),
                  )),
            )
          ],
        ),
        drawer: Drawer(
            child: ListView(
          children: <Widget>[
            Container(height: 20.0),
            ListTile(
              leading: Icon(Icons.file_upload, color: Colors.blue),
              title: Text("Upload New Audio File"),
              onTap: () async {
                if (await uploadAudioFile() == false)
                  return showMyDialog(context);
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

class _MyListItem extends StatefulWidget {
  final int index;
  final currentBox;
  final callback;

  const _MyListItem(this.index, this.currentBox, this.callback, {Key? key})
      : super(key: key);

  @override
  _MyListItemState createState() => _MyListItemState();
}

class _MyListItemState extends State<_MyListItem> {
  var audioFileData;
  var item;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    audioFileData = widget.currentBox.getAt(widget.index)!;
    item = context.select<LibraryModel, AudioFile>(
        (library) => library.getAllAudioFiles()[widget.index]);

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
                  IconButton(
                      onPressed: () => _showConfirmDeleteDialog(),
                      icon: Icon(Icons.delete)),
                  Padding(padding: EdgeInsets.only(right: 15)),
                ],
              )),
        ));
  }

  void _showConfirmDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("Are you sure you want to delete this file?"),
          content: new Text(
              "This will delete all metadata and the related files from the file system."),
          actions: <Widget>[
            new TextButton(
              child: new Text("Confirm Delete"),
              onPressed: () {
                widget.callback(item, widget.index);
                Navigator.of(context).pop();
              },
            ),
            new TextButton(
              child: new Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
