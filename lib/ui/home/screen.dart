// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';

// import 'package:musictranscriptiontools/data/blocs/blocs.dart';
// import 'package:musictranscriptiontools/data/blocs/settings/settings.dart';
// import 'package:musictranscriptiontools/plugins/app_review/app_review.dart';
// import 'package:musictranscriptiontools/screens/player.dart';
// import 'package:musictranscriptiontools/ui/common/index.dart';
// import 'package:musictranscriptiontools/ui/common/piano_view.dart';

// class HomeScreen extends StatefulWidget {
//   String url;

//   HomeScreen({required this.url});
//   @override
//   _HomeScreenState createState() => _HomeScreenState();
// }

// class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
//   bool canVibrate = false;
//   bool hideRTA = true;

//   @override
//   void initState() {
//     super.initState();
//     Future.delayed(Duration(seconds: 60)).then((_) {
//       if (mounted) ReviewUtils.requestReview();
//     });
//   }

//   onChanged() {}

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<SettingsBloc, SettingsState>(
//       builder: (context, state) => Scaffold(
//         drawer: Drawer(
//             child: SafeArea(
//           child: ListView(children: <Widget>[
//             Container(height: 20.0),
//             ListTile(
//               leading: Icon(Icons.settings),
//               title: Text("Pick Music File"),
//               onTap: () {
//                 // Navigator.of(context).push(
//                 //     MaterialPageRoute(builder: (context) => SettingsScreen()));
//               },
//             ),
//             ListTile(
//               title: Text("Return Home Page"),
//               onTap: () {
//                 Navigator.pop(context);
//                 Navigator.pop(context);
//               },
//             ),
//           ]),
//         )),
//         appBar: (AppBar(
//           title: Text(
//             'MyThirdEar',
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontFamily: 'Indies',
//               fontSize: 25.0,
//             ),
//           ),
          
//         )),
//         body: Column(
//           mainAxisSize: MainAxisSize.max,
//           mainAxisAlignment: MainAxisAlignment.end,
//           children: [
//             Container(
//               height: 450.h,
//               child: MusicPlayer(url: widget.url),
//             ),
//             Align(
//               alignment: Alignment.centerRight,
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text('Show Spectrogram'),
//                   Checkbox(
//                       value: hideRTA,
//                       onChanged: (value) {
//                         setState(() {
//                           hideRTA = value!;
//                         });
//                       })
//                 ],
//               ),
//             ),
//             SizedBox(height: 5),
//             Row(
//               mainAxisSize: MainAxisSize.max,
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   children: [
//                     Text(hideRTA ? 'Estimated Chord' : ''),
//                     Text(hideRTA ? 'Cmaj7' : ''),
//                   ],
//                 ),
//                 Column(
//                   children: [
//                     Text(hideRTA ? 'Estimated BPM' : ''),
//                     Text(hideRTA ? '117' : ''),
//                   ],
//                 ),
//               ],
//             ),
//             SizedBox(height: 120.h),
//             Container(
//               height: 450.h,
//               color: hideRTA ? Colors.black : Colors.transparent,
//               child: hideRTA ? getBody(state) : Container(),
//             )
//           ],
//         ),
//       ),
//     );
//   }

//   getBody(state) {
//     return state is SettingsReady
//         ? Container(
//             color: state.settings.darkMode ? null : Colors.grey[300],
//             child: Transform.scale(
//               scale: 1,
//               child: _buildKeys(context, state.settings),
//             ))
//         : Container(child: Center(child: CircularProgressIndicator()));
//   }

//   Widget _buildKeys(BuildContext context, Settings settings) {
//     double keyWidth = 60.w + (100.w * (settings.widthRatio));
//     final _vibrate = settings.shouldVibrate && canVibrate;
//     if (MediaQuery.of(context).size.height == 600) {
//       return Flex(
//         direction: Axis.vertical,
//         children: <Widget>[
//           Flexible(
//             child: PianoView(
//               keyWidth: keyWidth,
//               showLabels: settings.showLabels,
//               labelsOnlyOctaves: settings.labelsOnlyOctaves,
//               disableScroll: settings.disableScroll,
//               feedback: _vibrate,
//             ),
//           ),
//           Flexible(
//             child: PianoView(
//               keyWidth: keyWidth,
//               showLabels: settings.showLabels,
//               labelsOnlyOctaves: settings.labelsOnlyOctaves,
//               disableScroll: settings.disableScroll,
//               feedback: _vibrate,
//             ),
//           ),
//         ],
//       );
//     }
//     return PianoView(
//       keyWidth: keyWidth,
//       showLabels: settings.showLabels,
//       labelsOnlyOctaves: settings.labelsOnlyOctaves,
//       disableScroll: settings.disableScroll,
//       feedback: _vibrate,
//     );
//   }
// }
