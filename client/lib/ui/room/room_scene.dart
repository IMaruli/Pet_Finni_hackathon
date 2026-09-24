import 'package:flutter/widgets.dart';

import '../../store/snapshot.dart';
import 'room_ambience.dart';
import 'room_painter.dart';

/// Полноэкранная комната с героем на коврике (SA F-017).
class RoomScene extends StatelessWidget {
  const RoomScene({
    super.key,
    required this.inventory,
    this.room = 1,
    this.night = false,
    this.hero,
    this.heroScale = 0.56,
    this.feetY = 0.84,
    this.animated = true,
  });

  final Inventory inventory;
  final int room;
  final bool night;
  final Widget? hero;

  /// Размер героя как доля ширины.
  final double heroScale;

  /// Где стоит герой по высоте (доля).
  final double feetY;

  /// Пылинки в луче; в статичных превью выключаются.
  final bool animated;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        final feet = heroAnchor(size, feetY: feetY);
        final heroSize = size.width * heroScale;
        return Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                size: size,
                painter: RoomPainter(owned: inventory.owned, furniture: inventory.furniture, room: room, night: night, feetY: feetY),
              ),
            ),
            if (room == 1) RoomAmbience(feetY: feetY, night: night, animated: animated),
            if (hero != null)
              Positioned(
                left: feet.dx - heroSize / 2,
                top: feet.dy - heroSize * 0.92,
                width: heroSize,
                height: heroSize,
                child: hero!,
              ),
          ],
        );
      },
    );
  }
}
