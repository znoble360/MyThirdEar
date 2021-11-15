import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:musictranscriptiontools/screens/library.dart';
import 'package:musictranscriptiontools/models/library.dart';
import 'package:musictranscriptiontools/ui/home/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<AudioFile> audioFiles = [];
    // get cached files here
    // audioFiles = getCachedFiles()

    return MultiProvider(
      providers: [
        Provider(create: (context) => LibraryModel(audioFiles))
      ],
      child: MaterialApp(
        title: 'MyThirdEar',
        theme: ThemeUtils(context).themeData,
        initialRoute: '/',
        routes: {
          '/': (context) => const Library()
        },
      ),
    );
  }
}