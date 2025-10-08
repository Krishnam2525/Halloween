import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const SpookyBook());

class SpookyBook extends StatelessWidget {
  const SpookyBook({super.key});
  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(useMaterial3: true);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spooky Storybook',
      theme: base.copyWith(
        colorScheme: base.colorScheme.copyWith(
          primary: const Color(0xFFFF7A3C),
          secondary: const Color(0xFF8EE1FF),
          surface: const Color(0xFF12121C),
          // keep background for broader SDKs even if lint warns
          background: const Color(0xFF0B0B12),
        ),
        scaffoldBackgroundColor: const Color(0xFF0B0B12),
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        }),
      ),
      home: const TitlePage(),
    );
  }
}

/* ---------- UTIL + FRAME ---------- */

void pushFancy(BuildContext context, Widget page) {
  Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 650),
    reverseTransitionDuration: const Duration(milliseconds: 520),
    pageBuilder: (_, a, __) {
      final c = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: c,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(.06, .04), end: Offset.zero).animate(c),
          child: page,
        ),
      );
    },
  ));
}

double? lerpDouble(num a, num b, double t) => a + (b - a) * t;

/* Big Halloween-orange button with glow */
class PumpkinButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isNext;
  const PumpkinButton(
      {super.key, required this.label, required this.icon, required this.onTap, this.isNext = true});

  @override
  State<PumpkinButton> createState() => _PumpkinButtonState();
}

class _PumpkinButtonState extends State<PumpkinButton> with SingleTickerProviderStateMixin {
  bool _hover = false, _down = false;
  late final AnimationController pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const orange1 = Color(0xFFFFA53E);
    const orange2 = Color(0xFFFF6B3D);
    final glow = Tween<double>(begin: .35, end: .8).animate(pulse);
    final scale = _down ? 0.96 : (_hover ? 1.04 : 1.0);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() {
        _hover = false;
        _down = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTapUp: (_) => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          scale: scale,
          child: AnimatedBuilder(
            animation: glow,
            builder: (_, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [orange1, orange2]),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: orange1.withOpacity(glow.value),
                    blurRadius: 24,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!widget.isNext) Icon(widget.icon, color: Colors.black, size: 20),
                  if (!widget.isNext) const SizedBox(width: 8),
                  Text(widget.label,
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: .6)),
                  const SizedBox(width: 8),
                  if (widget.isNext) Icon(widget.icon, color: Colors.black, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* Page shell with persistent Prev/Next buttons (bottom corners) */
class PageFrame extends StatelessWidget {
  final String title;
  final List<Color> bg;
  final Widget body;
  final Widget? sky;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final int? step;
  final int? total;

  const PageFrame({
    super.key,
    required this.title,
    required this.bg,
    required this.body,
    this.sky,
    this.onPrev,
    this.onNext,
    this.step,
    this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: bg, begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              if (sky != null) Positioned.fill(child: sky!),
              Positioned(
                top: 10,
                left: 14,
                right: 14,
                child: Row(
                  children: [
                    if (Navigator.of(context).canPop())
                      PumpkinButton(
                          label: 'Back',
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.pop(context),
                          isNext: false)
                    else
                      const SizedBox(width: 96),
                    const Spacer(),
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const Spacer(),
                    if (step != null && total != null)
                      Text('$step / $total',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 90, 18, 100),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: body,
                  ),
                ),
              ),
              if (onPrev != null)
                Positioned(
                  bottom: 18,
                  left: 18,
                  child: PumpkinButton(
                      label: 'Previous',
                      icon: Icons.arrow_back_rounded,
                      onTap: onPrev!,
                      isNext: false),
                ),
              if (onNext != null)
                Positioned(
                  bottom: 18,
                  right: 18,
                  child: PumpkinButton(
                      label: 'Next',
                      icon: Icons.arrow_forward_rounded,
                      onTap: onNext!),
                ),
              Positioned.fill(child: const IgnorePointer(child: AnimatedEmbers())),
            ],
          ),
        ),
      ),
    );
  }
}

