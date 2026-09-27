// Генератор иконки и заставки из нашего же героя (F-053): своя графика, без чужих картинок.
// Запуск: flutter test tool/icon/make_icon_test.dart — пишет PNG в tool/icon/out/.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:finni/economy/economy_state.dart';
import 'package:finni/ui/mascot/mascot_look.dart';
import 'package:finni/ui/mascot/mascot_painter.dart';
import 'package:finni/ui/mascot/sphere.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _bgTop = Color(0xFF8E8CF5), _bgBottom = Color(0xFF5E5CE6);
const _look = MascotLook(color: Color(0xFFFFCC33), hair: 'tuft', mood: PetMood.glad, stage: 1);

/// [full] — квадрат с фоном (обычная иконка); иначе прозрачный передний слой адаптивной иконки.
Future<void> _render(String name, int px, {required bool background, required double heroScale, double dy = 0}) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  final size = Size(px.toDouble(), px.toDouble());
  if (background) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_bgTop, _bgBottom]).createShader(Offset.zero & size),
    );
    // Монетка-блик за героем.
    canvas.drawCircle(Offset(px * 0.5, px * 0.5), px * 0.38, Paint()..color = const Color(0x22FFFFFF));
  }
  final hero = px * heroScale;
  canvas.save();
  canvas.translate((px - hero) / 2, (px - hero) / 2 + px * dy);
  MascotPainter(look: _look, pose: const SpherePose(0.18, -0.05)).paint(canvas, Size(hero, hero));
  canvas.restore();
  final img = await rec.endRecording().toImage(px, px);
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  final out = File('tool/icon/out/$name.png')..createSync(recursive: true);
  out.writeAsBytesSync(data!.buffer.asUint8List());
}

void main() {
  testWidgets('make launcher icons and splash', (t) async {
    await t.runAsync(() async {
      await _render('icon_1024', 1024, background: true, heroScale: 1.02, dy: -0.1);
      // Адаптивная иконка: передний слой 108 dp, безопасная зона 66 dp — герой ~0.55.
      await _render('foreground_432', 432, background: false, heroScale: 0.74, dy: -0.07);
      await _render('splash_288', 288, background: false, heroScale: 0.86, dy: -0.08);
    });
  });
}
