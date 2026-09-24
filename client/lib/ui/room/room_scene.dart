import 'package:flutter/widgets.dart';

import '../../store/snapshot.dart';
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
  });

  final Inventory inventory;
  final int room;
  final bool night;
  final Widget? hero;

  /// Размер героя как доля ширины.
  final double heroScale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);
        final feet = heroAnchor(size);
        final heroSize = size.width * heroScale;
        return Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                size: size,
                painter: RoomPainter(owned: inventory.owned, furniture: inventory.furniture, room: room, night: night),
              ),
            ),
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