/* Subtle floating embers */
class AnimatedEmbers extends StatefulWidget {
  const AnimatedEmbers({super.key});
  @override
  State<AnimatedEmbers> createState() => _AnimatedEmbersState();
}

class _AnimatedEmbersState extends State<AnimatedEmbers>
    with SingleTickerProviderStateMixin {
  late final AnimationController ctrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();
  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => CustomPaint(painter: _EmberPainter(ctrl.value)),
    );
  }
}

class _EmberPainter extends CustomPainter {
  final double t;
  _EmberPainter(this.t);
  @override
  void paint(Canvas c, Size size) {
    final rnd = Random(42);
    for (int i = 0; i < 60; i++) {
      final p = (t + i / 60) % 1;
      final x = size.width * (i % 2 == 0 ? p : 1 - p);
      final y = size.height * (.95 - .9 * p) + sin(i + p * 6) * 6;
      final paint = Paint()
        ..color =
            Color.lerp(const Color(0xFFFFA53E), Colors.white, p)!.withOpacity(.5 * (1 - p));
      c.drawCircle(Offset(x, y), rnd.nextBool() ? 1.5 : 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EmberPainter oldDelegate) => oldDelegate.t != t;
}

/* ---------- TITLE ---------- */

class TitlePage extends StatefulWidget {
  const TitlePage({super.key});
  @override
  State<TitlePage> createState() => _TitlePageState();
}

class _TitlePageState extends State<TitlePage> with TickerProviderStateMixin {
  late final AnimationController floatCtrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat(reverse: true);
  late final AnimationController batsCtrl =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat();
  @override
  void dispose() {
    floatCtrl.dispose();
    batsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Spooky Storybook',
      bg: const [Color(0xFF0B0B12), Color(0xFF1A1030)],
      step: 0,
      total: 6,
      sky: CustomPaint(
          painter: StarsAndMoonPainter(batT: batsCtrl.value, controller: batsCtrl)),
      body: AnimatedBuilder(
        animation: floatCtrl,
        builder: (_, __) => Transform.translate(
          offset: Offset(0, lerpDouble(-10, 10, floatCtrl.value)!),
          child: Column(
            children: [
              Hero(
                tag: 'book-title',
                child: Text(
                  'Animated Halloween Storybook',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        foreground: Paint()
                          ..shader = const LinearGradient(
                            colors: [Color(0xFFFFA53E), Color(0xFFFF6B6B)],
                          ).createShader(const Rect.fromLTWH(0, 0, 800, 100)),
                        shadows: const [
                          Shadow(
                              color: Colors.black54,
                              blurRadius: 16,
                              offset: Offset(0, 4))
                        ],
                      ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Tap Next to begin your six-chapter tour of the night…',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.white70)),
            ],
          ),
        ),
      ),
      onNext: () => pushFancy(context, const Chapter1()),
    );
  }
}

/* ---------- CHAPTER 1 ---------- */
class Chapter1 extends StatefulWidget {
  const Chapter1({super.key});
  @override
  State<Chapter1> createState() => _Chapter1State();
}

class _Chapter1State extends State<Chapter1> with TickerProviderStateMixin {
  late final AnimationController pulse =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat(reverse: true);
  late final AnimationController fog =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))
        ..repeat();
  @override
  void dispose() {
    pulse.dispose();
    fog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Chapter I — The Rising Dead',
      bg: const [Color(0xFF090A12), Color(0xFF181B2F)],
      step: 1,
      total: 6,
      sky: CustomPaint(painter: FogPainter(t: fog.value, controller: fog)),
      body: Column(
        children: [
          Hero(
              tag: 'book-title',
              child: Text('The Rising Dead',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: const Color(0xFFFFA53E)))),
          const SizedBox(height: 8),
          Text('Zombies emerge from crooked graves as the earth shivers…',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white70)),
          const SizedBox(height: 24),
          SizedBox(
              height: 220,
              child: AnimatedBuilder(
                  animation: pulse,
                  builder: (_, __) =>
                      CustomPaint(painter: ZombiePainter(glow: pulse.value)))),
        ],
      ),
      onPrev: () => Navigator.pop(context),
      onNext: () => pushFancy(context, const Chapter2()),
    );
  }
}

