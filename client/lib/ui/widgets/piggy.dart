import 'package:flutter/material.dart';

/// Копилка-свинка с прорезью для монет (F-033) — вместо эмодзи.
class PiggyBankPainter extends CustomPainter {
  const PiggyBankPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    const pink = Color(0xFFFF9EB5), dark = Color(0xFFE07A95);
    final body = Rect.fromLTWH(w * 0.1, h * 0.22, w * 0.8, h * 0.62);
    // ножки
    for (final x in [0.26, 0.42, 0.58, 0.74]) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * x - w * 0.05, h * 0.72, w * 0.1, h * 0.22), Radius.circular(w * 0.04)), Paint()..color = dark);
    }
    // хвостик
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.1, h * 0.5)
        ..cubicTo(w * -0.02, h * 0.42, w * 0.02, h * 0.3, w * 0.08, h * 0.36),
      Paint()
        ..color = dark
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.035
        ..strokeCap = StrokeCap.round,
    );
    // туловище
    canvas.drawOval(
      body,
      Paint()..shader = const RadialGradient(center: Alignment(-0.3, -0.5), colors: [Color(0xFFFFD1DC), pink, dark]).createShader(body),
    );
    // ушко
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.62, h * 0.3)
        ..lineTo(w * 0.7, h * 0.08)
        ..lineTo(w * 0.78, h * 0.34)
        ..close(),
      Paint()..color = dark,
    );
    // пятачок
    final snout = Rect.fromCenter(center: Offset(w * 0.9, h * 0.54), width: w * 0.18, height: h * 0.26);
    canvas.drawOval(snout, Paint()..color = dark);
    for (final dy in [-0.05, 0.05]) {
      canvas.drawCircle(Offset(w * 0.91, h * (0.54 + dy)), w * 0.02, Paint()..color = const Color(0xFF9E4A62));
    }
    // глазик
    canvas.drawCircle(Offset(w * 0.74, h * 0.42), w * 0.03, Paint()..color = const Color(0xFF3B2A30));
    // прорезь для монет
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.48, h * 0.27), width: w * 0.28, height: h * 0.06), Radius.circular(h * 0.03)),
      Paint()..color = const Color(0xFF7A3A50),
    );
    // монетка-значок
    canvas.drawCircle(Offset(w * 0.42, h * 0.56), w * 0.09, Paint()..color = const Color(0xFFFFC928));
    canvas.drawCircle(
      Offset(w * 0.42, h * 0.56),
      w * 0.09,
      Paint()
        ..color = const Color(0xFFE0A800)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.015,
    );
  }

  @override
  bool shouldRepaint(PiggyBankPainter old) => false;
}
