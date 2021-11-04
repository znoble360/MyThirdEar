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

    // Using MultiProvider is convenient when providing multiple objects.
    return MultiProvider(
      providers: [
        // In this sample app, CatalogModel never changes, so a simple Provider
        // is sufficient.
        Provider(create: (context) => LibraryModel(audioFiles)),
        // CartModel is implemented as a ChangeNotifier, which calls for the use
        // of ChangeNotifierProvider. Moreover, CartModel depends
        // on CatalogModel, so a ProxyProvider is needed.
        // ChangeNotifierProxyProvider<LibraryModel, MusicPlayerModel>(
        //   create: (context) => CartModel(),
        //   update: (context, catalog, cart) {
        //     if (cart == null) throw ArgumentError.notNull('cart');
        //     cart.catalog = catalog;
        //     return cart;
        //   },
        // ),
      ],
      child: MaterialApp(
        title: 'MyThirdEar',
        theme: ThemeUtils(context).themeData,
        initialRoute: '/',
        routes: {
          '/': (context) => const Library(),
          // '/player': (context) => const MusicPlayer(url: '',)
        },
      ),
    );
  }
}