/* ---------- CHAPTER 2 ---------- */
class Chapter2 extends StatefulWidget {
  const Chapter2({super.key});
  @override
  State<Chapter2> createState() => _Chapter2State();
}

class _Chapter2State extends State<Chapter2> with TickerProviderStateMixin {
  late final AnimationController dance =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..repeat(reverse: true);
  @override
  void dispose() {
    dance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Chapter II — Bones of the Damned',
      bg: const [Color(0xFF0C0D16), Color(0xFF1B2238)],
      step: 2,
      total: 6,
      body: Column(
        children: [
          Text('Bones of the Damned',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: const Color(0xFF8EE1FF))),
          const SizedBox(height: 8),
          Text('A rattling rhythm echoes through the catacombs.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white70)),
          const SizedBox(height: 24),
          SizedBox(
              height: 240,
              child: AnimatedBuilder(
                  animation: dance,
                  builder: (_, __) =>
                      CustomPaint(painter: SkeletonPainter(t: dance.value)))),
        ],
      ),
      onPrev: () => Navigator.pop(context),
      onNext: () => pushFancy(context, const Chapter3()),
    );
  }
}

/* ---------- CHAPTER 3 ---------- */
class Chapter3 extends StatefulWidget {
  const Chapter3({super.key});
  @override
  State<Chapter3> createState() => _Chapter3State();
}

class _Chapter3State extends State<Chapter3> with TickerProviderStateMixin {
  late final AnimationController wand =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat();
  @override
  void dispose() {
    wand.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Chapter III — The Wicked Spell',
      bg: const [Color(0xFF120C18), Color(0xFF2D1538)],
      step: 3,
      total: 6,
      body: Column(
        children: [
          Text('The Wicked Spell',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: const Color(0xFFFFA6FF))),
          const SizedBox(height: 8),
          Text('The witch whispers, and the air fills with glittering runes.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white70)),
          const SizedBox(height: 24),
          SizedBox(
              height: 260,
              child: AnimatedBuilder(
                  animation: wand,
                  builder: (_, __) =>
                      CustomPaint(painter: WitchPainter(t: wand.value)))),
        ],
      ),
      onPrev: () => Navigator.pop(context),
      onNext: () => pushFancy(context, const Chapter4()),
    );
  }
}

/* ---------- CHAPTER 4 ---------- */
class Chapter4 extends StatefulWidget {
  const Chapter4({super.key});
  @override
  State<Chapter4> createState() => _Chapter4State();
}

class _Chapter4State extends State<Chapter4> with TickerProviderStateMixin {
  late final AnimationController glow =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..repeat(reverse: true);
  @override
  void dispose() {
    glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Chapter IV — Pumpkin Patch Terror',
      bg: const [Color(0xFF130E0C), Color(0xFF301A12)],
      step: 4,
      total: 6,
      body: Column(
        children: [
          Text('Pumpkin Patch Terror',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: const Color(0xFFFFA53E))),
          const SizedBox(height: 8),
          Text('Jack-o’-lanterns awaken with an inner blaze.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white70)),
          const SizedBox(height: 24),
          SizedBox(
              height: 220,
              child: AnimatedBuilder(
                  animation: glow,
                  builder: (_, __) =>
                      CustomPaint(painter: PumpkinPainter(glow: glow.value)))),
        ],
      ),
      onPrev: () => Navigator.pop(context),
      onNext: () => pushFancy(context, const Chapter5()),
    );
  }
}

