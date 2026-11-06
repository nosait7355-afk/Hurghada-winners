// نماذج البطولات (دوري / كأس / مجموعات) — مطابقة لـ /api/v1/tournaments.

String _s(dynamic v) => v?.toString() ?? '';
String? _ns(dynamic v) => v?.toString();
int _i(dynamic v, [int d = 0]) => (v as num?)?.toInt() ?? d;
int? _ni(dynamic v) => (v as num?)?.toInt();
bool _b(dynamic v, [bool d = false]) => v is bool ? v : d;
Map<String, dynamic> _m(dynamic v) => v is Map<String, dynamic> ? v : <String, dynamic>{};

const formatLabels = {
  'league': 'دوري',
  'knockout': 'كأس (خروج مغلوب)',
  'groups_knockout': 'مجموعات ثم كأس',
};
const statusLabels = {'draft': 'إعداد', 'running': 'جارية', 'finished': 'منتهية'};

class ScoringRules {
  final String mode; // goals | sets
  final int bestOf;
  final int pointsPerSet;
  final bool winByTwo;
  final int? maxPointsPerSet;
  const ScoringRules({
    this.mode = 'goals',
    this.bestOf = 3,
    this.pointsPerSet = 11,
    this.winByTwo = true,
    this.maxPointsPerSet,
  });
  bool get isSets => mode == 'sets';
  factory ScoringRules.fromJson(Map<String, dynamic> j) => ScoringRules(
        mode: _s(j['mode']).isEmpty ? 'goals' : _s(j['mode']),
        bestOf: _i(j['bestOf'], 3),
        pointsPerSet: _i(j['pointsPerSet'], 11),
        winByTwo: _b(j['winByTwo'], true),
        maxPointsPerSet: _ni(j['maxPointsPerSet']),
      );
  Map<String, dynamic> toJson() => {
        'mode': mode,
        'bestOf': bestOf,
        'pointsPerSet': pointsPerSet,
        'winByTwo': winByTwo,
        'maxPointsPerSet': maxPointsPerSet,
      };
}

class LeagueRules {
  final int winPoints, drawPoints, lossPoints;
  final bool doubleRound, allowDraws;
  const LeagueRules({
    this.winPoints = 3,
    this.drawPoints = 1,
    this.lossPoints = 0,
    this.doubleRound = false,
    this.allowDraws = true,
  });
  factory LeagueRules.fromJson(Map<String, dynamic> j) => LeagueRules(
        winPoints: _i(j['winPoints'], 3),
        drawPoints: _i(j['drawPoints'], 1),
        lossPoints: _i(j['lossPoints'], 0),
        doubleRound: _b(j['doubleRound']),
        allowDraws: _b(j['allowDraws'], true),
      );
  Map<String, dynamic> toJson() => {
        'winPoints': winPoints,
        'drawPoints': drawPoints,
        'lossPoints': lossPoints,
        'doubleRound': doubleRound,
        'allowDraws': allowDraws,
      };
}

class Tournament {
  final String id;
  final String name;
  final List<String> academyIds;
  final String? sport;
  final String ageGroup;
  final String? startDate, endDate;
  final String notes;
  final String participantType; // individual | team
  final String format;
  final String drawMode; // random | directed
  final ScoringRules scoring;
  final LeagueRules league;
  final int groupsCount, qualifiersPerGroup;
  final bool penaltiesEnabled;
  final int penaltiesCount;
  final String status;
  final bool visibleToPlayers;
  final int participantsCount;
  final bool canManage;
  final bool isParticipant;

  const Tournament({
    required this.id,
    required this.name,
    this.academyIds = const [],
    this.sport,
    this.ageGroup = '',
    this.startDate,
    this.endDate,
    this.notes = '',
    this.participantType = 'team',
    this.format = 'league',
    this.drawMode = 'random',
    this.scoring = const ScoringRules(),
    this.league = const LeagueRules(),
    this.groupsCount = 2,
    this.qualifiersPerGroup = 2,
    this.penaltiesEnabled = true,
    this.penaltiesCount = 5,
    this.status = 'draft',
    this.visibleToPlayers = true,
    this.participantsCount = 0,
    this.canManage = false,
    this.isParticipant = false,
  });

  bool get isTeam => participantType == 'team';
  bool get isDraft => status == 'draft';
  bool get isDirected => drawMode == 'directed';
  bool get hasLeagueTable => format != 'knockout';
  bool get hasBracket => format != 'league';

