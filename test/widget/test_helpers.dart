import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verdia/l10n/app_localizations.dart';

/// Plusieurs de nos écrans (formulaires à plusieurs champs) dépassent la
/// taille par défaut de la surface de test (800x600) : sans agrandir la
/// vue, les boutons en bas de page tombent hors des limites du rendu et
/// `tester.tap` échoue silencieusement sur un offset invalide.
void useTallTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// `MaterialApp` avec les délégués de localisation branchés — nécessaire dès
/// qu'un écran pompé utilise `AppLocalizations.of(context)!` (sinon l'appel
/// retourne `null` et l'écran ne se construit jamais).
Widget wrapLocalized(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}
