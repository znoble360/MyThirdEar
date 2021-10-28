import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musictranscriptiontools/Home.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:musictranscriptiontools/data/blocs/blocs.dart';
import 'package:musictranscriptiontools/ui/theme.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _settingsBloc = SettingsBloc();

  @override
  void initState() {
    _settingsBloc.add(CheckSettings());
    super.initState();
  }

  @override
  void dispose() {
    _settingsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeUtils(context);
    return ScreenUtilInit(
        designSize: Size(750, 1624),
        builder: () => MultiBlocProvider(
              providers: [
                BlocProvider<SettingsBloc>(create: (_) => _settingsBloc),
              ],
                child: BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, settingState) {
                    ThemeMode mode = ThemeMode.system;
                    if (settingState is SettingsReady) {
                      mode = settingState.themeMode;
                    }
                    return MaterialApp(
                      debugShowCheckedModeBanner: false,
                      theme: theme.light,
                      themeMode: mode,
                      home: Home(),
                      onGenerateTitle: (context) => "My Third Ear",
                      locale: Locale("en", "US"),
                    );
                  },
                ),
            ));
  }
}