  factory Tournament.fromJson(Map<String, dynamic> j) {
    final g = _m(j['groups']);
    final k = _m(j['knockout']);
    return Tournament(
      id: _s(j['_id'] ?? j['id']),
      name: _s(j['name']),
      academyIds: (j['academyIds'] as List? ?? []).map((e) => e.toString()).toList(),
      sport: _ns(j['sport']),
      ageGroup: _s(j['ageGroup']),
      startDate: _ns(j['startDate']),
      endDate: _ns(j['endDate']),
      notes: _s(j['notes']),
      participantType: _s(j['participantType']).isEmpty ? 'team' : _s(j['participantType']),
      format: _s(j['format']).isEmpty ? 'league' : _s(j['format']),
      drawMode: _s(j['drawMode']).isEmpty ? 'random' : _s(j['drawMode']),
      scoring: ScoringRules.fromJson(_m(j['scoring'])),
      league: LeagueRules.fromJson(_m(j['league'])),
      groupsCount: _i(g['count'], 2),
      qualifiersPerGroup: _i(g['qualifiersPerGroup'], 2),
      penaltiesEnabled: _b(k['penaltiesEnabled'], true),
      penaltiesCount: _i(k['penaltiesCount'], 5),
      status: _s(j['status']).isEmpty ? 'draft' : _s(j['status']),
      visibleToPlayers: _b(j['visibleToPlayers'], true),
      participantsCount: _i(j['participantsCount']),
      canManage: _b(j['canManage']),
      isParticipant: _b(j['isParticipant']),
    );
  }
}

class TournamentParticipant {
  final String id;
  final String name;
  final List<String> playerIds;
  final String? captainId;
  final int? seed;
  final int? groupIndex;
  const TournamentParticipant({
    required this.id,
    required this.name,
    this.playerIds = const [],
    this.captainId,
    this.seed,
    this.groupIndex,
  });
  factory TournamentParticipant.fromJson(Map<String, dynamic> j) => TournamentParticipant(
        id: _s(j['_id'] ?? j['id']),
        name: _s(j['name']),
        playerIds: (j['playerIds'] as List? ?? []).map((e) => e.toString()).toList(),
        captainId: _ns(j['captainId']),
        seed: _ni(j['seed']),
        groupIndex: _ni(j['groupIndex']),
      );
}

class SetScore {
  final int a, b;
  const SetScore(this.a, this.b);
  Map<String, dynamic> toJson() => {'a': a, 'b': b};
}

class TournamentFixture {
  final String id;
  final String stage; // league | group | knockout
  final int? groupIndex;
  final int round, matchNo;
  final String? aId, bId, winnerId;
  final int? scoreA, scoreB, penaltiesA, penaltiesB;
  final List<SetScore> sets;
  final String status; // pending | played | bye
  final String? date, time;
  final String location;

  const TournamentFixture({
    required this.id,
    required this.stage,
    this.groupIndex,
    required this.round,
    required this.matchNo,
    this.aId,
    this.bId,
    this.winnerId,
    this.scoreA,
    this.scoreB,
    this.penaltiesA,
    this.penaltiesB,
    this.sets = const [],
    this.status = 'pending',
    this.date,
    this.time,
    this.location = '',
  });

  bool get isPlayed => status == 'played';
  bool get isBye => status == 'bye';
  bool get isReady => aId != null && bId != null && !isBye;
  bool involves(String? participantId) =>
      participantId != null && (aId == participantId || bId == participantId);

  factory TournamentFixture.fromJson(Map<String, dynamic> j) => TournamentFixture(
        id: _s(j['_id'] ?? j['id']),
        stage: _s(j['stage']),
        groupIndex: _ni(j['groupIndex']),
        round: _i(j['round'], 1),
        matchNo: _i(j['matchNo'], 1),
        aId: _ns(j['aId']),
        bId: _ns(j['bId']),
        winnerId: _ns(j['winnerId']),
        scoreA: _ni(j['scoreA']),
        scoreB: _ni(j['scoreB']),
        penaltiesA: _ni(j['penaltiesA']),
        penaltiesB: _ni(j['penaltiesB']),
        sets: (j['sets'] as List? ?? []).map((s) => SetScore(_i(_m(s)['a']), _i(_m(s)['b']))).toList(),
        status: _s(j['status']).isEmpty ? 'pending' : _s(j['status']),
        date: _ns(j['date']),
        time: _ns(j['time']),
        location: _s(j['location']),
      );
}