/* ---------- CHAPTER 5 ---------- */
class Chapter5 extends StatefulWidget {
  const Chapter5({super.key});
  @override
  State<Chapter5> createState() => _Chapter5State();
}

class _Chapter5State extends State<Chapter5> with TickerProviderStateMixin {
  late final AnimationController eyes =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat(reverse: true);
  late final AnimationController bat =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat();
  late final AnimationController ghost =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
        ..repeat();
  @override
  void dispose() {
    eyes.dispose();
    bat.dispose();
    ghost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: "Chapter V — The Vampire's Lair",
      bg: const [Color(0xFF100C12), Color(0xFF2B0E1C)],
      step: 5,
      total: 6,
      body: Column(
        children: [
          Text("The Vampire's Lair",
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: const Color(0xFFFF5A72))),
          const SizedBox(height: 8),
          Text('Count Dracula waits with burning eyes; his minions stir.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white70)),
          const SizedBox(height: 24),
          SizedBox(
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                    animation: bat,
                    builder: (_, __) =>
                        CustomPaint(painter: BatPainter(t: bat.value))),
                AnimatedBuilder(
                    animation: ghost,
                    builder: (_, __) =>
                        CustomPaint(painter: GhostPainter(t: ghost.value))),
                AnimatedBuilder(
                    animation: eyes,
                    builder: (_, __) =>
                        CustomPaint(painter: VampirePainter(glow: eyes.value))),
              ],
            ),
          ),
        ],
      ),
      onPrev: () => Navigator.pop(context),
      onNext: () => pushFancy(context, const Chapter6()),
    );
  }
}

/* ---------- CHAPTER 6 ---------- */
class Chapter6 extends StatefulWidget {
  const Chapter6({super.key});
  @override
  State<Chapter6> createState() => _Chapter6State();
}

class _Chapter6State extends State<Chapter6> with TickerProviderStateMixin {
  late final AnimationController a =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..repeat(reverse: true);
  late final AnimationController b =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat();
  late final AnimationController c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
        ..repeat();
  late final AnimationController d =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
        ..repeat();
  @override
  void dispose() {
    a.dispose();
    b.dispose();
    c.dispose();
    d.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Chapter VI — The Halloween Ball',
      bg: const [Color(0xFF140C1C), Color(0xFF2E1034)],
      step: 6,
      total: 6,
      sky: CustomPaint(painter: SparkPainter(t: d.value, controller: d)),
      body: Column(
        children: [
          Text('The Halloween Ball',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: const Color(0xFFFFA53E))),
          const SizedBox(height: 8),
          Text('All spirits dance beneath the moonlight.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.white70)),
          const SizedBox(height: 24),
          SizedBox(
            height: 320,
            child: AnimatedBuilder(
              animation: Listenable.merge([a, b, c, d]),
              builder: (_, __) => Stack(fit: StackFit.expand, children: const [
                _FogLayer(),
                _BatLayer(),
                _GhostLayer(),
                _PumpkinLayer(),
                _ZombieLayer(),
                _SkeletonLayer(),
                _WitchLayer(),
                _VampireLayer(),
              ]),
            ),
          ),
        ],
      ),
      onPrev: () => Navigator.pop(context),
      onNext: () => Navigator.of(context)
          .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const TitlePage()), (r) => false),
    );
  }
}

/* Layers for finale (to keep AnimatedBuilder const-friendly) */
class _FogLayer extends StatelessWidget {
  const _FogLayer();
  @override
  Widget build(BuildContext context) => _AnimatedLayer(
      duration: 1600, builder: (t) => CustomPaint(painter: FogPainter(t: t)));
}

class _BatLayer extends StatelessWidget {
  const _BatLayer();
  @override
  Widget build(BuildContext context) =>
      _AnimatedLayer(duration: 1400, builder: (t) => CustomPaint(painter: BatPainter(t: t)));
}

