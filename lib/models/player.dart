import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:musictranscriptiontools/models/library.dart';

class MusicPlayerModel extends ChangeNotifier {
  /// The private field backing [catalog].
  late LibraryModel _library;

  /// Internal, private state of the cart. Stores the ids of each item.
  final AudioPlayer _player = AudioPlayer();

  /// The current catalog. Used to construct items from numeric ids.
  LibraryModel get library => _library;

  set library(LibraryModel newLibrary) {
    _library = newLibrary;
    // Notify listeners, in case the new catalog provides information
    // different from the previous one. For example, availability of an item
    // might have changed.
    notifyListeners();
  }

}