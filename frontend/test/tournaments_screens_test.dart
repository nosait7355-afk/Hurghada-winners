// اختبارات واجهة شاشات البطولات: تعرض الشاشات الحقيقية ببيانات نموذجية (بدون شبكة)
// على مقاس موبايل وديسكتوب، وتفشل عند أي خطأ في الرسم أو overflow أو استثناء.
import 'package:hurghada_winners/features/academy/domain/entities/academy_entity.dart';
import 'package:hurghada_winners/features/academy/presentation/providers/academy_provider.dart';
import 'package:hurghada_winners/features/auth/domain/entities/user_entity.dart';
import 'package:hurghada_winners/features/auth/presentation/providers/auth_provider.dart';
import 'package:hurghada_winners/features/tournaments/data/tournament_models.dart';
import 'package:hurghada_winners/features/tournaments/presentation/providers/tournaments_providers.dart';
import 'package:hurghada_winners/features/tournaments/presentation/screens/player_tournaments_screen.dart';
import 'package:hurghada_winners/features/tournaments/presentation/screens/tournament_detail_screen.dart';
import 'package:hurghada_winners/features/tournaments/presentation/screens/tournament_form_screen.dart';
import 'package:hurghada_winners/features/tournaments/presentation/screens/tournaments_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuth extends AuthNotifier {
  @override
  Future<AuthState> build() async => AuthState(
        isAuthenticated: true,
        user: UserEntity(id: 'u1', name: 'أدمن', email: 'a@x', role: UserRole.superAdmin, createdAt: DateTime(2026)),
      );
}

class _FakeAcademies extends AcademiesNotifier {
  @override
  Future<List<AcademyEntity>> build() async => const [];
}

Map<String, dynamic> _fx(String id, String stage, int round, int no, String? a, String? b,
        {int? sa, int? sb, String? w, String status = 'pending', int? g, List<List<int>>? sets, int? pa, int? pb}) =>
    {
      '_id': id, 'stage': stage, 'round': round, 'matchNo': no, 'aId': a, 'bId': b, 'scoreA': sa, 'scoreB': sb,
      'winnerId': w, 'status': status, 'groupIndex': g, 'penaltiesA': pa, 'penaltiesB': pb,
      'sets': (sets ?? []).map((s) => {'a': s[0], 'b': s[1]}).toList(), 'date': '2026-11-10', 'time': '17:00',
      'location': 'ملعب الأكاديمية',
    };

/// مجموعات ثم كأس، فرق، أهداف، مع ترجيح — بعضها ملعوب.
TournamentDetail _groupsDetail() {
  final teams = List.generate(8, (i) => {
        '_id': 't$i', 'name': 'فريق رقم ${i + 1} باسم طويل جداً للتجربة', 'playerIds': ['p${i * 2}', 'p${i * 2 + 1}'],
        'captainId': 'p${i * 2}', 'seed': i + 1, 'groupIndex': i % 2,
      });
  final fixtures = <Map<String, dynamic>>[
    _fx('g1', 'group', 1, 1, 't0', 't2', sa: 3, sb: 1, w: 't0', status: 'played', g: 0),
    _fx('g2', 'group', 1, 2, 't4', 't6', sa: 1, sb: 1, status: 'played', g: 0),
    _fx('g3', 'group', 1, 1, 't1', 't3', g: 1),
    _fx('k1', 'knockout', 1, 1, 't0', 't3', sa: 2, sb: 2, pa: 4, pb: 3, w: 't0', status: 'played'),
    _fx('k2', 'knockout', 1, 2, 't1', 't2'),
    _fx('k3', 'knockout', 2, 1, 't0', null),
  ];
  List<Map<String, dynamic>> rows(int g) => [
        for (var i = 0; i < 4; i++)
          {
            'id': 't${i * 2 + g}', 'position': i + 1, 'played': 3, 'won': 2, 'drawn': 0, 'lost': 1,
            'for': 7, 'against': 4, 'diff': 3, 'points': 6 - i,
          },
      ];
  return TournamentDetail.fromJson({
    'tournament': {
      '_id': 'T1', 'name': 'دوري الناشئين الكبير 2026', 'academyIds': ['A'], 'participantType': 'team',
      'format': 'groups_knockout', 'drawMode': 'directed', 'status': 'running', 'notes': 'الجوائز للمراكز الثلاثة الأولى',
      'scoring': {'mode': 'goals'}, 'league': {}, 'groups': {'count': 2, 'qualifiersPerGroup': 2},
      'knockout': {'penaltiesEnabled': true, 'penaltiesCount': 5}, 'visibleToPlayers': true,
    },
    'participants': teams,
    'players': List.generate(16, (i) => {'_id': 'p$i', 'fullName': 'لاعب $i'}),
    'fixtures': fixtures,
    'standings': [
      {'groupIndex': 0, 'rows': rows(0)},
      {'groupIndex': 1, 'rows': rows(1)},
    ],
    'myParticipantId': 't0',
    'canManage': true,
  });
}

