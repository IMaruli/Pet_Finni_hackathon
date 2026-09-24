/// «Меньше движения» (ТЗ 3.6, F-058): настройка во взрослом разделе или системная «Удалить анимацию».
/// Выставляется оболочкой приложения; виджеты читают [Motion.reduced].
abstract final class Motion {
  /// Настройка профиля «Меньше движения».
  static bool setting = false;

  /// Системная настройка Android (`MediaQuery.disableAnimations`).
  static bool system = false;

  static bool get reduced => setting || system;
}