class _GhostLayer extends StatelessWidget {
  const _GhostLayer();
  @override
  Widget build(BuildContext context) =>
      _AnimatedLayer(duration: 1600, builder: (t) => CustomPaint(painter: GhostPainter(t: t)));
}

class _PumpkinLayer extends StatelessWidget {
  const _PumpkinLayer();
  @override
  Widget build(BuildContext context) => _AnimatedLayer(
      duration: 1200, reverse: true, builder: (t) => CustomPaint(painter: PumpkinPainter(glow: t)));
}

class _ZombieLayer extends StatelessWidget {
  const _ZombieLayer();
  @override
  Widget build(BuildContext context) => _AnimatedLayer(
      duration: 1200, reverse: true, builder: (t) => CustomPaint(painter: ZombiePainter(glow: t)));
}

class _SkeletonLayer extends StatelessWidget {
  const _SkeletonLayer();
  @override
  Widget build(BuildContext context) => _AnimatedLayer(
      duration: 1400, reverse: true, builder: (t) => CustomPaint(painter: SkeletonPainter(t: t)));
}

class _WitchLayer extends StatelessWidget {
  const _WitchLayer();
  @override
  Widget build(BuildContext context) =>
      _AnimatedLayer(duration: 1800, builder: (t) => CustomPaint(painter: WitchPainter(t: t)));
}

class _VampireLayer extends StatelessWidget {
  const _VampireLayer();
  @override
  Widget build(BuildContext context) => _AnimatedLayer(
      duration: 1200, reverse: true, builder: (t) => CustomPaint(painter: VampirePainter(glow: t)));
}

/* Generic looping animation host */
class _AnimatedLayer extends StatefulWidget {
  final int duration;
  final bool reverse;
  final Widget Function(double t) builder;
  const _AnimatedLayer({required this.duration, this.reverse = false, required this.builder});
  @override
  State<_AnimatedLayer> createState() => _AnimatedLayerState();
}

class _AnimatedLayerState extends State<_AnimatedLayer> with SingleTickerProviderStateMixin {
  late final AnimationController c =
      AnimationController(vsync: this, duration: Duration(milliseconds: widget.duration))
        ..repeat(reverse: widget.reverse);
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (_, __) => widget.builder(c.value),
      );
}

/* ---------- EFFECT & CHARACTER PAINTERS ---------- */

class StarsAndMoonPainter extends CustomPainter {
  final double batT;
  final AnimationController controller;
  StarsAndMoonPainter({required this.batT, required this.controller}) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final stars = Paint()..color = Colors.white.withOpacity(.65);
    for (int i = 0; i < 120; i++) {
      final dx = (i * 37 % size.width) + sin(i * 16.0) * 2;
      final dy = (i * 59 % size.height) + cos(i * 9.0) * 2;
      canvas.drawCircle(Offset(dx, dy), i % 4 == 0 ? 1.8 : 1.1, stars);
    }
    final moon = Paint()..color = const Color(0xFFE8F3FF).withOpacity(.9);
    canvas.drawCircle(Offset(size.width * .82, size.height * .18), 42, moon);
    for (int i = 0; i < 8; i++) {
      final t = (batT + i / 8) % 1;
      final x = size.width * (1 - t);
      final y = size.height * (.25 + .55 * (i / 8)) + sin((t + i) * pi * 2) * 10;
      BatPainter.drawBat(canvas, Offset(x, y), .65 + (i % 3) * .2, opacity: .9);
    }
  }

  @override
  bool shouldRepaint(covariant StarsAndMoonPainter oldDelegate) => true;
}