/// كأس فردي بالأشواط في مرحلة الإعداد، قرعة موجّهة.
TournamentDetail _draftSetsDetail() => TournamentDetail.fromJson({
      'tournament': {
        '_id': 'T2', 'name': 'كأس التنس', 'academyIds': ['A'], 'participantType': 'individual', 'format': 'knockout',
        'drawMode': 'directed', 'status': 'draft', 'scoring': {'mode': 'sets', 'bestOf': 3, 'pointsPerSet': 11},
      },
      'participants':
          List.generate(5, (i) => {'_id': 'x$i', 'name': 'لاعب فردي $i', 'playerIds': ['q$i'], 'seed': i + 1}),
      'players': [],
      'fixtures': [],
      'standings': [],
      'canManage': true,
    });

/// كأس فردي بالأشواط جاري مع صعود مباشر.
TournamentDetail _setsRunning() => TournamentDetail.fromJson({
      'tournament': {
        '_id': 'T3', 'name': 'كأس الاسكواش', 'academyIds': ['A'], 'participantType': 'individual', 'format': 'knockout',
        'status': 'running', 'scoring': {'mode': 'sets', 'bestOf': 3, 'pointsPerSet': 11},
      },
      'participants': List.generate(3, (i) => {'_id': 'x$i', 'name': 'لاعب $i', 'playerIds': ['q$i']}),
      'fixtures': [
        _fx('a', 'knockout', 1, 1, 'x0', null, status: 'bye', w: 'x0'),
        _fx('b', 'knockout', 1, 2, 'x1', 'x2', sa: 2, sb: 1, w: 'x1', status: 'played', sets: [
          [11, 7],
          [9, 11],
          [12, 10],
        ]),
        _fx('c', 'knockout', 2, 1, 'x0', 'x1'),
      ],
      'standings': [],
      'canManage': true,
    });

const _sizes = {'phone': Size(390, 844), 'desktop': Size(1366, 768)};

Future<void> _pump(WidgetTester tester, Widget screen, List<Override> overrides, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: ScreenUtilInit(
      // نفس منطق main.dart: الويب العريض يستخدم 1366x768.
      designSize: size.width >= 700 ? const Size(1366, 768) : const Size(390, 844),
      builder: (_, __) => MaterialApp(
        builder: (c, w) => Directionality(textDirection: TextDirection.rtl, child: w!),
        home: screen,
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text).first);
  await tester.pumpAndSettle();
}

