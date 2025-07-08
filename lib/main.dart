import 'package:counterpp/l10n/app_localizations.dart';
import 'package:counterpp/models/settings.dart';
import 'package:counterpp/providers/counter_repository_provider.dart';
import 'package:counterpp/repository/counter_repository.dart';
import 'package:counterpp/screens/tab_screen.dart';
import 'package:counterpp/screens/tutorial_screen.dart';
import 'package:counterpp/widgets/loading_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

final theme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff0000ff)),
  textTheme: GoogleFonts.latoTextTheme(),
  useMaterial3: true,
);

void main() {
  runApp(const ProviderScope(
    child: App(),
  ));
}

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  bool showTutorial = true;

  Future<Settings> getSettings() {
    final CounterRepository counterRepository = ref.read(counterRepositoryProvider);
    return counterRepository.getSettings();
  }

  @override
  Widget build(BuildContext context) {
    final asyncValue = ref.watch(asyncCounterRepositoryProvider);
    return MaterialApp(
        // debugShowCheckedModeBanner: false,
        theme: theme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('fr'),
      ],
      home: asyncValue.when(
        data: (data) => FutureBuilder<Settings>(
          future: getSettings(),
          builder: (BuildContext ctx, AsyncSnapshot<Settings> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // While the future is running, show a loading indicator
              return const LoadingIndicator();
            } else if (snapshot.hasError) {
              if (!kReleaseMode) {
                debugPrint(snapshot.error.toString());
              }
              return const LoadingIndicator();
            } else {
              if (showTutorial && snapshot.data!.showTutorial != false) {
                final CounterRepository counterRepository = ref.read(counterRepositoryProvider);
                final Settings settings = Settings.copy(snapshot.data!);
                settings.showTutorial = false;
                counterRepository.updateSettings(settings);
                return TutorialScreen(continueCallback: () => setState(() {
                  showTutorial = false;
                }));
              } else {
                return const TabsScreen();
              }
            }
          },
        ),
        loading: () => const LoadingIndicator(),
        error: (err, stack) {
          if (!kReleaseMode) {
            debugPrint(stack.toString());
          }
          return const LoadingIndicator();
        },
      ),
    );
  }
}