class FogPainter extends CustomPainter {
  final double t;
  final AnimationController? controller;
  FogPainter({required this.t, this.controller}) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final g = LinearGradient(
      colors: [Colors.white.withOpacity(.07), Colors.white.withOpacity(0)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Offset.zero & size);
    final paint = Paint()..shader = g;
    for (int i = 0; i < 3; i++) {
      final y = size.height * (.25 + .25 * i) + sin(t * 2 * pi + i) * 12;
      final r = Rect.fromLTWH(-60 + i * 40, y, size.width + 120, 90);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(46)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant FogPainter oldDelegate) => true;
}

class SparkPainter extends CustomPainter {
  final double t;
  final AnimationController controller;
  SparkPainter({required this.t, required this.controller}) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(13);
    for (int i = 0; i < 120; i++) {
      final p = (t + i / 120) % 1;
      final a = p * 2 * pi + i * .35;
      final r = size.shortestSide * (.12 + .45 * p);
      final cx = size.width / 2 + cos(a) * r;
      final cy = size.height / 2 + sin(a) * r;
      final paint = Paint()
        ..color = Color.lerp(const Color(0xFFFFA53E), Colors.white, p)!.withOpacity(1 - p);
      canvas.drawCircle(Offset(cx, cy), rnd.nextBool() ? 2 : 1, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SparkPainter oldDelegate) => true;
}

/* Characters */
class ZombiePainter extends CustomPainter {
  final double glow;
  ZombiePainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Paint()..color = const Color(0xFF3E6E4E);
    final headR = Rect.fromCenter(center: Offset(w * .3, h * .35), width: 80, height: 60);
    canvas.drawRRect(RRect.fromRectAndRadius(headR, const Radius.circular(14)), body);

    final eye = Paint()..color = Color.lerp(const Color(0xFF440000), const Color(0xFFFF4444), glow)!;
    canvas.drawCircle(Offset(w * .28, h * .35), 6 + 2 * glow, eye);
    canvas.drawCircle(Offset(w * .32, h * .35), 6 + 2 * glow, eye);

    final shirt = Paint()..color = const Color(0xFF2B3C3A);
    final torso =
        RRect.fromRectAndRadius(Rect.fromLTWH(w * .22, h * .42, 120, 80), const Radius.circular(10));
    canvas.drawRRect(torso, shirt);

    final shred = Path()
      ..moveTo(w * .22, h * .52)
      ..lineTo(w * .22, h * .62)
      ..lineTo(w * .26, h * .56)
      ..lineTo(w * .30, h * .62)
      ..lineTo(w * .34, h * .56)
      ..lineTo(w * .34, h * .42);
    canvas.drawPath(shred, Paint()..color = const Color(0xFF0B0B12));

    final arm = Paint()..color = const Color(0xFF3E6E4E);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * .15, h * .46, 60, 16), const Radius.circular(8)),
        arm);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * .34, h * .46, 60, 16), const Radius.circular(8)),
        arm);

    final leg = Paint()..color = const Color(0xFF1E3328);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * .25, h * .62, 32, 60), const Radius.circular(8)),
        leg);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * .31, h * .62, 32, 60), const Radius.circular(8)),
        leg);
  }

  @override
  bool shouldRepaint(covariant ZombiePainter oldDelegate) => oldDelegate.glow != glow;
}

class SkeletonPainter extends CustomPainter {
  final double t;
  SkeletonPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, cx = w * .7, cy = h * .5, k = sin(t * pi) * 10;
    final bone = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(k * pi / 180);

    canvas.drawCircle(const Offset(0, -60), 22, bone);
    final eye = Paint()..color = Colors.greenAccent.withOpacity(.9);
    canvas.drawCircle(const Offset(-7, -62), 3 + 1.5 * (0.5 + 0.5 * sin(t * 2 * pi)), eye);
    canvas.drawCircle(const Offset(7, -62), 3 + 1.5 * (0.5 + 0.5 * sin(t * 2 * pi)), eye);

    canvas.drawLine(const Offset(0, -38), const Offset(0, 18), bone);
    canvas.drawLine(const Offset(0, -20), const Offset(-26, 0), bone);
    canvas.drawLine(const Offset(0, -20), const Offset(26, 0), bone);

