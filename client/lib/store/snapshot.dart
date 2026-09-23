import '../economy/economy.dart';
import 'economy_codec.dart';

List<String> _strings(Object? raw) => [for (final s in raw as List) s as String];

final class Profile {
  const Profile({required this.playerName, required this.petName, required this.lookId});
  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    playerName: j['playerName'] as String,
    petName: j['petName'] as String,
    lookId: j['lookId'] as String,
  );
  final String playerName;
  final String petName;
  final String lookId;
  Map<String, dynamic> toJson() => {'playerName': playerName, 'petName': petName, 'lookId': lookId};
}

final class Inventory {
  const Inventory({
    required this.owned,
    required this.worn,
    required this.goalsDone,
    required this.skin,
    required this.rooms,
    required this.furniture,
  });

  static const empty = Inventory(
    owned: {},
    worn: {},
    goalsDone: {},
    skin: null,
    rooms: 1,
    furniture: null,
  );

  factory Inventory.fromJson(Map<String, dynamic> j) => Inventory(
    owned: _strings(j['owned']).toSet(),
    worn: _strings(j['worn']).toSet(),
    goalsDone: _strings(j['goalsDone']).toSet(),
    skin: j['skin'] as String?,
    rooms: j['rooms'] as int,
    furniture: j['furniture'] as String?,
  );

  /// Купленные постоянные want (hero/room), id товаров.
  final Set<String> owned;

  /// Надетые hero-налепки, подмножество [owned].
  final Set<String> worn;
  final Set<String> goalsDone;

  /// 'monkey' или null.
  final String? skin;
  final int rooms;

  /// sofa|shelf|tv|console или null.
  final String? furniture;

  Inventory copyWith({
    Set<String>? owned,
    Set<String>? worn,
    Set<String>? goalsDone,
    String? skin,
    int? rooms,
    String? furniture,
  }) => Inventory(
    owned: owned ?? this.owned,
    worn: worn ?? this.worn,
    goalsDone: goalsDone ?? this.goalsDone,
    skin: skin ?? this.skin,
    rooms: rooms ?? this.rooms,
    furniture: furniture ?? this.furniture,
  );

  Map<String, dynamic> toJson() => {
    'owned': owned.toList(),
    'worn': worn.toList(),
    'goalsDone': goalsDone.toList(),
    'skin': skin,
    'rooms': rooms,
    'furniture': furniture,
  };
}

final class DaySummary {
  const DaySummary({
    required this.day,
    required this.planNeed,
    required this.planWant,
    required this.planSave,
    required this.spentNeed,
    required this.spentWant,
    required this.saved,
    required this.mood,
    required this.stageBefore,
    required this.stageAfter,
    required this.good,
    required this.goodPeriods,
  });

  factory DaySummary.fromJson(Map<String, dynamic> j) => DaySummary(
    day: j['day'] as int,
    planNeed: j['planNeed'] as int,
    planWant: j['planWant'] as int,
    planSave: j['planSave'] as int,
    spentNeed: j['spentNeed'] as int,
    spentWant: j['spentWant'] as int,
    saved: j['saved'] as int,
    mood: PetMood.values.byName(j['mood'] as String),
    stageBefore: j['stageBefore'] as int,
    stageAfter: j['stageAfter'] as int,
    good: j['good'] as bool,
    goodPeriods: j['goodPeriods'] as int,
  );

  final int day;
  final int planNeed;
  final int planWant;
  final int planSave;
  final int spentNeed;
  final int spentWant;
  final int saved;
  final PetMood mood;
  final int stageBefore;
  final int stageAfter;
  final bool good;
  final int goodPeriods;

  bool get grew => stageAfter > stageBefore;

  Map<String, dynamic> toJson() => {
    'day': day,
    'planNeed': planNeed,
    'planWant': planWant,
    'planSave': planSave,
    'spentNeed': spentNeed,
    'spentWant': spentWant,
    'saved': saved,
    'mood': mood.name,
    'stageBefore': stageBefore,
    'stageAfter': stageAfter,
    'good': good,
    'goodPeriods': goodPeriods,
  };
}

