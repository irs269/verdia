import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:verdia/main.dart' as app;

/// Test d'intégration minimal : démarre réellement l'application (le même
/// `main()` qu'en production — dotenv, Supabase.initialize, GoRouter) et
/// vérifie qu'elle atteint l'onboarding ou l'écran de connexion sans
/// planter. Les parcours complets (inscription, publication, likes,
/// notifications temps réel, sécurité RLS...) ont été vérifiés
/// manuellement de bout en bout à chaque phase via le navigateur — voir la
/// mémoire du projet — plutôt que ré-automatisés ici avec de vrais comptes,
/// pour éviter de dépendre d'un projet Supabase de test dédié.
///
/// À exécuter avec : flutter test integration_test/app_test.dart -d windows
/// (ou -d chrome/edge, si chromedriver est configuré).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the app boots to onboarding without crashing', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Par ce point le splash (délai de 600 ms) a déjà cédé la place à
    // l'onboarding — voir `redirect` dans app_router.dart.
    expect(find.text('Agis pour ta planète'), findsOneWidget);
    expect(find.text('Commencer'), findsNothing); // page 1/4, pas la dernière
    expect(find.text('Suivant'), findsOneWidget);
  });
}
