import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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
