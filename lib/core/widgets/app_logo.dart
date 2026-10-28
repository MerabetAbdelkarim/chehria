import 'package:flutter/material.dart';

/// The Chehria logo (wallet with a gold clasp), drawn as vectors so it stays
/// sharp at any size. Same geometry as `assets/brand/icon.svg` (100×100).
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Chehria',
      child: SizedBox.square(
        dimension: size,
        child: const CustomPaint(painter: _AppLogoPainter()),
      ),
    );
  }
}

class _AppLogoPainter extends CustomPainter {
  const _AppLogoPainter();

  static const _green = Color(0xFF00873D);
  static const _greenDeep = Color(0xFF0B5D33);
  static const _gold = Color(0xFFE8B23A);
  static const _white = Color(0xFFFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);

    // Tile.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 100, 100),
        const Radius.circular(23),
      ),
      Paint()..color = _green,
    );

    // Note sticking out of the wallet.
    final flap = Path()
      ..moveTo(24, 34)
      ..lineTo(64, 22)
      ..arcToPoint(const Offset(70, 26), radius: const Radius.circular(5))
      ..lineTo(72, 34)
      ..close();
    canvas.drawPath(flap, Paint()..color = _white.withValues(alpha: .55));

    // Wallet body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 32, 60, 44),
        const Radius.circular(9),
      ),
      Paint()..color = _white,
    );

    // Clasp and its gold button.
    final clasp = Path()
      ..moveTo(58, 46)
      ..lineTo(80, 46)
      ..lineTo(80, 62)
      ..lineTo(58, 62)
      ..arcToPoint(const Offset(58, 46), radius: const Radius.circular(8))
      ..close();
    canvas.drawPath(clasp, Paint()..color = _greenDeep);
    canvas.drawCircle(const Offset(60, 54), 4, Paint()..color = _gold);
  }

  @override
  bool shouldRepaint(_AppLogoPainter oldDelegate) => false;
}