class StandingRow {
  final String id;
  final int position, played, won, drawn, lost, goalsFor, against, diff, points;
  const StandingRow({
    required this.id,
    required this.position,
    required this.played,
    required this.won,
    required this.drawn,
    required this.lost,
    required this.goalsFor,
    required this.against,
    required this.diff,
    required this.points,
  });
  factory StandingRow.fromJson(Map<String, dynamic> j) => StandingRow(
        id: _s(j['id']),
        position: _i(j['position']),
        played: _i(j['played']),
        won: _i(j['won']),
        drawn: _i(j['drawn']),
        lost: _i(j['lost']),
        goalsFor: _i(j['for']),
        against: _i(j['against']),
        diff: _i(j['diff']),
        points: _i(j['points']),
      );
}

class StandingsGroup {
  final int? groupIndex;
  final List<StandingRow> rows;
  const StandingsGroup({this.groupIndex, this.rows = const []});
  factory StandingsGroup.fromJson(Map<String, dynamic> j) => StandingsGroup(
        groupIndex: _ni(j['groupIndex']),
        rows: (j['rows'] as List? ?? []).map((r) => StandingRow.fromJson(_m(r))).toList(),
      );
}

class TournamentPlayer {
  final String id;
  final String fullName;
  final String? imageUrl;
  final String? playerCode;
  const TournamentPlayer({required this.id, required this.fullName, this.imageUrl, this.playerCode});
  factory TournamentPlayer.fromJson(Map<String, dynamic> j) => TournamentPlayer(
        id: _s(j['_id'] ?? j['id']),
        fullName: _s(j['fullName']),
        imageUrl: _ns(j['image_url'] ?? j['imageUrl']),
        playerCode: _ns(j['playerCode']),
      );
}

class TournamentDetail {
  final Tournament tournament;
  final List<TournamentParticipant> participants;
  final List<TournamentPlayer> players;
  final List<TournamentFixture> fixtures;
  final List<StandingsGroup> standings;
  final String? myParticipantId;
  final bool canManage;

  const TournamentDetail({
    required this.tournament,
    this.participants = const [],
    this.players = const [],
    this.fixtures = const [],
    this.standings = const [],
    this.myParticipantId,
    this.canManage = false,
  });

  factory TournamentDetail.fromJson(Map<String, dynamic> j) => TournamentDetail(
        tournament: Tournament.fromJson(_m(j['tournament'])),
        participants: (j['participants'] as List? ?? [])
            .map((e) => TournamentParticipant.fromJson(_m(e)))
            .toList(),
        players: (j['players'] as List? ?? []).map((e) => TournamentPlayer.fromJson(_m(e))).toList(),
        fixtures: (j['fixtures'] as List? ?? []).map((e) => TournamentFixture.fromJson(_m(e))).toList(),
        standings: (j['standings'] as List? ?? []).map((e) => StandingsGroup.fromJson(_m(e))).toList(),
        myParticipantId: _ns(j['myParticipantId']),
        canManage: _b(j['canManage']),
      );

  TournamentParticipant? participant(String? id) {
    if (id == null) return null;
    for (final p in participants) {
      if (p.id == id) return p;
    }
    return null;
  }

  String nameOf(String? id) => participant(id)?.name ?? (id == null ? 'لم يتحدد' : '—');

  TournamentPlayer? player(String id) {
    for (final p in players) {
      if (p.id == id) return p;
    }
    return null;
  }

  List<TournamentFixture> get knockout => fixtures.where((f) => f.stage == 'knockout').toList();
  int get knockoutRounds => knockout.fold(0, (m, f) => f.round > m ? f.round : m);
}

/// اسم الدور في الكأس: النهائي، نصف النهائي، ربع النهائي، دور الـ16…
String knockoutRoundName(int round, int totalRounds) {
  final left = totalRounds - round;
  if (left == 0) return 'النهائي';
  if (left == 1) return 'نصف النهائي';
  if (left == 2) return 'ربع النهائي';
  return 'دور الـ${1 << (left + 1)}';
}

const _groupLetters = ['أ', 'ب', 'ج', 'د', 'هـ', 'و', 'ز', 'ح', 'ط', 'ي', 'ك', 'ل', 'م', 'ن', 'س', 'ع'];
String groupName(int? index) => index == null ? '' : 'المجموعة ${_groupLetters[index % _groupLetters.length]}';
