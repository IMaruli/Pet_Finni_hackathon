import 'game_controller.dart';

/// Эмоция героя в моменте (SA F-020 BR-05). Настроение дня (F-006) — отдельная ось.
enum PetEmotion { curious, hungry, thirsty, grubby, excited, calm, sleepy }

enum WishKind { plan, eat, drink, wash, quest, play, save, sleep }

/// Чего герой хочет прямо сейчас: реплика, эмоция и куда вести кнопку.
final class PetWish {
  const PetWish({required this.kind, required this.emotion, required this.text, required this.action});
  final WishKind kind;
  final PetEmotion emotion;
  final String text;
  final String action;
}

const _needWish = {'breakfast': WishKind.eat, 'water': WishKind.drink, 'care': WishKind.wash};

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
    for (final item in g.todaysNeeds) {
      if (!g.isBoughtToday(item.id)) return _needWish[item.id] ?? WishKind.eat;
    }
    if (!g.questDoneToday) return WishKind.quest;
    if (!g.gameRewardToday) return WishKind.play;
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
        : g.content.text('wish.${kind.name}', {'pet': g.profile.petName}),
    action: g.content.text('wish.${kind.name}.action'),
  );
}
