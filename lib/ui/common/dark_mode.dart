import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:MyThirdEar/data/blocs/blocs.dart';

class DarkModeToggle extends StatelessWidget {
  const DarkModeToggle({
    required Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsReady) {
            return IconButton(
              tooltip: "Theme Mode: " + describeEnum(state.themeMode),
              icon: Icon([
                Icons.brightness_auto,
                Icons.brightness_high,
                Icons.brightness_low,
              ][state.themeMode.index]),
              onPressed: () {
                ChangeSettings event = ChangeSettings(
                  state.settings
                    ..darkMode = !state.settings.darkMode
                    ..useSystemSetting = false,
                );
                BlocProvider.of<SettingsBloc>(context).add(event);
              },
            );
          }
          return Container();
        },
      ),
    );
  }
}