    canvas.drawLine(const Offset(0, 18), const Offset(-18, 54), bone);
    canvas.drawLine(const Offset(0, 18), const Offset(18, 54), bone);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SkeletonPainter oldDelegate) => oldDelegate.t != t;
}

class WitchPainter extends CustomPainter {
  final double t;
  WitchPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final base = Paint()..color = const Color(0xFF3B2B5B);
    final hat = Path()
      ..moveTo(w * .25, h * .35)
      ..lineTo(w * .45, h * .20)
      ..lineTo(w * .55, h * .35)
      ..close();
    canvas.drawPath(hat, base);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(w * .32, h * .35, 80, 46), const Radius.circular(12)),
        Paint()..color = const Color(0xFF6C4EB1));

    final wandPos = Offset(w * .62, h * .40 + sin(t * 2 * pi) * 6);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * .58, h * .40, 60, 6), const Radius.circular(3)),
        Paint()..color = Colors.brown.shade300);
    canvas.drawCircle(wandPos, 8, Paint()..color = Colors.yellowAccent);

    final rnd = Random(7);
    for (int i = 0; i < 30; i++) {
      final p = (t + i / 30) % 1;
      final dx = wandPos.dx - 120 * p + rnd.nextDouble() * 8 * (1 - p);
      final dy = wandPos.dy + sin((p + i) * 10) * 8;
      canvas.drawCircle(
          Offset(dx, dy), 2, Paint()..color = Colors.purpleAccent.withOpacity(1 - p));
    }
  }

  @override
  bool shouldRepaint(covariant WitchPainter oldDelegate) => oldDelegate.t != t;
}

class PumpkinPainter extends CustomPainter {
  final double glow;
  PumpkinPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, c = Offset(w * .5, h * .6);
    final body = Paint()..color = const Color(0xFFFF7A3C);
    canvas.drawOval(Rect.fromCenter(center: c, width: 180, height: 120), body);
    canvas.drawOval(Rect.fromCenter(center: c.translate(-50, 0), width: 80, height: 100),
        Paint()..color = const Color(0xFFFF8E55));
    canvas.drawOval(Rect.fromCenter(center: c.translate(50, 0), width: 80, height: 100),
        Paint()..color = const Color(0xFFFF8E55));
    canvas.drawRect(Rect.fromLTWH(c.dx - 8, c.dy - 80, 16, 20),
        Paint()..color = const Color(0xFF3F7A33));

    final eyes = Paint()
      ..color = Color.lerp(const Color(0xFFFFD08A), Colors.white, glow)!
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(_tri(c.translate(-35, -10), 20), eyes);
    canvas.drawPath(_tri(c.translate(35, -10), 20), eyes);
    canvas.drawPath(_mouth(c.translate(0, 20), 60, 18), eyes);
  }

  Path _tri(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy - r)
    ..lineTo(c.dx - r, c.dy + r * .6)
    ..lineTo(c.dx + r, c.dy + r * .6)
    ..close();

  Path _mouth(Offset c, double w, double h) => Path()
    ..moveTo(c.dx - w / 2, c.dy)
    ..lineTo(c.dx - w / 4, c.dy + h)
    ..lineTo(c.dx, c.dy)
    ..lineTo(c.dx + w / 4, c.dy + h)
    ..lineTo(c.dx + w / 2, c.dy);

  @override
  bool shouldRepaint(covariant PumpkinPainter oldDelegate) => oldDelegate.glow != glow;
}

