import 'package:flutter_test/flutter_test.dart';
import 'package:verdia/features/moderation/domain/content_report.dart';

Map<String, dynamic> _reportMap({String? description, String status = 'pending'}) {
  return {
    'id': 'report-1',
    'reporter_id': 'reporter-1',
    'target_type': 'comment',
    'target_id': 'comment-1',
    'reason': 'spam',
    'description': description,
    'status': status,
    'created_at': '2026-09-05T10:00:00Z',
  };
}

void main() {
  group('Report.fromMap', () {
    test('parses a full row', () {
      final report = Report.fromMap(_reportMap(description: 'Contenu publicitaire répété'));
      expect(report.id, 'report-1');
      expect(report.targetType, ReportTargetType.comment);
      expect(report.reason, 'spam');
      expect(report.description, 'Contenu publicitaire répété');
      expect(report.status, 'pending');
    });

    test('description is null when absent', () {
      final report = Report.fromMap(_reportMap());
      expect(report.description, isNull);
    });
  });

  group('ReportTargetType.fromValue', () {
    test('maps "comment" to ReportTargetType.comment', () {
      expect(ReportTargetType.fromValue('comment'), ReportTargetType.comment);
    });

    test('maps "post" to ReportTargetType.post', () {
      expect(ReportTargetType.fromValue('post'), ReportTargetType.post);
    });
  });

  group('ReportStatus.label', () {
    test('labels every known status in French', () {
      expect(ReportStatus.label(ReportStatus.pending), 'En attente');
      expect(ReportStatus.label(ReportStatus.reviewed), 'Traité');
      expect(ReportStatus.label(ReportStatus.dismissed), 'Ignoré');
    });
  });
}
