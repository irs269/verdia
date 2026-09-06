import 'package:flutter_test/flutter_test.dart';
import 'package:verdia/features/reports/domain/environmental_report.dart';

void main() {
  group('ReportType', () {
    test('every type in `all` has a distinct, non-empty label', () {
      final labels = ReportType.all.map(ReportType.label).toSet();
      expect(labels.length, ReportType.all.length);
      expect(labels.every((l) => l.isNotEmpty), isTrue);
    });

    test('every type in `all` has a distinct, non-empty icon', () {
      final icons = ReportType.all.map(ReportType.icon).toSet();
      expect(icons.length, ReportType.all.length);
    });

    test('label falls back to "Autre" for an unknown type', () {
      expect(ReportType.label('unknown_type'), 'Autre');
    });
  });

  group('ReportStatus', () {
    test('labels every known status in French', () {
      expect(ReportStatus.label(ReportStatus.signale), 'Signalé');
      expect(ReportStatus.label(ReportStatus.enVerification), 'En vérification');
      expect(ReportStatus.label(ReportStatus.enCours), 'En cours');
      expect(ReportStatus.label(ReportStatus.resolu), 'Résolu');
      expect(ReportStatus.label(ReportStatus.rejete), 'Rejeté');
    });

    test('falls back to the raw value for an unknown status', () {
      expect(ReportStatus.label('mystery'), 'mystery');
    });
  });
}
