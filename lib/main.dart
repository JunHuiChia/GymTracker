import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'data/workout_store.dart';
import 'screens/home_screen.dart';
import 'theme.dart';
export 'theme.dart' show appTheme;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Lora',
    ], await rootBundle.loadString('assets/fonts/OFL-Lora.txt'));
  });
  runApp(const GymTrackerApp());
}

class GymTrackerApp extends StatefulWidget {
  const GymTrackerApp({super.key, this.store});
  final WorkoutStore? store;
  @override
  State<GymTrackerApp> createState() => _GymTrackerAppState();
}

class _GymTrackerAppState extends State<GymTrackerApp> {
  late Future<WorkoutStore> _store;
  @override
  void initState() {
    super.initState();
    _store = widget.store == null
        ? WorkoutStore.open()
        : Future.value(widget.store);
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'GymTracker',
    debugShowCheckedModeBanner: false,
    theme: appTheme(Brightness.light),
    darkTheme: appTheme(Brightness.dark),
    home: FutureBuilder<WorkoutStore>(
      future: _store,
      builder: (context, snapshot) {
        if (snapshot.hasData) return HomeScreen(store: snapshot.data!);
        return Scaffold(
          appBar: AppBar(title: const Text('GymTracker')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: snapshot.hasError
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storage_outlined, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Your workout data could not be opened. No data has been reset.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => setState(() {
                            _store = WorkoutStore.open();
                          }),
                          child: const Text('Try again'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        );
      },
    ),
  );
}