void main() {
  for (final entry in _sizes.entries) {
    final size = entry.value;
    final tag = entry.key;

    testWidgets('admin detail (groups+cup, running) all tabs + fixture sheet [$tag]', (tester) async {
      final d = _groupsDetail();
      await _pump(tester, const TournamentDetailScreen(tournamentId: 'T1', academyId: 'A'),
          [tournamentDetailProvider.overrideWith((ref, id) async => d)], size);
      expect(find.text('دوري الناشئين الكبير 2026'), findsOneWidget);
      // يفتح على تبويب المباريات (البطولة جارية)؛ 4 فرق في الكأس = نصف النهائي.
      expect(find.text('نصف النهائي'), findsWidgets);
      expect(find.textContaining('ترجيح 4 - 3'), findsOneWidget);
      // نافذة مباراة ملعوبة (أول مباراة: فريق 1 ضد فريق 3)
      await tester.tap(find.text('3 - 1').first);
      await tester.pumpAndSettle();
      expect(find.text('تعديل النتيجة'), findsOneWidget);
      expect(find.text('مسح النتيجة'), findsOneWidget);
      Navigator.of(tester.element(find.text('تعديل النتيجة'))).pop();
      await tester.pumpAndSettle();
      await _tapText(tester, 'الترتيب');
      expect(find.text('المجموعة أ'), findsOneWidget);
      expect(find.text('شجرة الكأس'), findsOneWidget);
      await _tapText(tester, 'المشاركون');
      expect(find.textContaining('★'), findsWidgets);
    });

    testWidgets('knockout result sheet asks for penalties on a draw [$tag]', (tester) async {
      final d = _groupsDetail();
      await _pump(tester, const TournamentDetailScreen(tournamentId: 'T1', academyId: 'A'),
          [tournamentDetailProvider.overrideWith((ref, id) async => d)], size);
      // مباراة الكأس غير الملعوبة: فريق 2 ضد فريق 3
      await tester.scrollUntilVisible(find.textContaining('فريق رقم 2 ').last, 200,
          scrollable: find.byType(Scrollable).last);
      await tester.tap(find.textContaining('فريق رقم 2 ').last);
      await tester.pumpAndSettle();
      expect(find.text('حفظ النتيجة'), findsOneWidget);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '1');
      await tester.enterText(fields.at(1), '1');
      await tester.pumpAndSettle();
      expect(find.textContaining('ضربات الترجيح'), findsOneWidget);
    });

    testWidgets('draft directed individual: reorder list + generate button [$tag]', (tester) async {
      final d = _draftSetsDetail();
      await _pump(tester, const TournamentDetailScreen(tournamentId: 'T2', academyId: 'A'),
          [tournamentDetailProvider.overrideWith((ref, id) async => d)], size);
      expect(find.textContaining('اسحب لترتيب'), findsOneWidget);
      expect(find.byIcon(Icons.drag_handle), findsNWidgets(5));
      expect(find.textContaining('توليد جدول المباريات'), findsOneWidget);
      expect(find.text('إضافة لاعب'), findsOneWidget);
      await _tapText(tester, 'المباريات');
      expect(find.text('لم يتم توليد جدول المباريات بعد'), findsOneWidget);
    });

    testWidgets('sets cup: bye card, sets text, sets result sheet [$tag]', (tester) async {
      final d = _setsRunning();
      await _pump(tester, const TournamentDetailScreen(tournamentId: 'T3', academyId: 'A'),
          [tournamentDetailProvider.overrideWith((ref, id) async => d)], size);
      expect(find.text('صعود مباشر'), findsOneWidget);
      expect(find.textContaining('الأشواط: 11-7'), findsOneWidget);
      // النهائي: لاعب 0 ضد لاعب 1
      await tester.tap(find.text('لاعب 0').last);
      await tester.pumpAndSettle();
      expect(find.text('الشوط 3'), findsOneWidget);
    });

    testWidgets('list screen + player screens [$tag]', (tester) async {
      final d = _groupsDetail();
      await _pump(tester, const TournamentsListScreen(academyId: 'A'), [
        tournamentsListProvider.overrideWith((ref, id) async => [d.tournament, _draftSetsDetail().tournament]),
      ], size);
      expect(find.text('كأس التنس'), findsOneWidget);
      expect(find.text('إعداد'), findsOneWidget);
    });

    testWidgets('player tournament page [$tag]', (tester) async {
      final d = _groupsDetail();
      await _pump(tester, const PlayerTournamentDetailScreen(tournamentId: 'T1'),
          [playerTournamentDetailProvider.overrideWith((ref, id) async => d)], size);
      expect(find.text('مبارياتي'), findsOneWidget);
      expect(find.textContaining('فريقك:'), findsOneWidget);
      expect(find.textContaining('(الكابتن)'), findsOneWidget);
      await _tapText(tester, 'الترتيب');
      expect(find.text('شجرة الكأس'), findsOneWidget);
    });

    testWidgets('form screen: switching options shows the right sections [$tag]', (tester) async {
      await _pump(tester, const TournamentFormScreen(academyId: 'A'), [
        authStateProvider.overrideWith(_FakeAuth.new),
        academiesProvider.overrideWith(_FakeAcademies.new),
      ], size);
      expect(find.text('نقاط الدوري'), findsOneWidget);
      await _tapText(tester, 'أشواط');
      expect(find.text('عدد الأشواط'), findsOneWidget);
      await _tapText(tester, 'كأس (خروج مغلوب)');
      expect(find.text('نقاط الدوري'), findsNothing);
      await _tapText(tester, 'أهداف / نقاط');
      await tester.scrollUntilVisible(find.text('ضربات ترجيح عند التعادل'), 200,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('ضربات ترجيح عند التعادل'), findsOneWidget);
    });
  }
}
