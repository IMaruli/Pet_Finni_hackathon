import 'package:flutter/material.dart';

import '../../store/snapshot.dart';

const furnitureEmoji = {'sofa': '🛋️', 'shelf': '📚', 'tv': '📺', 'console': '🎮'};

/// Комната героя: стена, окно, пол, стол с нужным, слоты хотелок и цели (SA F-009).
class RoomView extends StatelessWidget {
  const RoomView({
    super.key,
    required this.inventory,
    required this.tableItems,
    required this.room,
    required this.hero,
    required this.poster,
    this.night = false,
  });

  final Inventory inventory;

  /// Эмодзи купленного сегодня нужного.
  final List<String> tableItems;

  /// 1 — спальня, 2 — игровая.
  final int room;
  final Widget hero;

  /// Мини-герой для постера.
  final Widget poster;
  final bool night;

  bool _has(String id) => inventory.owned.contains(id);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.1,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth, h = box.maxHeight;
          final playroom = room == 2;
          return ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RoomPainter(
                      playroom: playroom,
                      rug: !playroom && _has('rug'),
                      night: night,
                    ),
                  ),
                ),
                if (!playroom) ...[
                  if (_has('poster'))
                    Positioned(
                      right: w * 0.07,
                      top: h * 0.08,
                      width: w * 0.2,
                      height: w * 0.24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3D6),
                          border: Border.all(color: const Color(0xFF8A5A3B), width: 4),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: FittedBox(child: poster),
                      ),
                    ),
                  if (inventory.furniture case final f?)
                    Positioned(
                      left: w * 0.03,
                      bottom: h * 0.2,
                      child: Text(furnitureEmoji[f] ?? '🪑', style: TextStyle(fontSize: w * 0.2)),
                    ),
                  // Стол.
                  Positioned(
                    right: w * 0.04,
                    bottom: h * 0.14,
                    width: w * 0.28,
                    height: h * 0.2,
                    child: CustomPaint(painter: _TablePainter()),
                  ),
                  Positioned(
                    right: w * 0.05,
                    bottom: h * 0.33,
                    width: w * 0.27,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        if (_has('lamp'))
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFE27A).withValues(alpha: night ? 0.9 : 0.6),
                                  blurRadius: 28,
                                  spreadRadius: 6,
                                ),
                              ],
                            ),
                            child: Text('🌙', style: TextStyle(fontSize: w * 0.07)),
                          ),
                        for (final e in tableItems) Text(e, style: TextStyle(fontSize: w * 0.065)),
                      ],
                    ),
                  ),
                ] else ...[
                  Positioned(left: w * 0.06, top: h * 0.1, child: Text('🎈', style: TextStyle(fontSize: w * 0.1))),
                  Positioned(left: w * 0.15, top: h * 0.15, child: Text('🎈', style: TextStyle(fontSize: w * 0.08))),
                  Positioned(right: w * 0.06, bottom: h * 0.18, child: Text('🧸', style: TextStyle(fontSize: w * 0.13))),
                  Positioned(left: w * 0.05, bottom: h * 0.16, child: Text('🧩', style: TextStyle(fontSize: w * 0.1))),
                  Positioned(right: w * 0.08, top: h * 0.1, child: Text('🪁', style: TextStyle(fontSize: w * 0.1))),
                ],
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: h * 0.04,
                  child: Center(child: hero),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RoomPainter extends CustomPainter {
  _RoomPainter({required this.playroom, required this.rug, required this.night});
  final bool playroom;
  final bool rug;
  final bool night;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final wallH = h * 0.66;

    // Стена.
    final wall = playroom ? const Color(0xFFD8F3EA) : const Color(0xFFFFE8C7);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, wallH), Paint()..color = wall);
    final pattern = Paint()..color = (playroom ? const Color(0xFFB8E6D6) : const Color(0xFFFBDDB2));
    if (playroom) {
      for (var x = 20.0; x < w; x += 48) {
        for (var y = 20.0; y < wallH; y += 48) {
          canvas.drawCircle(Offset(x + ((y ~/ 48).isOdd ? 24 : 0), y), 5, pattern);
        }
      }
    } else {
      for (var x = 0.0; x < w; x += 36) {
        canvas.drawRect(Rect.fromLTWH(x, 0, 14, wallH), pattern);
      }
    }
    // Плинтус.
    canvas.drawRect(Rect.fromLTWH(0, wallH - 8, w, 10), Paint()..color = const Color(0xFFE5B98A));

    // Окно.
    if (!playroom) {
      final win = Rect.fromLTWH(w * 0.08, h * 0.08, w * 0.3, h * 0.3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(win.inflate(6), const Radius.circular(12)),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(win, const Radius.circular(8)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: night
                ? const [Color(0xFF1E2350), Color(0xFF3A3F8F)]
                : const [Color(0xFF8FD3FF), Color(0xFFD7F0FF)],
          ).createShader(win),
      );
      if (night) {
        canvas.drawCircle(win.topRight + Offset(-win.width * 0.3, win.height * 0.3), win.width * 0.12, Paint()..color = const Color(0xFFFFF3B0));
      } else {
        canvas.drawCircle(win.topRight + Offset(-win.width * 0.28, win.height * 0.3), win.width * 0.12, Paint()..color = const Color(0xFFFFD34D));
        final cloud = Paint()..color = Colors.white;
        final c = win.bottomLeft + Offset(win.width * 0.3, -win.height * 0.28);
        canvas.drawCircle(c, win.width * 0.09, cloud);
        canvas.drawCircle(c + Offset(win.width * 0.1, -win.width * 0.04), win.width * 0.11, cloud);
        canvas.drawCircle(c + Offset(win.width * 0.2, 0), win.width * 0.08, cloud);
      }
      final frame = Paint()
        ..color = Colors.white
        ..strokeWidth = 5;
      canvas.drawLine(win.topCenter, win.bottomCenter, frame);
      canvas.drawLine(win.centerLeft, win.centerRight, frame);
    }

    // Пол.
    final floorRect = Rect.fromLTWH(0, wallH, w, h - wallH);
    canvas.drawRect(floorRect, Paint()..color = playroom ? const Color(0xFFC9A77C) : const Color(0xFFD9A86C));
    final plank = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 2;
    for (var y = wallH + 18; y < h; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(w, y), plank);
    }

    if (playroom) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(w / 2, h * 0.87), width: w * 0.62, height: h * 0.14),
        Paint()..color = const Color(0xFF7CC6FE),
      );
    }
    if (rug) {
      final rect = Rect.fromCenter(center: Offset(w / 2, h * 0.87), width: w * 0.6, height: h * 0.14);
      canvas.drawOval(rect, Paint()..color = const Color(0xFFE8508F));
      canvas.drawOval(rect.deflate(8), Paint()..color = const Color(0xFFFFB3D1));
      canvas.drawOval(rect.deflate(18), Paint()..color = const Color(0xFFE8508F));
    }

    if (night) {
      canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0x55101840));
    }
  }

  @override
  bool shouldRepaint(_RoomPainter old) => old.playroom != playroom || old.rug != rug || old.night != night;
}

class _TablePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wood = Paint()..color = const Color(0xFF9C6B43);
    final dark = Paint()..color = const Color(0xFF7A5031);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height * 0.18), const Radius.circular(6)),
      wood,
    );
    canvas.drawRect(Rect.fromLTWH(size.width * 0.08, size.height * 0.18, size.width * 0.08, size.height * 0.82), dark);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.84, size.height * 0.18, size.width * 0.08, size.height * 0.82), dark);
  }

  @override
  bool shouldRepaint(_TablePainter old) => false;
}