final class GameSnapshot {
  const GameSnapshot({
    required this.profile,
    required this.economy,
    required this.inventory,
    required this.goalId,
    required this.goalOption,
    required this.day,
    required this.boughtToday,
    required this.questDoneToday,
    required this.gameRewardToday,
    required this.questsDone,
    required this.gameBest,
    required this.lastSummary,
    required this.soundOn,
  });

  static const version = 1;

  factory GameSnapshot.fromJson(Map<String, dynamic> j) {
    if (j['version'] != version) {
      throw FormatException('unsupported snapshot version ${j['version']}');
    }
    final summary = j['lastSummary'] as Map<String, dynamic>?;
    return GameSnapshot(
      profile: Profile.fromJson(j['profile'] as Map<String, dynamic>),
      economy: EconomyCodec.decode(j['economy'] as Map<String, dynamic>),
      inventory: Inventory.fromJson(j['inventory'] as Map<String, dynamic>),
      goalId: j['goalId'] as String?,
      goalOption: j['goalOption'] as String?,
      day: j['day'] as int,
      boughtToday: _strings(j['boughtToday']),
      questDoneToday: j['questDoneToday'] as bool,
      gameRewardToday: j['gameRewardToday'] as bool,
      questsDone: _strings(j['questsDone']),
      gameBest: (j['gameBest'] as Map<String, dynamic>).cast<String, int>(),
      lastSummary: summary == null ? null : DaySummary.fromJson(summary),
      soundOn: j['soundOn'] as bool,
    );
  }

  final Profile profile;
  final EconomyState economy;
  final Inventory inventory;
  final String? goalId;
  final String? goalOption;
  final int day;

  /// Id товаров, купленных сегодня.
  final List<String> boughtToday;
  final bool questDoneToday;
  final bool gameRewardToday;

  /// Id заданий за всё время.
  final List<String> questsDone;

  /// Лучший результат по мини-играм.
  final Map<String, int> gameBest;
  final DaySummary? lastSummary;
  final bool soundOn;

  GameSnapshot copyWith({
    Profile? profile,
    EconomyState? economy,
    Inventory? inventory,
    String? goalId,
    String? goalOption,
    bool clearGoal = false,
    int? day,
    List<String>? boughtToday,
    bool? questDoneToday,
    bool? gameRewardToday,
    List<String>? questsDone,
    Map<String, int>? gameBest,
    DaySummary? lastSummary,
    bool clearSummary = false,
    bool? soundOn,
  }) => GameSnapshot(
    profile: profile ?? this.profile,
    economy: economy ?? this.economy,
    inventory: inventory ?? this.inventory,
    goalId: clearGoal ? null : (goalId ?? this.goalId),
    goalOption: clearGoal ? null : (goalOption ?? this.goalOption),
    day: day ?? this.day,
    boughtToday: boughtToday ?? this.boughtToday,
    questDoneToday: questDoneToday ?? this.questDoneToday,
    gameRewardToday: gameRewardToday ?? this.gameRewardToday,
    questsDone: questsDone ?? this.questsDone,
    gameBest: gameBest ?? this.gameBest,
    lastSummary: clearSummary ? null : (lastSummary ?? this.lastSummary),
    soundOn: soundOn ?? this.soundOn,
  );

  Map<String, dynamic> toJson() => {
    'version': version,
    'profile': profile.toJson(),
    'economy': EconomyCodec.encode(economy),
    'inventory': inventory.toJson(),
    'goalId': goalId,
    'goalOption': goalOption,
    'day': day,
    'boughtToday': boughtToday,
    'questDoneToday': questDoneToday,
    'gameRewardToday': gameRewardToday,
    'questsDone': questsDone,
    'gameBest': gameBest,
    'lastSummary': lastSummary?.toJson(),
    'soundOn': soundOn,
  };
}
