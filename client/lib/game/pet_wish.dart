import 'game_controller.dart';

/// Эмоция героя в моменте (SA F-020 BR-05). Настроение дня (F-006) — отдельная ось.
enum PetEmotion { curious, hungry, thirsty, grubby, excited, calm, sleepy }

enum WishKind { plan, eat, drink, wash, quest, play, save, sleep }

/// Время суток в комнате (SA F-028).
enum DayTime { morning, day, evening, night }

/// План и нужное — утро, урок и игра — день, копилка — вечер, сон — ночь.
extension WishDayTime on WishKind {
  DayTime get dayTime => switch (this) {
    WishKind.plan || WishKind.eat || WishKind.drink || WishKind.wash => DayTime.morning,
    WishKind.quest || WishKind.play => DayTime.day,
    WishKind.save => DayTime.evening,
    WishKind.sleep => DayTime.night,
  };
}

/// Чего герой хочет прямо сейчас: реплика, эмоция и куда вести кнопку.
final class PetWish {
  const PetWish({required this.kind, required this.emotion, required this.text, required this.action});
  final WishKind kind;
  final PetEmotion emotion;
  final String text;
  final String action;

  DayTime get dayTime => kind.dayTime;
}

const _needWish = {'food': WishKind.eat, 'water': WishKind.drink, 'hygiene': WishKind.wash};

const _emotion = {
  WishKind.plan: PetEmotion.curious,
  WishKind.eat: PetEmotion.hungry,
  WishKind.drink: PetEmotion.thirsty,
  WishKind.wash: PetEmotion.grubby,
  WishKind.quest: PetEmotion.excited,
  WishKind.play: PetEmotion.excited,
  WishKind.save: PetEmotion.calm,
  WishKind.sleep: PetEmotion.sleepy,
};

/// Одно желание дня по порядку BR-01: план → нужное → квест → игра → копилка → сон.
PetWish wishFor(GameController g) {
  final kind = () {
    if (!g.planConfirmed) return WishKind.plan;
    // День знакомства: сначала урок и игра, нужды просыпаются потом (F-042, F-043).
    if (g.isIntroDay && !g.lessonPaidToday) return WishKind.quest;
    if (g.isIntroDay && !g.gameRewardToday) return WishKind.play;
    for (final item in g.todaysNeeds) {
      if (!g.isBoughtToday(item.id)) return _needWish[item.need] ?? WishKind.eat;
    }
    if (!g.lessonPaidToday) return WishKind.quest; // урок дня (F-025)
    if (g.economy.savedThisPeriod.value == 0) return WishKind.save;
    return WishKind.sleep;
  }();
  // Первый день: подписываем, откуда монеты (ТЗ: доход).
  final first = kind == WishKind.plan && g.day == 1;
  final config = g.content.config;
  return PetWish(
    kind: kind,
    emotion: _emotion[kind]!,
    text: first
        ? g.content.text('wish.plan.first', {'start': '${config.startCoins}', 'pocket': '${config.pocketMoney}'})
        : _needAsk(g, kind) ?? g.content.text('wish.${kind.name}', {'pet': g.profile.petName}),
    action: g.content.text('wish.${kind.name}.action'),
  );
}

/// Своя реплика для каждой вещи нужного (F-032): «Хочу супчика с хлебом!».
String? _needAsk(GameController g, WishKind kind) {
  if (kind != WishKind.eat && kind != WishKind.drink && kind != WishKind.wash) return null;
  // Мягкий переход дня знакомства: «после урока я проголодался…» (F-043).
  if (g.isIntroDay && kind == WishKind.eat) return g.content.text('wish.eat.intro');
  return g.todaysNeeds.where((i) => !g.isBoughtToday(i.id)).firstOrNull?.ask;
}