class VampirePainter extends CustomPainter {
  final double glow;
  VampirePainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, center = Offset(w * .5, h * .50);
    final cape = Path()
      ..moveTo(center.dx, center.dy)
      ..quadraticBezierTo(center.dx - 140, center.dy + 60, center.dx - 40, center.dy + 120)
      ..quadraticBezierTo(center.dx, center.dy + 140, center.dx + 40, center.dy + 120)
      ..quadraticBezierTo(center.dx + 140, center.dy + 60, center.dx, center.dy)
      ..close();
    canvas.drawPath(cape, Paint()..color = const Color(0xFF540016).withOpacity(.85));
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(center: center.translate(0, -18), width: 60, height: 80),
            const Radius.circular(12)),
        Paint()..color = const Color(0xFFEDEDED));

    final eye = Paint()..color = Color.lerp(const Color(0xFF4A0000), const Color(0xFFFF3B3B), glow)!;
    canvas.drawCircle(center.translate(-12, -24), 5 + 2 * glow, eye);
    canvas.drawCircle(center.translate(12, -24), 5 + 2 * glow, eye);
    canvas.drawCircle(center.translate(0, 18), 3, Paint()..color = Colors.black);
    canvas.drawLine(center.translate(-8, 10), center.translate(-6, 16),
        Paint()..color = Colors.black..strokeWidth = 2);
    canvas.drawLine(center.translate(8, 10), center.translate(6, 16),
        Paint()..color = Colors.black..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant VampirePainter oldDelegate) => oldDelegate.glow != glow;
}

class GhostPainter extends CustomPainter {
  final double t;
  GhostPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, cx = w * .25, cy = h * .45 + sin(t * 2 * pi) * 8;

    final path = Path()
      ..moveTo(cx, cy - 50)
      ..quadraticBezierTo(cx - 60, cy - 70, cx - 60, cy)
      ..quadraticBezierTo(cx - 60, cy + 40, cx + 60, cy + 40)
      ..quadraticBezierTo(cx + 60, cy - 10, cx + 60, cy)
      ..quadraticBezierTo(cx + 60, cy - 70, cx, cy - 50)
      ..close();

    final body = Paint()..color = Colors.white.withOpacity(.92);
    canvas.drawShadow(path.shift(const Offset(0, 6)), Colors.black, 8, true);
    canvas.drawPath(path, body);

    final eyes = Paint()..color = Colors.black.withOpacity(.9);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 15, cy - 12), width: 10, height: 14), eyes);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 15, cy - 12), width: 10, height: 14), eyes);
  }

  @override
  bool shouldRepaint(covariant GhostPainter oldDelegate) => oldDelegate.t != t;
}

class BatPainter extends CustomPainter {
  final double t;
  BatPainter({required this.t});

  static void drawBat(Canvas canvas, Offset c, double scale, {double opacity = 1}) {
    final wing = Paint()..color = Colors.black.withOpacity(opacity);
    final body = Paint()..color = Colors.black.withOpacity(opacity);
    final left = Path()
      ..moveTo(c.dx, c.dy)
      ..quadraticBezierTo(c.dx - 18 * scale, c.dy - 12 * scale, c.dx - 36 * scale, c.dy)
      ..quadraticBezierTo(c.dx - 18 * scale, c.dy + 10 * scale, c.dx, c.dy)
      ..close();
    final right = Path()
      ..moveTo(c.dx, c.dy)
      ..quadraticBezierTo(c.dx + 18 * scale, c.dy - 12 * scale, c.dx + 36 * scale, c.dy)
      ..quadraticBezierTo(c.dx + 18 * scale, c.dy + 10 * scale, c.dx, c.dy)
      ..close();
    canvas.drawPath(left, wing);
    canvas.drawPath(right, wing);
    canvas.drawOval(Rect.fromCenter(center: c, width: 10 * scale, height: 14 * scale), body);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * (.15 + .7 * (0.5 + 0.5 * sin(t * 2 * pi))),
        size.height * .35 + sin(t * 2 * pi) * 10);
    drawBat(canvas, c, .9);
  }

  @override
  bool shouldRepaint(covariant BatPainter oldDelegate) => oldDelegate.t != t;
}
