// ignore_for_file: unused_element, unused_local_variable, deprecated_member_use

import 'dart:async';
import 'dart:io';
// ignore: unused_import
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:table_calendar/table_calendar.dart';

// ─── Brand Palette ────────────────────────────────────────────────────────────
class LiftdColors {
  static const bg        = Color(0xFF0A0A0A);
  static const surface   = Color(0xFF141414);
  static const card      = Color(0xFF1A1A1A);
  static const orange    = Color(0xFFE85D24);
  static const cream     = Color(0xFFF2F0EB);
  static const lifted    = Color(0xFF22C55E);
  static const benched   = Color(0xFFEF4444);
  static const recovered = Color(0xFF64748B);
  static const blue      = Color(0xFF60A5FA);
}

// ─── Enums ────────────────────────────────────────────────────────────────────
enum GymStatus { none, lifted, benched, recovered }
enum ExerciseStatus { pending, done, missed }

// ─── Main ─────────────────────────────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  await Hive.initFlutter();
  await Hive.openBox('liftdBox');
  runApp(const LiftdApp());
}

// ─── Animated Splash Screen ───────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<double> _barWidth;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));

    // Logo scales up from 0.4 → 1.0 with a slight overshoot
    _scale = Tween<double>(begin: 0.4, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl,
            curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack)));

    // Logo fades in
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl,
            curve: const Interval(0.0, 0.4, curve: Curves.easeOut)));

    // Orange bar under logo grows from 0 → full width
    _barWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl,
            curve: const Interval(0.45, 0.75, curve: Curves.easeOutCubic)));

    // "liftd." text fades + slides up
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl,
            curve: const Interval(0.6, 0.85, curve: Curves.easeOut)));
    _textSlide = Tween<Offset>(
        begin: const Offset(0, 0.5), end: Offset.zero).animate(
        CurvedAnimation(parent: _ctrl,
            curve: const Interval(0.6, 0.85, curve: Curves.easeOutCubic)));

    _ctrl.forward();

    // Navigate after animation + short hold
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNavigationScreen(),
          transitionDuration: const Duration(milliseconds: 500),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim, child: child),
        ));
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LiftdColors.bg,
      body: Stack(children: [
        // Subtle orange glow bottom-right
        Positioned(
          bottom: -120, right: -80,
          child: Container(
            width: 280, height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                LiftdColors.orange.withOpacity(0.12), Colors.transparent,
              ]),
            ),
          ),
        ),
        // Blue glow top-left
        Positioned(
          top: -80, left: -60,
          child: Container(
            width: 220, height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                LiftdColors.blue.withOpacity(0.07), Colors.transparent,
              ]),
            ),
          ),
        ),
        // Centred logo + text
        Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo badge
                Opacity(
                  opacity: _fade.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0E0E0E),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                            color: LiftdColors.orange.withOpacity(0.35),
                            width: 1.5),
                        boxShadow: [
                          BoxShadow(
                              color: LiftdColors.orange.withOpacity(0.18),
                              blurRadius: 32, spreadRadius: 2),
                        ],
                      ),
                      child: const Center(child: LiftdLogo(size: 58)),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                // Animated orange bar (grows left→right)
                SizedBox(
                  width: 48,
                  height: 3,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: _barWidth.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: LiftdColors.orange,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // "liftd." text
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: 'liftd',
                          style: GoogleFonts.spaceMono(
                              color: LiftdColors.cream,
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5),
                        ),
                        TextSpan(
                          text: '.',
                          style: GoogleFonts.spaceMono(
                              color: LiftdColors.orange,
                              fontSize: 26,
                              fontWeight: FontWeight.w700),
                        ),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                FadeTransition(
                  opacity: _textFade,
                  child: Text(
                    'minimal. focused. consistent.',
                    style: GoogleFonts.spaceMono(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                        letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── App Root ─────────────────────────────────────────────────────────────────
class LiftdApp extends StatelessWidget {
  const LiftdApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Liftd.',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
        colorScheme: const ColorScheme.dark(
          primary: LiftdColors.orange,
          secondary: LiftdColors.blue,
          surface: LiftdColors.surface,
        ),
        textTheme: GoogleFonts.spaceMonoTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: LiftdColors.card,
          contentTextStyle: GoogleFonts.spaceMono(color: LiftdColors.cream, fontSize: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          actionTextColor: LiftdColors.orange,
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: LiftdColors.surface,
          modalBackgroundColor: LiftdColors.surface,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: GoogleFonts.spaceMono(color: Colors.grey.shade600),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: LiftdColors.orange),
          ),
          filled: true,
          fillColor: LiftdColors.card,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: LiftdColors.orange,
            foregroundColor: LiftdColors.cream,
            textStyle: GoogleFonts.spaceMono(fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ), dialogTheme: const DialogThemeData(backgroundColor: LiftdColors.surface),
      ),
      home: const SplashScreen(),
    );
  }
}

// ─── Storage ──────────────────────────────────────────────────────────────────
class StorageKeys {
  static const boxName        = 'liftdBox';
  static const calorieTarget  = 'calorieTarget';
  static const calorieEntries = 'calorieEntries';
  static const progressPhotos = 'progressPhotos';
  static const weeklyPlan     = 'weeklyPlan';
  static const customPlans    = 'customPlans';   // List of user-saved custom plans
  static const prRecords      = 'prRecords';     // List of PR entries
  static const notes          = 'notes';         // List of saved notes
}

class AppDataUtils {
  static Box get box => Hive.box(StorageKeys.boxName);
  static bool _isAtt(dynamic k) =>
      k is String && RegExp(r'^\d{4}-\d{1,2}-\d{1,2}$').hasMatch(k);
  static bool _isWkt(dynamic k) => k is String && k.startsWith('workout-');
  static void resetAttendance() {
    for (final k in box.keys.where(_isAtt).toList()) {
      box.delete(k);
    }
  }
  static void resetWorkoutProgress() {
    for (final k in box.keys.where(_isWkt).toList()) {
      box.delete(k);
    }
  }
  static void resetCalories() {
    box.delete(StorageKeys.calorieEntries);
    box.put(StorageKeys.calorieTarget, 2000);
  }
  static void resetProgressPhotos() => box.delete(StorageKeys.progressPhotos);
  static void resetEverything() {
    box.clear();
    box.put(StorageKeys.calorieTarget, 2000);
  }
}

// ─── Tab transitions — simple, clean fade + directional slide ─────────────────
Widget _tabTransition(Widget child, Animation<double> anim, int to, int from) {
  final curve = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
  final fade  = CurvedAnimation(parent: anim, curve: Curves.easeOut);
  final goRight = to > from;
  final offset = Offset(goRight ? 0.06 : -0.06, 0);
  return FadeTransition(
    opacity: fade,
    child: SlideTransition(
      position: Tween<Offset>(begin: offset, end: Offset.zero).animate(curve),
      child: child,
    ),
  );
}

// ─── Navigation ───────────────────────────────────────────────────────────────
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _cur = 0, _prev = 0;
  GymStatus? _flashStatus;

  void _triggerFlash(GymStatus s) {
    setState(() => _flashStatus = s);
    Future.delayed(const Duration(milliseconds: 1700),
        () { if (mounted) setState(() => _flashStatus = null); });
  }

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(onStatusFlash: _triggerFlash),
      const CalendarScreen(),
      const WorkoutScreen(),
      const CaloriesScreen(),
      const ProgressScreen(),
      const PRScreen(),
      SettingsScreen(onRefreshAll: () => setState(() {})),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return LiftdScaffold(
      child: Stack(children: [
        Scaffold(
          backgroundColor: Colors.transparent,
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve:  Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => _tabTransition(child, anim, _cur, _prev),
            child: KeyedSubtree(
              key: ValueKey(_cur),
              child: _screens[_cur],
            ),
          ),
          bottomNavigationBar: _LiftdNavBar(
            currentIndex: _cur,
            onTap: (i) => setState(() { _prev = _cur; _cur = i; }),
          ),
        ),
        // Full-screen status flash overlay
        if (_flashStatus != null)
          _StatusFlashOverlay(status: _flashStatus!),
      ]),
    );
  }
}

// ─── Status Flash Overlay ─────────────────────────────────────────────────────
class _StatusFlashOverlay extends StatefulWidget {
  final GymStatus status;
  const _StatusFlashOverlay({required this.status});
  @override
  State<_StatusFlashOverlay> createState() => _StatusFlashOverlayState();
}

class _StatusFlashOverlayState extends State<_StatusFlashOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  // Opacity: ramp up → hold → ramp down
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1700));
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.26), weight: 12),
      TweenSequenceItem(tween: ConstantTween(0.26),           weight: 55),
      TweenSequenceItem(tween: Tween(begin: 0.26, end: 0.0),  weight: 33),
    ]).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Color get _color {
    switch (widget.status) {
      case GymStatus.lifted:    return LiftdColors.lifted;
      case GymStatus.benched:   return LiftdColors.benched;
      case GymStatus.recovered: return LiftdColors.recovered;
      default: return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Stack(children: [
          Container(color: _color.withOpacity(_opacity.value)),
          Center(child: _FlashIcon(status: widget.status, ctrl: _ctrl)),
        ]),
      ),
    );
  }
}

// The animated icon drawn on top of the flash
class _FlashIcon extends StatelessWidget {
  final GymStatus status;
  final AnimationController ctrl;
  const _FlashIcon({required this.status, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final scaleSq = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.2, end: 1.18)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.18, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0),            weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 25),
    ]).animate(ctrl);

    final opacitySq = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 18),
      TweenSequenceItem(tween: ConstantTween(1.0),           weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 27),
    ]).animate(ctrl);

    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => Opacity(
        opacity: opacitySq.value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: scaleSq.value,
          child: _iconWidget(),
        ),
      ),
    );
  }

  Widget _iconWidget() {
    switch (status) {
      case GymStatus.lifted:
        return _LiftedFlashIcon(ctrl: ctrl);
      case GymStatus.benched:
        return _BenchedFlashIcon(ctrl: ctrl);
      case GymStatus.recovered:
        return _circleIcon(LiftdColors.recovered, Icons.bedtime_rounded);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _circleIcon(Color c, IconData icon) => Container(
    width: 110, height: 110,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: c.withOpacity(0.22),
      border: Border.all(color: c, width: 3),
    ),
    child: Icon(icon, color: c, size: 52),
  );
}

// Arrow animates upward while icon grows
class _LiftedFlashIcon extends StatelessWidget {
  final AnimationController ctrl;
  const _LiftedFlashIcon({required this.ctrl});
  @override
  Widget build(BuildContext context) {
    final rise = Tween<double>(begin: 0, end: -28).animate(
        CurvedAnimation(parent: ctrl, curve: const Interval(0.0, 0.55, curve: Curves.easeOut)));
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, rise.value),
        child: Container(
          width: 110, height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: LiftdColors.lifted.withOpacity(0.2),
            border: Border.all(color: LiftdColors.lifted, width: 3),
          ),
          child: const Icon(Icons.arrow_upward_rounded,
              color: LiftdColors.lifted, size: 58),
        ),
      ),
    );
  }
}

// Cross draws itself stroke-by-stroke
class _BenchedFlashIcon extends StatelessWidget {
  final AnimationController ctrl;
  const _BenchedFlashIcon({required this.ctrl});
  @override
  Widget build(BuildContext context) {
    final draw = CurvedAnimation(
        parent: ctrl, curve: const Interval(0.0, 0.45, curve: Curves.easeOut));
    return AnimatedBuilder(
      animation: draw,
      builder: (_, __) => Container(
        width: 110, height: 110,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: LiftdColors.benched.withOpacity(0.2),
          border: Border.all(color: LiftdColors.benched, width: 3),
        ),
        child: CustomPaint(painter: _CrossPainter(progress: draw.value)),
      ),
    );
  }
}

class _CrossPainter extends CustomPainter {
  final double progress;
  _CrossPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size sz) {
    final p = Paint()
      ..color = LiftdColors.benched
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const pad = 0.28;
    final tl = Offset(sz.width * pad, sz.height * pad);
    final br = Offset(sz.width * (1 - pad), sz.height * (1 - pad));
    final tr = Offset(sz.width * (1 - pad), sz.height * pad);
    final bl = Offset(sz.width * pad, sz.height * (1 - pad));
    if (progress <= 0.5) {
      canvas.drawLine(tl, Offset.lerp(tl, br, (progress / 0.5).clamp(0, 1))!, p);
    } else {
      canvas.drawLine(tl, br, p);
      canvas.drawLine(tr, Offset.lerp(tr, bl, ((progress - 0.5) / 0.5).clamp(0, 1))!, p);
    }
  }
  @override
  bool shouldRepaint(_CrossPainter o) => o.progress != progress;
}

// ─── Nav Bar ──────────────────────────────────────────────────────────────────
class _LiftdNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _LiftdNavBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_outlined,                 Icons.home_rounded,                 'Home'),
      (Icons.calendar_month_outlined,       Icons.calendar_month_rounded,       'Calendar'),
      (Icons.fitness_center_outlined,       Icons.fitness_center_rounded,       'Workout'),
      (Icons.local_fire_department_outlined,Icons.local_fire_department_rounded,'Calories'),
      (Icons.photo_library_outlined,        Icons.photo_library_rounded,        'Progress'),
      (Icons.emoji_events_outlined,         Icons.emoji_events_rounded,         'PR'),
      (Icons.settings_outlined,             Icons.settings_rounded,             'Settings'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: LiftdColors.surface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) => _NavItem(
              icon:     currentIndex == i ? items[i].$2 : items[i].$1,
              label:    items[i].$3,
              selected: currentIndex == i,
              onTap:    () => onTap(i),
            )),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label,
      required this.selected, required this.onTap});
  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _scale = Tween<double>(begin: 1.0, end: 0.80)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
          decoration: BoxDecoration(
            color: widget.selected ? LiftdColors.orange.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(widget.icon, key: ValueKey(widget.selected),
                  color: widget.selected ? LiftdColors.orange : Colors.grey.shade600, size: 20),
            ),
            const SizedBox(height: 2),
            Text(widget.label, style: GoogleFonts.spaceMono(
                fontSize: 8, fontWeight: FontWeight.w700,
                color: widget.selected ? LiftdColors.orange : Colors.grey.shade600)),
          ]),
        ),
      ),
    );
  }
}

// ─── Liftd Scaffold ────────────────────────────────────────────────────────────
class LiftdScaffold extends StatelessWidget {
  final Widget child;
  const LiftdScaffold({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      color: LiftdColors.bg,
      child: Stack(children: [
        Positioned(bottom: -160, right: -100,
            child: Container(width: 320, height: 320,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      LiftdColors.orange.withOpacity(0.07), Colors.transparent])))),
        Positioned(top: -100, left: -60,
            child: Container(width: 240, height: 240,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      LiftdColors.blue.withOpacity(0.05), Colors.transparent])))),
        child,
      ]),
    );
  }
}

// ─── Page Shell ───────────────────────────────────────────────────────────────
class AppPage extends StatelessWidget {
  final Widget child;
  final String title, subtitle;
  final List<Widget>? actions;
  final bool showLogo;

  const AppPage({super.key, required this.child, required this.title,
      required this.subtitle, this.actions, this.showLogo = false});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Header(title: title, subtitle: subtitle,
              actions: actions, showLogo: showLogo),
          const SizedBox(height: 18),
          Expanded(child: child),
        ]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title, subtitle;
  final List<Widget>? actions;
  final bool showLogo;
  const _Header({required this.title, required this.subtitle,
      this.actions, this.showLogo = false});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      if (showLogo) ...[
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF0E0E0E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: LiftdColors.orange.withOpacity(0.35)),
          ),
          child: const Center(child: LiftdLogo(size: 26)),
        ),
        const SizedBox(width: 12),
      ],
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Title: everything except trailing "." uses cream gradient; "." is orange
          RichText(
            text: TextSpan(children: [
              TextSpan(
                text: showLogo
                    ? title.replaceAll('.', '')   // strip dot, paint separately
                    : title,
                style: GoogleFonts.spaceMono(
                    color: LiftdColors.cream, fontSize: 27,
                    fontWeight: FontWeight.w700, letterSpacing: -0.5),
              ),
              if (showLogo && title.contains('.'))
                TextSpan(
                  text: '.',
                  style: GoogleFonts.spaceMono(
                      color: LiftdColors.orange, fontSize: 27,
                      fontWeight: FontWeight.w700, letterSpacing: -0.5),
                ),
            ]),
          ),
          const SizedBox(height: 5),
          Text(subtitle, style: GoogleFonts.spaceMono(
              fontSize: 11, color: Colors.grey.shade500)),
        ]),
      ),
      if (actions != null) ...actions!,
    ]);
  }
}

// ─── Liftd Logo ────────────────────────────────────────────────────────────────
class LiftdLogo extends StatelessWidget {
  final double size;
  final Color arrowColor;
  const LiftdLogo({super.key, this.size = 48, this.arrowColor = LiftdColors.cream});
  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size,
      child: CustomPaint(painter: _LogoPainter(arrowColor: arrowColor)));
}

class _LogoPainter extends CustomPainter {
  final Color arrowColor;
  _LogoPainter({required this.arrowColor});
  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final arrow = Paint()..color = arrowColor..style = PaintingStyle.fill..isAntiAlias = true;
    final orange = Paint()..color = LiftdColors.orange..style = PaintingStyle.fill..isAntiAlias = true;
    // Stem
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w*0.433, h*0.333, w*0.133, h*0.4), Radius.circular(w*0.044)), arrow);
    // Head
    canvas.drawPath(Path()
      ..moveTo(w*0.5, h*0.2)
      ..lineTo(w*0.289, h*0.422)..lineTo(w*0.344, h*0.422)
      ..lineTo(w*0.5, h*0.267)
      ..lineTo(w*0.656, h*0.422)..lineTo(w*0.711, h*0.422)
      ..close(), arrow);
    // Bar
    canvas.drawRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(w*0.333, h*0.756, w*0.333, h*0.067), Radius.circular(w*0.033)), orange);
  }
  @override
  bool shouldRepaint(_LogoPainter o) => o.arrowColor != arrowColor;
}

// ─── HOME SCREEN ──────────────────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  final ValueChanged<GymStatus>? onStatusFlash;
  const HomeScreen({super.key, this.onStatusFlash});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

// ─── Rank System ──────────────────────────────────────────────────────────────
// 8 tiers, escalating thresholds. Icon shapes inspired by the Valorant-style
// badge image: each rank has a unique color pair + an IconData stand-in.
class RankTier {
  final String name;
  final int minPts, maxPts; // maxPts = minPts of next; top tier = 999999
  final Color primary, glow;
  final IconData icon;
  final String quote;        // motivational quote shown on rank card
  const RankTier({
    required this.name, required this.minPts, required this.maxPts,
    required this.primary, required this.glow,
    required this.icon, required this.quote,
  });
}

const List<RankTier> kRanks = [
  RankTier(
    name: 'Unranked', minPts: 0, maxPts: 60,
    primary: Color(0xFF6B7280), glow: Color(0xFF374151),
    icon: Icons.help_outline_rounded,
    quote: 'Every legend started with a first step.',
  ),
  RankTier(
    name: 'Initiate', minPts: 60, maxPts: 180,
    primary: Color(0xFF78716C), glow: Color(0xFF44403C),
    icon: Icons.shield_outlined,
    quote: 'The iron never lies. Show up.',
  ),
  RankTier(
    name: 'Trainee', minPts: 180, maxPts: 380,
    primary: Color(0xFF10B981), glow: Color(0xFF065F46),
    icon: Icons.bolt_rounded,
    quote: 'Discipline beats motivation every single time.',
  ),
  RankTier(
    name: 'Grinder', minPts: 380, maxPts: 700,
    primary: Color(0xFF3B82F6), glow: Color(0xFF1E3A5F),
    icon: Icons.local_fire_department_rounded,
    quote: 'Pain is temporary. Progress is permanent.',
  ),
  RankTier(
    name: 'Forged', minPts: 700, maxPts: 1200,
    primary: Color(0xFF8B5CF6), glow: Color(0xFF3B0764),
    icon: Icons.diamond_outlined,
    quote: 'You are being forged — every rep is a hammer strike.',
  ),
  RankTier(
    name: 'Loaded', minPts: 1200, maxPts: 2000,
    primary: Color(0xFFF59E0B), glow: Color(0xFF78350F),
    icon: Icons.military_tech_rounded,
    quote: 'The bar bends, you don\'t. Loaded and locked in.',
  ),
  RankTier(
    name: 'Beast', minPts: 2000, maxPts: 3200,
    primary: Color(0xFFEF4444), glow: Color(0xFF7F1D1D),
    icon: Icons.whatshot_rounded,
    quote: 'Ordinary people rest. Beasts adapt and destroy.',
  ),
  RankTier(
    name: 'Titan', minPts: 3200, maxPts: 5000,
    primary: Color(0xFFEC4899), glow: Color(0xFF831843),
    icon: Icons.workspace_premium_rounded,
    quote: 'At the summit, the air is thin. Titans breathe it anyway.',
  ),
  RankTier(
    name: 'Legend', minPts: 5000, maxPts: 999999,
    primary: Color(0xFFE85D24), glow: Color(0xFF7C2D12),
    icon: Icons.auto_awesome_rounded,
    quote: 'Legends don\'t quit. They become the standard.',
  ),
];

RankTier rankFor(int pts) {
  RankTier cur = kRanks.first;
  for (final r in kRanks) { if (pts >= r.minPts) cur = r; }
  return cur;
}

class RankInfo {
  final RankTier tier;
  final int points;
  RankInfo({required this.tier, required this.points});
}

class _HomeScreenState extends State<HomeScreen> {
  GymStatus todayStatus = GymStatus.none;
  late Box fitBox;

  @override
  void initState() { super.initState(); fitBox = Hive.box(StorageKeys.boxName); _load(); }

  String _todayKey() { final n = DateTime.now(); return '${n.year}-${n.month}-${n.day}'; }

  void _load() {
    final s = fitBox.get(_todayKey(), defaultValue: 'none');
    setState(() => todayStatus = GymStatus.values.firstWhere(
        (e) => e.name == s, orElse: () => GymStatus.none));
  }

  void _setStatus(GymStatus s) {
    HapticFeedback.mediumImpact();
    setState(() => todayStatus = s);
    fitBox.put(_todayKey(), s.name);
    widget.onStatusFlash?.call(s);
  }

  String get _txt {
    switch (todayStatus) {
      case GymStatus.lifted:    return 'Lifted';
      case GymStatus.benched:   return 'Benched';
      case GymStatus.recovered: return 'Recovered';
      case GymStatus.none:      return 'Not marked yet';
    }
  }
  Color get _color {
    switch (todayStatus) {
      case GymStatus.lifted:    return LiftdColors.lifted;
      case GymStatus.benched:   return LiftdColors.benched;
      case GymStatus.recovered: return LiftdColors.recovered;
      case GymStatus.none:      return Colors.grey.shade700;
    }
  }
  String get _motivation {
    switch (todayStatus) {
      case GymStatus.lifted:    return 'Plates don\'t lie. Keep moving.';
      case GymStatus.benched:   return 'Tomorrow is a fresh rep.';
      case GymStatus.recovered: return 'Recovery is training too.';
      case GymStatus.none:      return 'Mark your day. Stay consistent.';
    }
  }

  int get _todayCal {
    final n = DateTime.now();
    return List<Map<String, dynamic>>.from(
      ((fitBox.get(StorageKeys.calorieEntries, defaultValue: []) as List))
          .map((e) => Map<String, dynamic>.from(e)),
    ).where((e) => e['year']==n.year && e['month']==n.month && e['day']==n.day)
     .fold<int>(0, (s, e) => s + ((e['calories'] ?? 0) as int));
  }
  int get _calTarget => fitBox.get(StorageKeys.calorieTarget, defaultValue: 2000) as int;
  int get _photoCount =>
      (fitBox.get(StorageKeys.progressPhotos, defaultValue: []) as List).length;
  int get _wktDone {
    final n = DateTime.now();
    final data = fitBox.get('workout-${n.year}-${n.month}-${n.day}');
    if (data == null) return 0;
    return List<Map<String, dynamic>>.from(
        (data as List).map((e) => Map<String, dynamic>.from(e)))
        .where((e) => e['status'] == ExerciseStatus.done.name).length;
  }

  RankInfo _calcRank() {
    int pts = 0;

    // Only attendance-based keys (format: "year-month-day")
    final attendanceKeys = fitBox.keys
        .where((k) => k is String &&
            RegExp(r'^\d{4}-\d{1,2}-\d{1,2}$').hasMatch(k))
        .cast<String>()
        .toList();

    // Add points for logged days
    for (final k in attendanceKeys) {
      final v = fitBox.get(k);
      if (v == GymStatus.lifted.name)  pts += 15; // Went to gym
      if (v == GymStatus.benched.name) pts -= 8;  // Missed gym day
    }

    // Only deduct for unlogged days AFTER the first ever entry
    // This prevents punishing users for days before they installed the app
    if (attendanceKeys.isNotEmpty) {
      // Find the earliest logged date
      DateTime? firstDate;
      for (final k in attendanceKeys) {
        final parts = k.split('-');
        if (parts.length == 3) {
          final d = DateTime(
              int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          if (firstDate == null || d.isBefore(firstDate)) firstDate = d;
        }
      }

      if (firstDate != null) {
        final today = DateTime.now();
        final todayZero = DateTime(today.year, today.month, today.day);
        // Walk from day after first entry up to yesterday
        DateTime cursor = firstDate.add(const Duration(days: 1));
        while (cursor.isBefore(todayZero)) {
          final key = '${cursor.year}-${cursor.month}-${cursor.day}';
          final v = fitBox.get(key);
          if (v == null || v == 'none') {
            pts -= 3; // Day after first use — not logged
          }
          cursor = cursor.add(const Duration(days: 1));
        }
      }
    }

    // Points can never go below 0
    if (pts < 0) pts = 0;

    return RankInfo(tier: rankFor(pts), points: pts);
  }

  void _openRankSheet() {
    final r = _calcRank();
    final isMax = r.tier.maxPts == 999999;
    final progress = isMax ? 1.0
        : ((r.points - r.tier.minPts) / (r.tier.maxPts - r.tier.minPts)).clamp(0.0, 1.0);
    final ptsToNext = isMax ? 0 : r.tier.maxPts - r.points;

    showModalBottomSheet(
      context: context,
      // Transparent so our Container paints the full background — no system white
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.65),
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, sc) => Container(
          // Full dark background — covers every pixel of the sheet
          decoration: const BoxDecoration(
            color: LiftdColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(children: [
          const SizedBox(height: 12),
          // Themed drag handle
          Container(width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Text('All Ranks', style: GoogleFonts.spaceMono(
                  color: LiftdColors.cream, fontSize: 20, fontWeight: FontWeight.w700)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: r.tier.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: r.tier.primary.withOpacity(0.5))),
                child: Text(r.tier.name, style: GoogleFonts.spaceMono(
                    color: r.tier.primary, fontWeight: FontWeight.w700, fontSize: 11)),
              ),
            ]),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${r.points} pts  •  ${isMax ? "MAX RANK" : "$ptsToNext pts to ${_nextRank(r.tier)?.name ?? 'Legend'}"}',
                style: GoogleFonts.spaceMono(color: Colors.grey.shade500, fontSize: 11)),
            ),
          ),
          const SizedBox(height: 14),
          Divider(color: Colors.white.withOpacity(0.06), height: 1),
          // Scoring legend
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: LiftdColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('HOW POINTS WORK', style: GoogleFonts.spaceMono(
                    color: Colors.grey.shade500, fontSize: 9, letterSpacing: 1.4)),
                const SizedBox(height: 10),
                const _ScoreRow(icon: Icons.arrow_upward_rounded,
                    color: LiftdColors.lifted,   label: 'Lifted',           pts: '+15'),
                const _ScoreRow(icon: Icons.close_rounded,
                    color: LiftdColors.benched,  label: 'Benched (missed)', pts: '-8'),
                const _ScoreRow(icon: Icons.help_outline_rounded,
                    color: Colors.grey,          label: 'Day not logged',   pts: '-3'),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: sc,
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              itemCount: kRanks.length,
              itemBuilder: (_, i) {
                final rank = kRanks[i];
                final isCur = rank.name == r.tier.name;
                final unlocked = r.points >= rank.minPts;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isCur ? rank.primary.withOpacity(0.08) : LiftdColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isCur
                            ? rank.primary.withOpacity(0.55)
                            : Colors.white.withOpacity(0.05),
                        width: isCur ? 1.5 : 1),
                    boxShadow: isCur
                        ? [BoxShadow(color: rank.glow.withOpacity(0.35),
                            blurRadius: 20, spreadRadius: -4)]
                        : [],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Container(
                        width: 52, height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            rank.primary.withOpacity(unlocked ? 0.28 : 0.06),
                            rank.glow.withOpacity(unlocked ? 0.45 : 0.08),
                          ]),
                          border: Border.all(
                              color: rank.primary.withOpacity(unlocked ? 0.65 : 0.18),
                              width: isCur ? 2 : 1),
                        ),
                        child: Icon(rank.icon,
                            color: rank.primary.withOpacity(unlocked ? 1.0 : 0.3),
                            size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(rank.name,
                                style: GoogleFonts.spaceMono(
                                    color: unlocked ? rank.primary : Colors.grey.shade700,
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                            if (isCur) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                    color: rank.primary.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(6)),
                                child: Text('YOU', style: GoogleFonts.spaceMono(
                                    color: rank.primary, fontSize: 8, fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ]),
                          const SizedBox(height: 3),
                          Text(
                            rank.maxPts == 999999
                                ? '${rank.minPts}+ pts'
                                : '${rank.minPts} – ${rank.maxPts} pts',
                            style: GoogleFonts.spaceMono(
                                color: Colors.grey.shade600, fontSize: 10),
                          ),
                          if (isCur) ...[
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: LinearProgressIndicator(
                                value: progress, minHeight: 5,
                                backgroundColor: Colors.white.withOpacity(0.06),
                                valueColor: AlwaysStoppedAnimation<Color>(rank.primary),
                              ),
                            ),
                          ],
                        ],
                      )),
                      if (!unlocked)
                        Icon(Icons.lock_outline_rounded,
                            color: Colors.grey.shade700, size: 16),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
        ),
      ),
    );
  }

  RankTier? _nextRank(RankTier cur) {
    final idx = kRanks.indexWhere((r) => r.name == cur.name);
    return idx < kRanks.length - 1 ? kRanks[idx + 1] : null;
  }

  @override
  Widget build(BuildContext context) {
    final r = _calcRank();
    final tier = r.tier;
    final isMax = tier.maxPts == 999999;
    final progress = isMax ? 1.0
        : ((r.points - tier.minPts) / (tier.maxPts - tier.minPts)).clamp(0.0, 1.0);
    final ptsToNext = isMax ? 0 : tier.maxPts - r.points;
    final nextTier = _nextRank(tier);

    return AppPage(
      title: 'liftd.',
      subtitle: 'minimal. focused. consistent.',
      showLogo: true,
      child: ListView(children: [
        _StatusCard(statusText: _txt, statusColor: _color, subtitle: _motivation,
            isActive: todayStatus == GymStatus.lifted),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _StatusBtn(label: 'Lifted',    color: LiftdColors.lifted,
              icon: Icons.arrow_upward_rounded, onTap: () => _setStatus(GymStatus.lifted))),
          const SizedBox(width: 10),
          Expanded(child: _StatusBtn(label: 'Benched',   color: LiftdColors.benched,
              icon: Icons.close_rounded,        onTap: () => _setStatus(GymStatus.benched))),
          const SizedBox(width: 10),
          Expanded(child: _StatusBtn(label: 'Recovered', color: LiftdColors.recovered,
              icon: Icons.bedtime_outlined,     onTap: () => _setStatus(GymStatus.recovered))),
        ]),
        const SizedBox(height: 22),

        // ── Premium Rank Card ───────────────────────────────────────────────
        _RankCard(
          rankInfo: r,
          progress: progress,
          ptsToNext: ptsToNext,
          nextTierName: nextTier?.name,
          onInfoTap: _openRankSheet,
        ),
        const SizedBox(height: 22),

        const _SectionTitle(title: 'Overview'),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _InfoCard(title: 'Calories',
              value: '$_todayCal / $_calTarget', icon: Icons.local_fire_department_outlined)),
          const SizedBox(width: 12),
          Expanded(child: _InfoCard(title: 'Sets Done',
              value: '$_wktDone done', icon: Icons.fitness_center_outlined)),
        ]),
        const SizedBox(height: 12),
        _InfoCard(title: 'Photos',
            value: '$_photoCount saved', icon: Icons.photo_camera_back_outlined,
            fullWidth: true),
      ]),
    );
  }
}

// ─── Premium Rank Card ────────────────────────────────────────────────────────
class _RankCard extends StatefulWidget {
  final RankInfo rankInfo;
  final double progress;
  final int ptsToNext;
  final String? nextTierName;
  final VoidCallback onInfoTap;

  const _RankCard({
    required this.rankInfo, required this.progress,
    required this.ptsToNext, this.nextTierName, required this.onInfoTap,
  });
  @override State<_RankCard> createState() => _RankCardState();
}

class _RankCardState extends State<_RankCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _glow;
  @override void initState() {
    super.initState();
    _glow = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
  }
  @override void dispose() { _glow.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final tier   = widget.rankInfo.tier;
    final isMax  = tier.maxPts == 999999;

    return AnimatedBuilder(
      animation: _glow,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              tier.glow.withOpacity(0.45 + 0.15 * _glow.value),
              LiftdColors.card,
              LiftdColors.card,
            ],
          ),
          border: Border.all(
              color: tier.primary.withOpacity(0.4 + 0.2 * _glow.value), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: tier.glow.withOpacity(0.35 + 0.15 * _glow.value),
                blurRadius: 28, spreadRadius: -4, offset: const Offset(0, 8)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Header row: badge + name + "i" button ─────────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              // Badge
              Container(
                width: 58, height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    tier.primary.withOpacity(0.35),
                    tier.glow.withOpacity(0.6),
                  ]),
                  border: Border.all(color: tier.primary.withOpacity(0.8), width: 2),
                  boxShadow: [BoxShadow(
                      color: tier.primary.withOpacity(0.4 + 0.2 * _glow.value),
                      blurRadius: 16, spreadRadius: 2)],
                ),
                child: Icon(tier.icon, color: tier.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CURRENT RANK', style: GoogleFonts.spaceMono(
                    color: Colors.grey.shade500, fontSize: 9, letterSpacing: 1.4)),
                const SizedBox(height: 4),
                Text(tier.name, style: GoogleFonts.spaceMono(
                    color: tier.primary, fontSize: 22, fontWeight: FontWeight.w700,
                    letterSpacing: -0.5)),
                Text('${widget.rankInfo.points} pts total',
                    style: GoogleFonts.spaceMono(
                        color: Colors.grey.shade500, fontSize: 10)),
              ])),
              // "i" info button
              GestureDetector(
                onTap: widget.onInfoTap,
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: tier.primary.withOpacity(0.12),
                    border: Border.all(color: tier.primary.withOpacity(0.4)),
                  ),
                  child: Icon(Icons.info_outline_rounded,
                      color: tier.primary.withOpacity(0.9), size: 16),
                ),
              ),
            ]),

            const SizedBox(height: 20),

            // ── Progress bar ──────────────────────────────────────────────
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: widget.progress),
                    duration: const Duration(milliseconds: 1100),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => LinearProgressIndicator(
                      value: v, minHeight: 7,
                      backgroundColor: Colors.white.withOpacity(0.06),
                      valueColor: AlwaysStoppedAnimation<Color>(tier.primary),
                    ),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Text('${tier.minPts}', style: GoogleFonts.spaceMono(
                  color: Colors.grey.shade600, fontSize: 9)),
              const Spacer(),
              Text(isMax ? 'LEGEND' : '${tier.maxPts}', style: GoogleFonts.spaceMono(
                  color: Colors.grey.shade600, fontSize: 9)),
            ]),

            const SizedBox(height: 18),

            // ── Next rank chip + pts to go ──────────────────────────────
            if (!isMax)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(0.07))),
                child: Row(children: [
                  Icon(Icons.arrow_upward_rounded, color: tier.primary, size: 14),
                  const SizedBox(width: 8),
                  Text('${widget.ptsToNext} pts to ',
                      style: GoogleFonts.spaceMono(
                          color: Colors.grey.shade400, fontSize: 11)),
                  Text(widget.nextTierName ?? '',
                      style: GoogleFonts.spaceMono(
                          color: tier.primary, fontWeight: FontWeight.w700, fontSize: 11)),
                ]),
              ),
            if (isMax)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: tier.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tier.primary.withOpacity(0.3))),
                child: Row(children: [
                  Icon(tier.icon, color: tier.primary, size: 14),
                  const SizedBox(width: 8),
                  Text('Maximum rank achieved.', style: GoogleFonts.spaceMono(
                      color: tier.primary, fontWeight: FontWeight.w700, fontSize: 11)),
                ]),
              ),

            const SizedBox(height: 16),

            // ── Motivational quote ────────────────────────────────────────
            Text('"${tier.quote}"',
                style: GoogleFonts.spaceMono(
                    color: Colors.grey.shade400, fontSize: 11,
                    fontStyle: FontStyle.italic, height: 1.5)),
          ]),
        ),
      ),
    );
  }
}


class _ProgressBar extends StatefulWidget {
  final double value;
  const _ProgressBar({required this.value});
  @override State<_ProgressBar> createState() => _ProgressBarState();
}
class _ProgressBarState extends State<_ProgressBar> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _a = Tween<double>(begin: 0, end: widget.value)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _c.forward();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: LinearProgressIndicator(value: _a.value, minHeight: 8,
          backgroundColor: Colors.white.withOpacity(0.06),
          valueColor: const AlwaysStoppedAnimation<Color>(LiftdColors.orange)),
    ),
  );
}

// ─── Status Card ───────────────────────────────────────────────────────────────
class _StatusCard extends StatefulWidget {
  final String statusText, subtitle;
  final Color statusColor;
  final bool isActive;
  const _StatusCard({required this.statusText, required this.statusColor,
      required this.subtitle, required this.isActive});
  @override State<_StatusCard> createState() => _StatusCardState();
}
class _StatusCardState extends State<_StatusCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  @override void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
  }
  @override void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: LiftdColors.card,
        border: Border.all(color: widget.isActive
            ? LiftdColors.orange.withOpacity(0.4) : Colors.white.withOpacity(0.05)),
        boxShadow: widget.isActive
            ? [BoxShadow(color: LiftdColors.orange.withOpacity(0.12),
                blurRadius: 24, offset: const Offset(0, 8))] : [],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Today's Status", style: GoogleFonts.spaceMono(
            fontSize: 11, color: Colors.grey.shade500)),
        const SizedBox(height: 16),
        Row(children: [
          AnimatedBuilder(animation: _pulse, builder: (_, __) => Container(
            width: 12, height: 12,
            decoration: BoxDecoration(shape: BoxShape.circle, color: widget.statusColor,
              boxShadow: widget.isActive ? [BoxShadow(
                  color: widget.statusColor.withOpacity(0.4 + 0.3 * _pulse.value),
                  blurRadius: 8 + 4 * _pulse.value, spreadRadius: 1)] : []),
          )),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (c, a) => FadeTransition(opacity: a,
                  child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(a),
                      child: c)),
              child: Text(widget.statusText, key: ValueKey(widget.statusText),
                  style: GoogleFonts.spaceMono(fontSize: 22,
                      fontWeight: FontWeight.w700, color: LiftdColors.cream)),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Text(widget.subtitle, style: GoogleFonts.spaceMono(
            fontSize: 11, color: Colors.grey.shade500)),
      ]),
    );
  }
}

// ─── Status Button ─────────────────────────────────────────────────────────────
class _StatusBtn extends StatefulWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;
  const _StatusBtn({required this.label, required this.color,
      required this.icon, required this.onTap});
  @override State<_StatusBtn> createState() => _StatusBtnState();
}
class _StatusBtnState extends State<_StatusBtn> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _s = Tween<double>(begin: 1.0, end: 0.90)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(scale: _s,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withOpacity(0.35)),
          ),
          child: Column(children: [
            Icon(widget.icon, color: widget.color, size: 20),
            const SizedBox(height: 6),
            Text(widget.label, style: GoogleFonts.spaceMono(
                color: widget.color, fontWeight: FontWeight.w700, fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}

// ─── Info Card ─────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final bool fullWidth;
  const _InfoCard({required this.title, required this.value,
      required this.icon, this.fullWidth = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: LiftdColors.card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.04))),
      child: Row(children: [
        Container(width: 42, height: 42,
            decoration: BoxDecoration(color: LiftdColors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: LiftdColors.orange, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.spaceMono(fontSize: 10, color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.spaceMono(
              fontSize: 13, fontWeight: FontWeight.w700, color: LiftdColors.cream)),
        ])),
      ]),
    );
  }
}

// ─── Section Title ─────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) => Text(title,
      style: GoogleFonts.spaceMono(fontSize: 14, fontWeight: FontWeight.w700,
          color: LiftdColors.cream, letterSpacing: 0.5));
}

// ─── CALENDAR SCREEN ──────────────────────────────────────────────────────────
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final Box fitBox;
  DateTime focusedDay  = DateTime.now();
  DateTime selectedDay = DateTime.now();

  // Today zeroed to midnight
  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() { super.initState(); fitBox = Hive.box(StorageKeys.boxName); }

  String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';

  bool _isFuture(DateTime d) =>
      DateTime(d.year, d.month, d.day).isAfter(_today);

  // A day is "expired" if it's a past day AND the 24-hour window has closed.
  // The window closes exactly 24 hours after the day ended (midnight + 24h).
  // e.g. March 15 → window closes March 17 at 00:00
  bool _isExpired(DateTime d) {
    final dayZero = DateTime(d.year, d.month, d.day);
    if (!dayZero.isBefore(_today)) return false; // today or future — not expired
    // Window = end of that day (midnight next day) + 24 hours
    final deadline = dayZero.add(const Duration(days: 2)); // midnight + 24h
    return DateTime.now().isAfter(deadline);
  }

  bool _canMark(DateTime d) => !_isFuture(d) && !_isExpired(d);

  GymStatus _statusFor(DateTime d) {
    if (_isFuture(d)) return GymStatus.none;
    final s = fitBox.get(_key(d), defaultValue: 'none');
    return GymStatus.values.firstWhere((e) => e.name == s, orElse: () => GymStatus.none);
  }

  String _readable(GymStatus s) {
    switch (s) {
      case GymStatus.lifted:    return 'Lifted';
      case GymStatus.benched:   return 'Benched';
      case GymStatus.recovered: return 'Recovered';
      case GymStatus.none:      return 'No status';
    }
  }

  Color _statusColor(GymStatus s) {
    switch (s) {
      case GymStatus.lifted:    return LiftdColors.lifted;
      case GymStatus.benched:   return LiftdColors.benched;
      case GymStatus.recovered: return LiftdColors.recovered;
      case GymStatus.none:      return Colors.transparent;
    }
  }

  Widget _calDay(DateTime day, bool isToday, bool isSelected) {
    final future  = _isFuture(day);
    final expired = _isExpired(day);
    final locked  = future || expired;
    final status  = _statusFor(day);
    final color   = _statusColor(status);

    Color bg     = Colors.transparent;
    Color txt    = locked ? Colors.grey.shade700 : LiftdColors.cream;
    Color border = Colors.transparent;

    if (!locked) {
      if (status != GymStatus.none) {
        bg     = color.withOpacity(0.16);
        txt    = color;
        border = isSelected ? LiftdColors.orange : color.withOpacity(0.6);
      } else if (isSelected) {
        bg     = LiftdColors.orange.withOpacity(0.14);
        border = LiftdColors.orange;
      } else if (isToday) {
        border = Colors.white.withOpacity(0.22);
      }
    } else if (expired && status != GymStatus.none) {
      // Already logged before expiry — still show the color, just dimmed
      bg     = color.withOpacity(0.08);
      txt    = color.withOpacity(0.5);
      border = isSelected ? Colors.grey.shade700 : Colors.transparent;
    }

    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36, height: 36,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle,
            border: Border.all(color: border, width: 1.4)),
        child: Center(child: Text('${day.day}',
            style: GoogleFonts.spaceMono(
                color: txt, fontWeight: FontWeight.w700, fontSize: 12))),
      ),
    );
  }

  void _setStatus(GymStatus s) {
    // Block future days
    if (_isFuture(selectedDay)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: LiftdColors.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: LiftdColors.orange.withOpacity(0.35))),
          content: Row(children: [
            const Icon(Icons.lock_outline_rounded, color: LiftdColors.orange, size: 15),
            const SizedBox(width: 8),
            Text('Future days cannot be marked.',
                style: GoogleFonts.spaceMono(color: LiftdColors.cream, fontSize: 12)),
          ]),
        ));
      return;
    }
    // Block expired days (window > 24 hours past)
    if (_isExpired(selectedDay)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          duration: const Duration(seconds: 3),
          backgroundColor: LiftdColors.card,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: LiftdColors.benched.withOpacity(0.45))),
          content: Row(children: [
            const Icon(Icons.timer_off_rounded, color: LiftdColors.benched, size: 15),
            const SizedBox(width: 8),
            Expanded(child: Text('24-hour window closed. −3 pts penalty applied.',
                style: GoogleFonts.spaceMono(color: LiftdColors.cream, fontSize: 11))),
          ]),
        ));
      return;
    }
    HapticFeedback.selectionClick();
    fitBox.put(_key(selectedDay), s.name);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final selStatus  = _statusFor(selectedDay);
    final canMark    = _canMark(selectedDay);
    final isExpired  = _isExpired(selectedDay);
    final isFuture   = _isFuture(selectedDay);

    // Status label for the selected day card
    String statusLabel;
    Color statusColor;
    if (isFuture) {
      statusLabel = 'Future — locked';
      statusColor = Colors.grey.shade800;
    } else if (isExpired && selStatus == GymStatus.none) {
      statusLabel = 'Expired — −3 pts';
      statusColor = LiftdColors.benched;
    } else {
      statusLabel = _readable(selStatus);
      statusColor = _statusColor(selStatus);
    }

    return AppPage(
      title: 'Calendar',
      subtitle: 'your consistency, mapped.',
      child: ListView(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: LiftdColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.04))),
          child: TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: focusedDay,
            selectedDayPredicate: (d) => isSameDay(selectedDay, d),
            onDaySelected: (sel, foc) => setState(() { selectedDay = sel; focusedDay = foc; }),
            headerStyle: HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: GoogleFonts.spaceMono(
                  color: LiftdColors.cream, fontSize: 14, fontWeight: FontWeight.w700),
              leftChevronIcon:  const Icon(Icons.chevron_left,  color: LiftdColors.cream),
              rightChevronIcon: const Icon(Icons.chevron_right, color: LiftdColors.cream),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: GoogleFonts.spaceMono(color: Colors.grey.shade500, fontSize: 10),
              weekendStyle: GoogleFonts.spaceMono(color: Colors.grey.shade500, fontSize: 10),
            ),
            calendarStyle: const CalendarStyle(
              defaultTextStyle:   TextStyle(color: Colors.transparent),
              weekendTextStyle:   TextStyle(color: Colors.transparent),
              todayDecoration:    BoxDecoration(color: Colors.transparent),
              selectedDecoration: BoxDecoration(color: Colors.transparent),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder:  (_, d, __) => _calDay(d, false, false),
              todayBuilder:    (_, d, __) => _calDay(d, true,  false),
              selectedBuilder: (_, d, __) => _calDay(d, false, true),
              outsideBuilder:  (_, d, __) => Center(child: Text('${d.day}',
                  style: GoogleFonts.spaceMono(color: Colors.grey.shade800, fontSize: 12))),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SelectedDayCard(
            date: selectedDay,
            status: statusLabel,
            color: statusColor),
        const SizedBox(height: 14),
        Opacity(
          opacity: canMark ? 1.0 : 0.3,
          child: Row(children: [
            Expanded(child: _StatusBtn(label: 'Lifted',    color: LiftdColors.lifted,
                icon: Icons.arrow_upward_rounded, onTap: () => _setStatus(GymStatus.lifted))),
            const SizedBox(width: 10),
            Expanded(child: _StatusBtn(label: 'Benched',   color: LiftdColors.benched,
                icon: Icons.close_rounded,        onTap: () => _setStatus(GymStatus.benched))),
            const SizedBox(width: 10),
            Expanded(child: _StatusBtn(label: 'Recovered', color: LiftdColors.recovered,
                icon: Icons.bedtime_outlined,     onTap: () => _setStatus(GymStatus.recovered))),
          ]),
        ),
        // Lock message — future or expired
        if (isFuture || isExpired) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                color: LiftdColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: (isExpired
                    ? LiftdColors.benched : LiftdColors.orange).withOpacity(0.25))),
            child: Row(children: [
              Icon(isExpired ? Icons.timer_off_rounded : Icons.lock_outline,
                  color: isExpired ? LiftdColors.benched : LiftdColors.orange,
                  size: 15),
              const SizedBox(width: 10),
              Expanded(child: Text(
                isExpired
                    ? '24-hour window has closed. You can no longer log this day.'
                    : 'Future days cannot be marked.',
                style: GoogleFonts.spaceMono(color: Colors.grey.shade500, fontSize: 11))),
            ]),
          ),
        ],
        const SizedBox(height: 16),
        _LegendCard(),
      ]),
    );
  }
}

class _SelectedDayCard extends StatelessWidget {
  final DateTime date; final String status; final Color color;
  const _SelectedDayCard({required this.date, required this.status, required this.color});
  @override
  Widget build(BuildContext context) {
    final safe = color == Colors.transparent ? Colors.grey.shade700 : color;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: LiftdColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.04))),
      child: Row(children: [
        Container(width: 10, height: 10,
            decoration: BoxDecoration(shape: BoxShape.circle, color: safe)),
        const SizedBox(width: 12),
        Text('${date.day}/${date.month}/${date.year}  •  $status',
            style: GoogleFonts.spaceMono(
                color: LiftdColors.cream, fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _LegendCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: LiftdColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.04))),
      child: const Column(children: [
        _LR(color: LiftdColors.lifted,    label: 'Lifted'),
        SizedBox(height: 10),
        _LR(color: LiftdColors.benched,   label: 'Benched'),
        SizedBox(height: 10),
        _LR(color: LiftdColors.recovered, label: 'Recovered'),
      ]),
    );
  }
}

class _LR extends StatelessWidget {
  final Color color; final String label;
  const _LR({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 10, height: 10,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
    const SizedBox(width: 10),
    Text(label, style: GoogleFonts.spaceMono(
        color: LiftdColors.cream, fontWeight: FontWeight.w700, fontSize: 12)),
  ]);
}

// ─── Score Row (used in rank sheet legend) ────────────────────────────────────
class _ScoreRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String pts;
  const _ScoreRow({required this.icon, required this.color,
      required this.label, required this.pts});

  @override
  Widget build(BuildContext context) {
    final isPositive = pts.startsWith('+');
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(
          width: 28, height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: GoogleFonts.spaceMono(
            color: Colors.grey.shade400, fontSize: 11))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: isPositive
                ? LiftdColors.lifted.withOpacity(0.12)
                : LiftdColors.benched.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(pts, style: GoogleFonts.spaceMono(
              color: isPositive ? LiftdColors.lifted : LiftdColors.benched,
              fontWeight: FontWeight.w700, fontSize: 11)),
        ),
      ]),
    );
  }
}


class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});
  @override State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  late Box fitBox;
  static const _days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];

  Map<String, List<Map<String, dynamic>>> weeklyPlan = {};
  List<Map<String, dynamic>> todayEx = [], missedEx = [];

  @override
  void initState() { super.initState(); fitBox = Hive.box(StorageKeys.boxName); _loadPlan(); _loadToday(); }

  Map<String, List<Map<String, dynamic>>> _defaultPlan() => {
    'Monday':   [{'name':'Bench Press','sets':'4','reps':'8'},{'name':'Incline DB','sets':'3','reps':'10'}],
    'Tuesday':  [{'name':'Pull Ups','sets':'4','reps':'8'},{'name':'Barbell Row','sets':'4','reps':'10'}],
    'Wednesday':[{'name':'Squats','sets':'4','reps':'8'},{'name':'Leg Press','sets':'3','reps':'12'}],
    'Thursday': [{'name':'Shoulder Press','sets':'4','reps':'8'},{'name':'Lateral Raise','sets':'3','reps':'12'}],
    'Friday':   [{'name':'Barbell Curl','sets':'4','reps':'10'},{'name':'Tricep Pushdown','sets':'3','reps':'12'}],
    'Saturday': [{'name':'Crunches','sets':'4','reps':'20'},{'name':'Plank','sets':'3','reps':'60s'}],
    'Sunday':   [],
  };

  void _loadPlan() {
    final s = fitBox.get(StorageKeys.weeklyPlan);
    if (s == null) { weeklyPlan = _defaultPlan(); _savePlan(); return; }
    final raw = Map<String, dynamic>.from(s);
    weeklyPlan = {};
    for (final d in _days) {
      weeklyPlan[d] = List<Map<String, dynamic>>.from(
          (raw[d] as List? ?? []).map((e) => Map<String, dynamic>.from(e)));
    }
  }

  void _savePlan() => fitBox.put(StorageKeys.weeklyPlan, weeklyPlan);
  String _todayName() => _days[DateTime.now().weekday - 1];
  String _wKey() { final n = DateTime.now(); return 'workout-${n.year}-${n.month}-${n.day}'; }

  void _loadToday({bool force = false}) {
    final s = force ? null : fitBox.get(_wKey());
    if (s != null) {
      final l = List<Map<String, dynamic>>.from((s as List).map((e) => Map<String, dynamic>.from(e)));
      setState(() {
        todayEx  = l.where((e) => e['status'] != ExerciseStatus.missed.name).toList();
        missedEx = l.where((e) => e['status'] == ExerciseStatus.missed.name).toList();
      });
      return;
    }
    final plan = weeklyPlan[_todayName()] ?? [];
    setState(() {
      todayEx  = plan.map((e) => {...e, 'status': ExerciseStatus.pending.name}).toList();
      missedEx = [];
    });
    _saveWkt();
  }

  void _saveWkt() => fitBox.put(_wKey(), [...todayEx, ...missedEx]);
  void _reset() { fitBox.delete(_wKey()); _loadToday(force: true); }

  void _markDone(int i) {
    setState(() {
      final e = todayEx[i];
      e['status'] = e['status'] == ExerciseStatus.done.name
          ? ExerciseStatus.pending.name : ExerciseStatus.done.name;
    });
    _saveWkt();
  }

  void _markMissed(int i) {
    final item = Map<String, dynamic>.from(todayEx[i]);
    setState(() {
      final e = todayEx.removeAt(i);
      e['status'] = ExerciseStatus.missed.name;
      missedEx.add(e);
    });
    _saveWkt();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        backgroundColor: LiftdColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: LiftdColors.benched.withOpacity(0.35))),
        content: Row(children: [
          const Icon(Icons.close_rounded, color: LiftdColors.benched, size: 16),
          const SizedBox(width: 8),
          Text('${item['name']} benched',
              style: GoogleFonts.spaceMono(
                  color: LiftdColors.cream, fontSize: 12)),
        ]),
        action: SnackBarAction(
          label: 'Undo',
          textColor: LiftdColors.orange,
          onPressed: () => _restore(Map<String, dynamic>.from(item), i),
        ),
      ));
  }

  void _restore(Map<String, dynamic> ex, [int? idx]) {
    setState(() {
      missedEx.removeWhere((e) => e['name'] == ex['name']);
      ex['status'] = ExerciseStatus.pending.name;
      if (idx != null && idx <= todayEx.length) {
        todayEx.insert(idx, ex);
      } else {
        todayEx.add(ex);
      }
    });
    _saveWkt();
  }

  int get _doneCount => todayEx.where((e) => e['status'] == ExerciseStatus.done.name).length;

  Future<void> _addOrEdit({required String day, Map<String, dynamic>? ex,
      int? idx, required VoidCallback refresh}) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ExerciseDialog(
        initialName: ex?['name'] ?? '',
        initialSets: ex?['sets'] ?? '',
        initialReps: ex?['reps'] ?? '',
      ),
    );
    if (result == null) return;
    final e2 = {'name': result['name']!, 'sets': result['sets']!, 'reps': result['reps']!};
    setState(() {
      weeklyPlan.putIfAbsent(day, () => []);
      if (idx != null) {
        weeklyPlan[day]![idx] = e2;
      } else {
        weeklyPlan[day]!.add(e2);
      }
      _savePlan(); if (day == _todayName()) _reset();
    });
    refresh();
  }

  // ─── Preset workout plans ────────────────────────────────────────────────────
  static const List<Map<String, dynamic>> _presetPlans = [
    {
      'name': 'Push / Pull / Legs',
      'tag': 'Hypertrophy',
      'color': 0xFF3B82F6,
      'icon': 'barbell',
      'desc': '6-day PPL split. Build size and strength with compound + isolation work.',
      'plan': {
        'Monday':   [{'name':'Bench Press','sets':'4','reps':'8'},{'name':'Incline DB Press','sets':'3','reps':'10'},{'name':'Cable Fly','sets':'3','reps':'12'},{'name':'Tricep Pushdown','sets':'3','reps':'12'}],
        'Tuesday':  [{'name':'Deadlift','sets':'4','reps':'6'},{'name':'Pull Ups','sets':'4','reps':'8'},{'name':'Seated Cable Row','sets':'3','reps':'10'},{'name':'Barbell Curl','sets':'3','reps':'12'}],
        'Wednesday':[{'name':'Squats','sets':'4','reps':'8'},{'name':'Leg Press','sets':'3','reps':'12'},{'name':'Leg Curl','sets':'3','reps':'12'},{'name':'Calf Raise','sets':'4','reps':'15'}],
        'Thursday': [{'name':'Overhead Press','sets':'4','reps':'8'},{'name':'DB Shoulder Press','sets':'3','reps':'10'},{'name':'Lateral Raise','sets':'3','reps':'15'},{'name':'Skull Crushers','sets':'3','reps':'12'}],
        'Friday':   [{'name':'Weighted Pull Ups','sets':'4','reps':'6'},{'name':'T-Bar Row','sets':'3','reps':'10'},{'name':'Face Pull','sets':'3','reps':'15'},{'name':'Hammer Curl','sets':'3','reps':'12'}],
        'Saturday': [{'name':'Front Squat','sets':'4','reps':'8'},{'name':'Romanian Deadlift','sets':'3','reps':'10'},{'name':'Lunges','sets':'3','reps':'12'},{'name':'Leg Extension','sets':'3','reps':'15'}],
        'Sunday':   [],
      },
    },
    {
      'name': 'Upper / Lower',
      'tag': 'Strength',
      'color': 0xFF22C55E,
      'icon': 'bolt',
      'desc': '4-day split focusing on progressive overload. Great for beginners to intermediate.',
      'plan': {
        'Monday':   [{'name':'Bench Press','sets':'4','reps':'5'},{'name':'Barbell Row','sets':'4','reps':'5'},{'name':'Overhead Press','sets':'3','reps':'8'},{'name':'Pull Ups','sets':'3','reps':'8'}],
        'Tuesday':  [{'name':'Squats','sets':'4','reps':'5'},{'name':'Romanian Deadlift','sets':'3','reps':'8'},{'name':'Leg Press','sets':'3','reps':'10'},{'name':'Calf Raise','sets':'4','reps':'15'}],
        'Wednesday':[],
        'Thursday': [{'name':'Incline Press','sets':'4','reps':'8'},{'name':'Seated Cable Row','sets':'4','reps':'8'},{'name':'DB Fly','sets':'3','reps':'12'},{'name':'Face Pull','sets':'3','reps':'15'}],
        'Friday':   [{'name':'Deadlift','sets':'4','reps':'5'},{'name':'Front Squat','sets':'3','reps':'8'},{'name':'Leg Curl','sets':'3','reps':'10'},{'name':'Leg Extension','sets':'3','reps':'12'}],
        'Saturday': [],
        'Sunday':   [],
      },
    },
    {
      'name': 'Full Body 3x',
      'tag': 'Beginner',
      'color': 0xFFEAB308,
      'icon': 'star',
      'desc': '3-day full body routine. Perfect for beginners building a solid foundation.',
      'plan': {
        'Monday':   [{'name':'Squat','sets':'3','reps':'8'},{'name':'Bench Press','sets':'3','reps':'8'},{'name':'Barbell Row','sets':'3','reps':'8'},{'name':'Plank','sets':'3','reps':'30s'}],
        'Tuesday':  [],
        'Wednesday':[{'name':'Deadlift','sets':'3','reps':'6'},{'name':'Overhead Press','sets':'3','reps':'8'},{'name':'Pull Ups','sets':'3','reps':'6'},{'name':'Crunches','sets':'3','reps':'15'}],
        'Thursday': [],
        'Friday':   [{'name':'Squat','sets':'3','reps':'10'},{'name':'Incline DB Press','sets':'3','reps':'10'},{'name':'Cable Row','sets':'3','reps':'10'},{'name':'Lateral Raise','sets':'3','reps':'12'}],
        'Saturday': [],
        'Sunday':   [],
      },
    },
    {
      'name': 'Bro Split',
      'tag': 'Classic',
      'color': 0xFFEC4899,
      'icon': 'fire',
      'desc': '5-day classic bodybuilder split. One muscle group per day, maximum pump.',
      'plan': {
        'Monday':   [{'name':'Barbell Curl','sets':'4','reps':'10'},{'name':'Hammer Curl','sets':'3','reps':'12'},{'name':'Concentration Curl','sets':'3','reps':'12'},{'name':'Cable Curl','sets':'3','reps':'15'}],
        'Tuesday':  [{'name':'Tricep Pushdown','sets':'4','reps':'10'},{'name':'Skull Crushers','sets':'3','reps':'10'},{'name':'Overhead Extension','sets':'3','reps':'12'},{'name':'Dips','sets':'3','reps':'12'}],
        'Wednesday':[{'name':'Bench Press','sets':'4','reps':'8'},{'name':'Incline DB Press','sets':'4','reps':'10'},{'name':'Cable Fly','sets':'3','reps':'12'},{'name':'Push Up','sets':'3','reps':'15'}],
        'Thursday': [{'name':'Barbell Row','sets':'4','reps':'8'},{'name':'Pull Ups','sets':'4','reps':'8'},{'name':'Lat Pulldown','sets':'3','reps':'10'},{'name':'Face Pull','sets':'3','reps':'15'}],
        'Friday':   [{'name':'Squat','sets':'4','reps':'8'},{'name':'Leg Press','sets':'4','reps':'10'},{'name':'Leg Curl','sets':'3','reps':'12'},{'name':'Calf Raise','sets':'4','reps':'20'}],
        'Saturday': [{'name':'Overhead Press','sets':'4','reps':'8'},{'name':'Lateral Raise','sets':'4','reps':'12'},{'name':'Front Raise','sets':'3','reps':'12'},{'name':'Shrugs','sets':'3','reps':'15'}],
        'Sunday':   [],
      },
    },
  ];

  // ─── Custom plans storage ────────────────────────────────────────────────────
  List<Map<String, dynamic>> _loadCustomPlans() {
    final raw = fitBox.get(StorageKeys.customPlans, defaultValue: []) as List;
    return List<Map<String, dynamic>>.from(raw.map((e) => Map<String, dynamic>.from(e)));
  }

  void _saveCustomPlans(List<Map<String, dynamic>> plans) {
    fitBox.put(StorageKeys.customPlans, plans);
  }

  void _deleteCustomPlan(int index) {
    final plans = _loadCustomPlans();
    plans.removeAt(index);
    _saveCustomPlans(plans);
    setState(() {});
  }

  // Opens the Plans picker sheet
  Future<void> _openPlans() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.65),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => StatefulBuilder(builder: (ctx, ss) {
        final customPlans = _loadCustomPlans();
        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx2, sc) => Container(
            decoration: const BoxDecoration(
              color: LiftdColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Workout Plans', style: GoogleFonts.spaceMono(
                        color: LiftdColors.cream, fontSize: 20, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Pick a plan or build your own.',
                        style: GoogleFonts.spaceMono(color: Colors.grey.shade500, fontSize: 11)),
                  ])),
                ]),
              ),
              const SizedBox(height: 14),
              Divider(color: Colors.white.withOpacity(0.06), height: 1),
              Expanded(
                child: ListView(
                  controller: sc,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    // ── Preset plan cards ──────────────────────────────────
                    if (_presetPlans.isNotEmpty) ...[
                      Text('PRESET PLANS', style: GoogleFonts.spaceMono(
                          color: Colors.grey.shade600, fontSize: 9, letterSpacing: 1.4)),
                      const SizedBox(height: 10),
                      ..._presetPlans.map((plan) {
                        final c = Color(plan['color'] as int);
                        return _PlanCard(
                          plan: plan,
                          accentColor: c,
                          onPreview: () => _previewPlan(ctx, plan, () => ss(() {})),
                        );
                      }),
                    ],
                    // ── My custom plans ────────────────────────────────────
                    if (customPlans.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('MY PLANS', style: GoogleFonts.spaceMono(
                          color: Colors.grey.shade600, fontSize: 9, letterSpacing: 1.4)),
                      const SizedBox(height: 10),
                      ...List.generate(customPlans.length, (i) {
                        final plan = customPlans[i];
                        const c = LiftdColors.orange;
                        return _PlanCard(
                          plan: plan,
                          accentColor: c,
                          onPreview: () => _previewPlan(ctx, plan, () => ss(() {})),
                          onDelete: () {
                            _deleteCustomPlan(i);
                            ss(() {});
                          },
                        );
                      }),
                    ],
                    const SizedBox(height: 8),
                    // ── Create custom plan card ────────────────────────────
                    Text('CREATE', style: GoogleFonts.spaceMono(
                        color: Colors.grey.shade600, fontSize: 9, letterSpacing: 1.4)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _openCustomPlanBuilder();
                        // Re-open plans after builder closes so they see the new plan
                        if (mounted) _openPlans();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: LiftdColors.card,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color: LiftdColors.orange.withOpacity(0.45), width: 1.5),
                        ),
                        child: Row(children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: LiftdColors.orange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: LiftdColors.orange.withOpacity(0.35)),
                            ),
                            child: const Icon(Icons.add_rounded,
                                color: LiftdColors.orange, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Create Custom Plan', style: GoogleFonts.spaceMono(
                                color: LiftdColors.cream, fontSize: 14, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            Text('Name it, build it day by day, save it.',
                                style: GoogleFonts.spaceMono(
                                    color: Colors.grey.shade500, fontSize: 11)),
                          ])),
                          Icon(Icons.chevron_right_rounded,
                              color: LiftdColors.orange.withOpacity(0.6), size: 20),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ]),
          ),
        );
      }),
    );
  }

  // ─── Custom plan builder (name + exercises per day, then save) ───────────────
  Future<void> _openCustomPlanBuilder() async {
    String planName = '';
    String selDay = _todayName();
    // Build a fresh empty plan map
    final Map<String, List<Map<String, dynamic>>> draftPlan = {
      for (final d in _days) d: [],
    };
    bool saved = false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.65),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.6,
        maxChildSize: 0.97,
        expand: false,
        builder: (ctx, sc) => StatefulBuilder(builder: (ctx, ss) {
          final nameCtrl = TextEditingController(text: planName);
          return Container(
            decoration: const BoxDecoration(
              color: LiftdColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('New Custom Plan', style: GoogleFonts.spaceMono(
                      color: LiftdColors.cream, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Build your weekly plan and save it.',
                      style: GoogleFonts.spaceMono(color: Colors.grey.shade500, fontSize: 11)),
                  const SizedBox(height: 14),
                  // Plan name input
                  TextField(
                    controller: nameCtrl,
                    onChanged: (v) => planName = v,
                    style: GoogleFonts.spaceMono(color: LiftdColors.cream, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Plan name (e.g. "My PPL")',
                      hintStyle: GoogleFonts.spaceMono(color: Colors.grey.shade600, fontSize: 12),
                      prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded,
                          color: LiftdColors.orange, size: 18),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              Divider(color: Colors.white.withOpacity(0.06), height: 1),
              Expanded(
                child: ListView(
                  controller: sc,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  children: [
                    // Day selector
                    Wrap(spacing: 8, runSpacing: 8,
                        children: _days.map((d) {
                          final hasEx = draftPlan[d]!.isNotEmpty;
                          return GestureDetector(
                            onTap: () => ss(() => selDay = d),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: selDay == d
                                    ? LiftdColors.orange.withOpacity(0.14)
                                    : LiftdColors.card,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                    color: selDay == d
                                        ? LiftdColors.orange
                                        : hasEx
                                            ? LiftdColors.lifted.withOpacity(0.5)
                                            : Colors.white.withOpacity(0.06)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                if (hasEx) ...[
                                  Container(width: 6, height: 6,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: selDay == d
                                              ? LiftdColors.orange
                                              : LiftdColors.lifted)),
                                  const SizedBox(width: 5),
                                ],
                                Text(d.substring(0, 3), style: GoogleFonts.spaceMono(
                                    color: selDay == d ? LiftdColors.orange : LiftdColors.cream,
                                    fontWeight: FontWeight.w700, fontSize: 11)),
                              ]),
                            ),
                          );
                        }).toList()),
                    const SizedBox(height: 16),
                    // Current day exercises
                    Row(children: [
                      Expanded(child: Text(selDay, style: GoogleFonts.spaceMono(
                          color: LiftdColors.cream, fontSize: 15, fontWeight: FontWeight.w700))),
                      TextButton.icon(
                        onPressed: () async {
                          await _addOrEditDraft(
                            ctx: ctx,
                            day: selDay,
                            draftPlan: draftPlan,
                            refresh: () => ss(() {}),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, color: LiftdColors.orange, size: 18),
                        label: Text('Add', style: GoogleFonts.spaceMono(
                            color: LiftdColors.orange, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    if (draftPlan[selDay]!.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: LiftdColors.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.05))),
                        child: Text('No exercises for $selDay. Tap Add.',
                            style: GoogleFonts.spaceMono(
                                color: Colors.grey.shade600, fontSize: 11)),
                      )
                    else
                      ...List.generate(draftPlan[selDay]!.length, (i) {
                        final ex = draftPlan[selDay]![i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(color: LiftdColors.card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.05))),
                          child: Row(children: [
                            Expanded(child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(ex['name'], style: GoogleFonts.spaceMono(
                                  color: LiftdColors.cream, fontWeight: FontWeight.w700, fontSize: 12)),
                              Text('${ex['sets']} sets × ${ex['reps']} reps',
                                  style: GoogleFonts.spaceMono(
                                      color: Colors.grey.shade500, fontSize: 10)),
                            ])),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                await _addOrEditDraft(
                                  ctx: ctx, day: selDay, draftPlan: draftPlan,
                                  existingEx: ex, index: i,
                                  refresh: () => ss(() {}),
                                );
                              },
                              icon: const Icon(Icons.edit_outlined,
                                  color: LiftdColors.blue, size: 16),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => ss(() => draftPlan[selDay]!.removeAt(i)),
                              icon: const Icon(Icons.delete_outline,
                                  color: LiftdColors.benched, size: 16),
                            ),
                          ]),
                        );
                      }),
                  ],
                ),
              ),
              // Save / Cancel bar
              Container(
                color: LiftdColors.surface,
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Row(children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Center(child: Text('Cancel',
                            style: GoogleFonts.spaceMono(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w700, fontSize: 13))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        final name = planName.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(SnackBar(
                              duration: const Duration(seconds: 2),
                              content: Text('Give your plan a name first.',
                                  style: GoogleFonts.spaceMono(
                                      color: LiftdColors.cream, fontSize: 12)),
                            ));
                          return;
                        }
                        // Build a serialisable copy of the draft
                        final planMap = <String, dynamic>{};
                        for (final d in _days) {
                          planMap[d] = draftPlan[d]!
                              .map((e) => Map<String, dynamic>.from(e))
                              .toList();
                        }
                        final totalEx = draftPlan.values
                            .fold<int>(0, (s, v) => s + v.length);
                        final newPlan = {
                          'name': name,
                          'tag': 'Custom',
                          'color': LiftdColors.orange.value,
                          'icon': 'custom',
                          'desc': '$totalEx exercises across the week.',
                          'plan': planMap,
                        };
                        final plans = _loadCustomPlans();
                        plans.add(newPlan);
                        _saveCustomPlans(plans);
                        saved = true;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(SnackBar(
                            duration: const Duration(seconds: 2),
                            content: Row(children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  color: LiftdColors.lifted, size: 16),
                              const SizedBox(width: 8),
                              Text('"$name" saved!',
                                  style: GoogleFonts.spaceMono(
                                      color: LiftdColors.cream, fontSize: 12)),
                            ]),
                          ));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: LiftdColors.orange.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: LiftdColors.orange.withOpacity(0.6)),
                        ),
                        child: Center(child: Text('Save Plan',
                            style: GoogleFonts.spaceMono(
                                color: LiftdColors.orange,
                                fontWeight: FontWeight.w700, fontSize: 13))),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          );
        }),
      ),
    );
  }

  // Helper: add or edit an exercise inside the custom plan builder draft
  Future<void> _addOrEditDraft({
    required BuildContext ctx,
    required String day,
    required Map<String, List<Map<String, dynamic>>> draftPlan,
    Map<String, dynamic>? existingEx,
    int? index,
    required VoidCallback refresh,
  }) async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ExerciseDialog(
        initialName: existingEx?['name'] ?? '',
        initialSets: existingEx?['sets'] ?? '',
        initialReps: existingEx?['reps'] ?? '',
      ),
    );
    if (result == null) return;
    final ex = {'name': result['name']!, 'sets': result['sets']!, 'reps': result['reps']!};
    if (index != null) {
      draftPlan[day]![index] = ex;
    } else {
      draftPlan[day]!.add(ex);
    }
    refresh();
  }

  // Preview a preset or custom plan before applying
  Future<void> _previewPlan(BuildContext parentCtx, Map<String, dynamic> plan,
      [VoidCallback? onApplied]) async {
    Navigator.pop(parentCtx); // close plans sheet
    final planData = Map<String, dynamic>.from(plan['plan'] as Map);
    final c = Color(plan['color'] as int);
    bool applied = false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.65),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, sc) => Container(
          decoration: const BoxDecoration(
            color: LiftdColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.withOpacity(0.4)),
                  ),
                  child: Icon(_planIcon(plan['icon'] as String), color: c, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(plan['name'] as String, style: GoogleFonts.spaceMono(
                      color: LiftdColors.cream, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(plan['desc'] as String,
                      style: GoogleFonts.spaceMono(color: Colors.grey.shade500, fontSize: 10),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ])),
              ]),
            ),
            const SizedBox(height: 14),
            Divider(color: Colors.white.withOpacity(0.06), height: 1),
            Expanded(
              child: ListView.builder(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                itemCount: _days.length,
                itemBuilder: (_, i) {
                  final day = _days[i];
                  final exs = List<Map<String, dynamic>>.from(
                      (planData[day] as List? ?? []).map((e) => Map<String, dynamic>.from(e)));
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, top: 4),
                      child: Row(children: [
                        Container(width: 6, height: 6,
                            decoration: BoxDecoration(shape: BoxShape.circle,
                                color: exs.isEmpty ? Colors.grey.shade700 : c)),
                        const SizedBox(width: 8),
                        Text(day, style: GoogleFonts.spaceMono(
                            color: exs.isEmpty ? Colors.grey.shade700 : LiftdColors.cream,
                            fontWeight: FontWeight.w700, fontSize: 12)),
                        const SizedBox(width: 6),
                        if (exs.isEmpty)
                          Text('— Rest', style: GoogleFonts.spaceMono(
                              color: Colors.grey.shade700, fontSize: 10)),
                      ]),
                    ),
                    if (exs.isNotEmpty) ...[
                      ...exs.map((ex) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                            color: LiftdColors.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.05))),
                        child: Row(children: [
                          Expanded(child: Text(ex['name'] as String,
                              style: GoogleFonts.spaceMono(
                                  color: LiftdColors.cream, fontWeight: FontWeight.w700, fontSize: 12))),
                          Text('${ex['sets']}×${ex['reps']}',
                              style: GoogleFonts.spaceMono(
                                  color: Colors.grey.shade500, fontSize: 11)),
                        ]),
                      )),
                      const SizedBox(height: 6),
                    ],
                  ]);
                },
              ),
            ),
            // Apply / Discard buttons
            Container(
              color: LiftdColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Row(children: [
                // Discard
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Center(child: Text('Discard',
                          style: GoogleFonts.spaceMono(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w700, fontSize: 13))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Apply
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      applied = true;
                      // Deep-copy the plan into weeklyPlan
                      for (final d in _days) {
                        weeklyPlan[d] = List<Map<String, dynamic>>.from(
                            (planData[d] as List? ?? []).map((e) => Map<String, dynamic>.from(e)));
                      }
                      _savePlan();
                      _reset();
                      setState(() {});
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                          duration: const Duration(seconds: 2),
                          content: Row(children: [
                            const Icon(Icons.check_circle_outline_rounded,
                                color: LiftdColors.lifted, size: 16),
                            const SizedBox(width: 8),
                            Text('${plan['name']} applied!',
                                style: GoogleFonts.spaceMono(
                                    color: LiftdColors.cream, fontSize: 12)),
                          ]),
                        ));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: c.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.withOpacity(0.55)),
                      ),
                      child: Center(child: Text('Apply Plan',
                          style: GoogleFonts.spaceMono(
                              color: c, fontWeight: FontWeight.w700, fontSize: 13))),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
    if (!applied) {
      // Re-open plans sheet if discarded
      // (user tapped discard, do nothing — they can re-open from the Plans button)
    }
  }

  IconData _planIcon(String key) {
    switch (key) {
      case 'bolt':    return Icons.bolt_rounded;
      case 'star':    return Icons.star_rounded;
      case 'fire':    return Icons.local_fire_department_rounded;
      case 'custom':  return Icons.tune_rounded;
      default:        return Icons.fitness_center_rounded;
    }
  }

  // ─── Pick a day's workout from any plan ──────────────────────────────────────
  Future<void> _openDayPicker() async {
    // Combine presets + custom plans
    final allPlans = [
      ..._presetPlans,
      ..._loadCustomPlans(),
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.65),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, sc) => Container(
          decoration: const BoxDecoration(
            color: LiftdColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pick a Workout', style: GoogleFonts.spaceMono(
                    color: LiftdColors.cream, fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Choose a plan, then pick the day you want to do.',
                    style: GoogleFonts.spaceMono(color: Colors.grey.shade500, fontSize: 11)),
              ]),
            ),
            const SizedBox(height: 14),
            Divider(color: Colors.white.withOpacity(0.06), height: 1),
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: allPlans.map((plan) {
                  final c = Color(plan['color'] as int);
                  final planMap = plan['plan'] as Map;
                  final activeDays = planMap.entries
                      .where((e) => (e.value as List?)?.isNotEmpty == true)
                      .length;

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _openDaySelector(plan);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: LiftdColors.card,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: c.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: c.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: c.withOpacity(0.35)),
                          ),
                          child: Icon(_planIcon(plan['icon'] as String), color: c, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(plan['name'] as String, style: GoogleFonts.spaceMono(
                              color: LiftdColors.cream, fontSize: 14,
                              fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('$activeDays workout days',
                              style: GoogleFonts.spaceMono(
                                  color: Colors.grey.shade500, fontSize: 11)),
                        ])),
                        Icon(Icons.chevron_right_rounded,
                            color: c.withOpacity(0.6), size: 20),
                      ]),
                    ),
                  );
                }).toList(),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // Shows all days of a plan as selectable cards
  Future<void> _openDaySelector(Map<String, dynamic> plan) async {
    final c       = Color(plan['color'] as int);
    final planMap = Map<String, dynamic>.from(plan['plan'] as Map);

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.65),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, sc) => Container(
          decoration: const BoxDecoration(
            color: LiftdColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 12),
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: c.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.withOpacity(0.35)),
                  ),
                  child: Icon(_planIcon(plan['icon'] as String), color: c, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(plan['name'] as String, style: GoogleFonts.spaceMono(
                      color: LiftdColors.cream, fontSize: 18, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  Text('Select a day to load its workout',
                      style: GoogleFonts.spaceMono(
                          color: Colors.grey.shade500, fontSize: 10)),
                ])),
              ]),
            ),
            const SizedBox(height: 14),
            Divider(color: Colors.white.withOpacity(0.06), height: 1),
            Expanded(
              child: ListView.builder(
                controller: sc,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                itemCount: _days.length,
                itemBuilder: (_, i) {
                  final day = _days[i];
                  final exs = List<Map<String, dynamic>>.from(
                      (planMap[day] as List? ?? [])
                          .map((e) => Map<String, dynamic>.from(e)));
                  final isRest = exs.isEmpty;

                  return GestureDetector(
                    onTap: isRest ? null : () {
                      Navigator.pop(ctx);
                      _loadDayWorkout(day, exs, plan['name'] as String);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isRest
                            ? LiftdColors.card.withOpacity(0.5)
                            : LiftdColors.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isRest
                              ? Colors.white.withOpacity(0.04)
                              : c.withOpacity(0.35),
                          width: 1.2,
                        ),
                      ),
                      child: Row(children: [
                        // Day badge
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: isRest
                                ? Colors.white.withOpacity(0.04)
                                : c.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: isRest
                                    ? Colors.white.withOpacity(0.06)
                                    : c.withOpacity(0.35)),
                          ),
                          child: Center(child: Text(
                            day.substring(0, 3).toUpperCase(),
                            style: GoogleFonts.spaceMono(
                                color: isRest ? Colors.grey.shade700 : c,
                                fontWeight: FontWeight.w700, fontSize: 11),
                          )),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(day, style: GoogleFonts.spaceMono(
                              color: isRest ? Colors.grey.shade600 : LiftdColors.cream,
                              fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 4),
                          if (isRest)
                            Text('Rest day', style: GoogleFonts.spaceMono(
                                color: Colors.grey.shade700, fontSize: 11))
                          else ...[
                            Text('${exs.length} exercise${exs.length > 1 ? 's' : ''}',
                                style: GoogleFonts.spaceMono(
                                    color: Colors.grey.shade500, fontSize: 11)),
                            const SizedBox(height: 6),
                            // Exercise name previews
                            Builder(builder: (_) {
                              final pills = <Widget>[
                                ...exs.take(3).map((ex) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: c.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(ex['name'] as String,
                                      style: GoogleFonts.spaceMono(
                                          color: c, fontSize: 9,
                                          fontWeight: FontWeight.w700)),
                                )),
                                if (exs.length > 3)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text('+${exs.length - 3} more',
                                        style: GoogleFonts.spaceMono(
                                            color: Colors.grey.shade500,
                                            fontSize: 9)),
                                  ),
                              ];
                              return Wrap(spacing: 6, runSpacing: 4, children: pills);
                            }),
                          ],
                        ])),
                        if (!isRest)
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: c.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.play_arrow_rounded, color: c, size: 18),
                          ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // Load a selected day's exercises into today's session
  void _loadDayWorkout(String day, List<Map<String, dynamic>> exercises,
      String planName) {
    setState(() {
      todayEx = exercises
          .map((e) => {...Map<String, dynamic>.from(e),
              'status': ExerciseStatus.pending.name})
          .toList();
      missedEx = [];
    });
    _saveWkt();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 2),
        content: Row(children: [
          const Icon(Icons.fitness_center_rounded,
              color: LiftdColors.lifted, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(
              '$planName · $day loaded!',
              style: GoogleFonts.spaceMono(
                  color: LiftdColors.cream, fontSize: 12))),
        ]),
      ));
  }

  Future<void> _openEditor() async {
    String selDay = _todayName();
    await showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.65),
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx2, sc) => StatefulBuilder(builder: (ctx2, ss) {
          void refresh() => ss(() {});
          final exs = weeklyPlan[selDay] ?? [];
          return Container(
            decoration: const BoxDecoration(
              color: LiftdColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 12),
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Edit Weekly Plan', style: GoogleFonts.spaceMono(
                      color: LiftdColors.cream, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Add, edit or remove exercises per day.',
                      style: GoogleFonts.spaceMono(color: Colors.grey.shade500, fontSize: 11)),
                ]),
              ),
              const SizedBox(height: 14),
              Divider(color: Colors.white.withOpacity(0.06), height: 1),
              Expanded(
                child: ListView(
                  controller: sc,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  children: [
                    Wrap(spacing: 8, runSpacing: 8,
                        children: _days.map((d) => _DayPill(label: d, selected: selDay == d,
                            onTap: () => ss(() => selDay = d))).toList()),
                    const SizedBox(height: 18),
                    Row(children: [
                      Expanded(child: Text(selDay, style: GoogleFonts.spaceMono(
                          color: LiftdColors.cream, fontSize: 16, fontWeight: FontWeight.w700))),
                      IconButton(onPressed: () => _addOrEdit(day: selDay, refresh: refresh),
                          icon: const Icon(Icons.add_rounded, color: LiftdColors.orange)),
                    ]),
                    const SizedBox(height: 8),
                    if (exs.isEmpty)
                      Container(padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: LiftdColors.card,
                              borderRadius: BorderRadius.circular(16)),
                          child: Text('No exercises for $selDay.',
                              style: GoogleFonts.spaceMono(color: Colors.grey.shade500, fontSize: 11)))
                    else
                      ...List.generate(exs.length, (i) {
                        final e2 = exs[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: LiftdColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withOpacity(0.05))),
                          child: Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(e2['name'], style: GoogleFonts.spaceMono(
                                  color: LiftdColors.cream, fontWeight: FontWeight.w700, fontSize: 12)),
                              Text('${e2['sets']}×${e2['reps']}', style: GoogleFonts.spaceMono(
                                  color: Colors.grey.shade500, fontSize: 10)),
                            ])),
                            IconButton(onPressed: () => _addOrEdit(day: selDay, ex: e2, idx: i, refresh: refresh),
                                icon: const Icon(Icons.edit_outlined, color: LiftdColors.blue, size: 18)),
                            IconButton(onPressed: () {
                              setState(() { weeklyPlan[selDay]!.removeAt(i); _savePlan();
                                if (selDay == _todayName()) _reset(); }); refresh();
                            }, icon: const Icon(Icons.delete_outline, color: LiftdColors.benched, size: 18)),
                          ]),
                        );
                      }),
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity,
                        child: FilledButton(
                            onPressed: () => Navigator.pop(ctx2),
                            child: const Text('Done'))),
                  ],
                ),
              ),
            ]),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRest = todayEx.isEmpty && missedEx.isEmpty;
    return AppPage(
      title: 'Workout',
      subtitle: '${_todayName()} • $_doneCount/${todayEx.length} done',
      actions: [
        IconButton(onPressed: _openDayPicker,
            icon: const Icon(Icons.style_rounded, color: LiftdColors.orange)),
        IconButton(onPressed: _openPlans,
            icon: const Icon(Icons.library_books_outlined, color: LiftdColors.cream)),
        IconButton(onPressed: _openEditor,
            icon: const Icon(Icons.edit_note_rounded, color: LiftdColors.cream)),
        IconButton(onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded, color: LiftdColors.cream)),
      ],
      child: ListView(children: [
        // Pick Workout banner — always visible at top
        GestureDetector(
          onTap: _openDayPicker,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: LiftdColors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: LiftdColors.orange.withOpacity(0.35)),
            ),
            child: Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: LiftdColors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.style_rounded,
                    color: LiftdColors.orange, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pick a Workout', style: GoogleFonts.spaceMono(
                    color: LiftdColors.orange, fontWeight: FontWeight.w700,
                    fontSize: 13)),
                Text('Load any day from your saved plans',
                    style: GoogleFonts.spaceMono(
                        color: Colors.grey.shade500, fontSize: 10)),
              ])),
              Icon(Icons.chevron_right_rounded,
                  color: LiftdColors.orange.withOpacity(0.6), size: 18),
            ]),
          ),
        ),

        if (isRest)
          Container(padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: LiftdColors.card,
                  borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                Icon(Icons.fitness_center_outlined,
                    color: Colors.grey.shade700, size: 32),
                const SizedBox(height: 10),
                Text('No workout for today.',
                    style: GoogleFonts.spaceMono(
                        color: LiftdColors.cream, fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Tap "Pick a Workout" above to load any plan\'s day.',
                    style: GoogleFonts.spaceMono(
                        color: Colors.grey.shade500, fontSize: 11),
                    textAlign: TextAlign.center),
              ]))
        else ...[
          const _SectionTitle(title: "Today's Exercises"),
          const SizedBox(height: 12),
          ...List.generate(todayEx.length, (i) {
            final ex = todayEx[i];
            return Padding(padding: const EdgeInsets.only(bottom: 12),
              child: Dismissible(
                key: ValueKey('${ex['name']}-$i'),
                direction: DismissDirection.endToStart,
                background: Container(
                    decoration: BoxDecoration(color: LiftdColors.benched.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(18)),
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Icon(Icons.close_rounded, color: LiftdColors.benched)),
                onDismissed: (_) => _markMissed(i),
                child: _ExCard(name: ex['name'], sets: ex['sets'],
                    reps: ex['reps'], status: ex['status'], onTap: () => _markDone(i)),
              ),
            );
          }),
          const SizedBox(height: 18),
          const _SectionTitle(title: 'Benched Exercises'),
          const SizedBox(height: 12),
          if (missedEx.isEmpty)
            Container(padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: LiftdColors.card, borderRadius: BorderRadius.circular(18)),
                child: Text('None benched today.', style: GoogleFonts.spaceMono(
                    color: Colors.grey.shade500, fontSize: 12)))
          else
            ...missedEx.map((ex) => Padding(padding: const EdgeInsets.only(bottom: 12),
              child: _ExCard(name: ex['name'], sets: ex['sets'],
                  reps: ex['reps'], status: ex['status'],
                  onTap: () => _restore(Map<String, dynamic>.from(ex))))),
        ],
      ]),
    );
  }
}

class _ExCard extends StatefulWidget {
  final String name, sets, reps, status;
  final VoidCallback? onTap;
  const _ExCard({required this.name, required this.sets, required this.reps,
      required this.status, required this.onTap});
  @override State<_ExCard> createState() => _ExCardState();
}
class _ExCardState extends State<_ExCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 130));
    _s = Tween<double>(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeIn));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDone   = widget.status == ExerciseStatus.done.name;
    final isMissed = widget.status == ExerciseStatus.missed.name;
    Color bd = Colors.white.withOpacity(0.06), bg = LiftdColors.card, ic = Colors.white;
    if (isDone)   { bd = LiftdColors.lifted;  bg = LiftdColors.lifted.withOpacity(0.1);  ic = LiftdColors.lifted; }
    if (isMissed) { bd = LiftdColors.benched; bg = LiftdColors.benched.withOpacity(0.1); ic = LiftdColors.benched; }

    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap?.call(); },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(scale: _s,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: bd, width: 1.2)),
          child: Row(children: [
            AnimatedContainer(duration: const Duration(milliseconds: 280),
              width: 40, height: 40,
              decoration: BoxDecoration(color: ic.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(isDone ? Icons.check_rounded
                  : isMissed ? Icons.close_rounded : Icons.fitness_center_rounded,
                  color: ic, size: 18)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.name, style: GoogleFonts.spaceMono(
                  color: LiftdColors.cream, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('${widget.sets} sets • ${widget.reps} reps', style: GoogleFonts.spaceMono(
                  color: Colors.grey.shade500, fontSize: 11)),
            ])),
            Text(isDone ? 'Done' : isMissed ? 'Restore' : 'Tap',
                style: GoogleFonts.spaceMono(color: ic, fontWeight: FontWeight.w700, fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}

class _DayPill extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _DayPill({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? LiftdColors.orange.withOpacity(0.14) : LiftdColors.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: selected ? LiftdColors.orange : Colors.white.withOpacity(0.06)),
      ),
      child: Text(label, style: GoogleFonts.spaceMono(
          color: selected ? LiftdColors.orange : LiftdColors.cream,
          fontWeight: FontWeight.w700, fontSize: 11)),
    ),
  );
}

// ─── Plan Card (used in plans picker sheet) ───────────────────────────────────
class _PlanCard extends StatefulWidget {
  final Map<String, dynamic> plan;
  final Color accentColor;
  final VoidCallback onPreview;
  final VoidCallback? onDelete;
  const _PlanCard({required this.plan, required this.accentColor,
      required this.onPreview, this.onDelete});
  @override State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 140));
    _s = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeIn));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  IconData get _icon {
    switch (widget.plan['icon'] as String) {
      case 'bolt':   return Icons.bolt_rounded;
      case 'star':   return Icons.star_rounded;
      case 'fire':   return Icons.local_fire_department_rounded;
      case 'custom': return Icons.tune_rounded;
      default:       return Icons.fitness_center_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.accentColor;
    final planMap = widget.plan['plan'] as Map;
    final totalExs = planMap.values.fold<int>(0, (s, v) => s + ((v as List?)?.length ?? 0));
    final activeDays = planMap.values.where((v) => (v as List?)?.isNotEmpty == true).length;
    final isCustom = widget.onDelete != null;

    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onPreview(); },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _s,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: LiftdColors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: c.withOpacity(0.3)),
            boxShadow: [BoxShadow(color: c.withOpacity(0.08), blurRadius: 16, spreadRadius: -4)],
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: c.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.withOpacity(0.35)),
              ),
              child: Icon(_icon, color: c, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(widget.plan['name'] as String,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceMono(
                          color: LiftdColors.cream, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: c.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text(widget.plan['tag'] as String,
                      style: GoogleFonts.spaceMono(
                          color: c, fontSize: 9, fontWeight: FontWeight.w700)),
                ),
              ]),
              const SizedBox(height: 4),
              Text(widget.plan['desc'] as String,
                  style: GoogleFonts.spaceMono(color: Colors.grey.shade500, fontSize: 10),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.calendar_today_outlined, color: Colors.grey.shade600, size: 11),
                const SizedBox(width: 4),
                Text('$activeDays days/week',
                    style: GoogleFonts.spaceMono(color: Colors.grey.shade600, fontSize: 10)),
                const SizedBox(width: 12),
                Icon(Icons.fitness_center_rounded, color: Colors.grey.shade600, size: 11),
                const SizedBox(width: 4),
                Text('$totalExs exercises',
                    style: GoogleFonts.spaceMono(color: Colors.grey.shade600, fontSize: 10)),
              ]),
            ])),
            const SizedBox(width: 8),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.chevron_right_rounded, color: c.withOpacity(0.5), size: 20),
              if (isCustom) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    // Swallow tap so it doesn't trigger onPreview
                    widget.onDelete?.call();
                  },
                  child: Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                        color: LiftdColors.benched.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: LiftdColors.benched.withOpacity(0.3))),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: LiftdColors.benched, size: 14),
                  ),
                ),
              ],
            ]),
          ]),
        ),
      ),
    );
  }
}


// ─── Exercise Database ────────────────────────────────────────────────────────
const List<String> kExerciseDatabase = [
  // Chest
  'Bench Press', 'Incline Bench Press', 'Decline Bench Press',
  'Dumbbell Chest Press', 'Incline Dumbbell Press', 'Decline Dumbbell Press',
  'Dumbbell Fly', 'Incline Dumbbell Fly', 'Cable Fly', 'Cable Crossover',
  'Pec Deck Machine', 'Push Up', 'Wide Push Up', 'Diamond Push Up',
  'Chest Dip', 'Landmine Press', 'Machine Chest Press',
  // Back
  'Deadlift', 'Romanian Deadlift', 'Sumo Deadlift', 'Stiff Leg Deadlift',
  'Pull Ups', 'Chin Ups', 'Weighted Pull Ups', 'Lat Pulldown',
  'Barbell Row', 'Dumbbell Row', 'Seated Cable Row', 'T-Bar Row',
  'Pendlay Row', 'Face Pull', 'Shrugs', 'Rack Pull', 'Hyperextension',
  'Good Morning', 'Cable Row', 'Machine Row', 'Reverse Fly',
  // Shoulders
  'Overhead Press', 'Barbell Overhead Press', 'Dumbbell Shoulder Press',
  'Arnold Press', 'Seated Dumbbell Press', 'Lateral Raise',
  'Front Raise', 'Rear Delt Fly', 'Upright Row', 'Cable Lateral Raise',
  'Machine Shoulder Press', 'Machine Lateral Raise', 'Face Pull',
  // Biceps
  'Barbell Curl', 'Dumbbell Curl', 'Hammer Curl', 'Concentration Curl',
  'Incline Dumbbell Curl', 'Cable Curl', 'EZ Bar Curl', 'Preacher Curl',
  'Reverse Curl', 'Zottman Curl', 'Spider Curl', '21s',
  // Triceps
  'Tricep Pushdown', 'Overhead Tricep Extension', 'Skull Crushers',
  'Close Grip Bench Press', 'Tricep Dip', 'Diamond Push Up',
  'Cable Overhead Tricep Extension', 'Kickback', 'JM Press',
  // Legs - Quads
  'Squat', 'Back Squat', 'Front Squat', 'Goblet Squat', 'Hack Squat',
  'Leg Press', 'Leg Extension', 'Bulgarian Split Squat', 'Lunges',
  'Walking Lunges', 'Step Ups', 'Wall Sit', 'Sissy Squat',
  // Legs - Hamstrings & Glutes
  'Leg Curl', 'Lying Leg Curl', 'Seated Leg Curl', 'Nordic Curl',
  'Hip Thrust', 'Glute Bridge', 'Cable Kickback', 'Donkey Kick',
  // Legs - Calves
  'Calf Raise', 'Standing Calf Raise', 'Seated Calf Raise',
  'Leg Press Calf Raise', 'Donkey Calf Raise',
  // Core / Abs
  'Crunch', 'Crunches', 'Sit Up', 'Plank', 'Side Plank',
  'Leg Raise', 'Hanging Leg Raise', 'Cable Crunch', 'Ab Wheel',
  'Russian Twist', 'Mountain Climber', 'Bicycle Crunch', 'Toe Touch',
  'Flutter Kick', 'Hollow Hold', 'Dead Bug', 'Dragon Flag',
  // Cardio / Full Body
  'Burpee', 'Jump Squat', 'Box Jump', 'Battle Ropes', 'Kettlebell Swing',
  'Clean and Press', 'Snatch', 'Thruster', 'Turkish Get Up',
  'Farmer Walk', 'Sled Push', 'Jump Rope', 'Rowing Machine',
  'Treadmill', 'Cycling', 'Elliptical',
];

// ─── Exercise Add/Edit — Bottom Sheet (no Dialog overflow issues) ─────────────
class _ExerciseDialog extends StatefulWidget {
  final String initialName, initialSets, initialReps;
  const _ExerciseDialog({
    this.initialName = '', this.initialSets = '', this.initialReps = '',
  });
  @override State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog>
    with WidgetsBindingObserver {
  late TextEditingController _nameCtrl, _setsCtrl, _repsCtrl;

  final _suggestions = ValueNotifier<List<String>>([]);
  final _nameError   = ValueNotifier<String>('');
  final _setsError   = ValueNotifier<String>('');
  final _repsError   = ValueNotifier<String>('');
  final _keyboardHeight = ValueNotifier<double>(0);

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _nameCtrl = TextEditingController(text: widget.initialName);
    _setsCtrl = TextEditingController(text: widget.initialSets);
    _repsCtrl = TextEditingController(text: widget.initialReps);
  }

  // Called by Flutter when keyboard height changes — outside build()
  @override
  void didChangeMetrics() {
    final bottom = WidgetsBinding
        .instance.platformDispatcher.views.first.viewInsets.bottom /
        WidgetsBinding
            .instance.platformDispatcher.views.first.devicePixelRatio;
    _keyboardHeight.value = bottom;
  }

  void _onNameChanged(String value) {
    _debounce?.cancel();
    final q = value.trim().toLowerCase();
    if (q.isEmpty) { _suggestions.value = []; return; }
    _debounce = Timer(const Duration(milliseconds: 200), () {
      final starts = <String>[], contains = <String>[];
      for (final e in kExerciseDatabase) {
        final l = e.toLowerCase();
        if (l.startsWith(q)) {
          starts.add(e);
        } else if (l.contains(q)) contains.add(e);
        if (starts.length + contains.length >= 8) break;
      }
      _suggestions.value = [...starts, ...contains].take(5).toList();
    });
  }

  void _pickSuggestion(String name) {
    _debounce?.cancel();
    _nameCtrl.text = name;
    _nameCtrl.selection =
        TextSelection.fromPosition(TextPosition(offset: name.length));
    _suggestions.value = [];
    _nameError.value = '';
  }

  bool _validate() {
    _nameError.value = '';
    _setsError.value = '';
    _repsError.value = '';
    bool ok = true;
    final name = _nameCtrl.text.trim();
    final sets = _setsCtrl.text.trim();
    final reps = _repsCtrl.text.trim();
    if (name.isEmpty) { _nameError.value = 'Enter exercise name'; ok = false; }
    else if (RegExp(r'[0-9]').hasMatch(name)) {
      _nameError.value = 'Name must contain only letters'; ok = false;
    }
    if (sets.isEmpty) { _setsError.value = 'Enter sets'; ok = false; }
    else if (!RegExp(r'^\d+$').hasMatch(sets)) {
      _setsError.value = 'Numbers only'; ok = false;
    }
    if (reps.isEmpty) { _repsError.value = 'Enter reps'; ok = false; }
    else if (!RegExp(r'^\d+$').hasMatch(reps)) {
      _repsError.value = 'Numbers only'; ok = false;
    }
    return ok;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _nameCtrl.dispose();
    _setsCtrl.dispose();
    _repsCtrl.dispose();
    _suggestions.dispose();
    _nameError.dispose();
    _setsError.dispose();
    _repsError.dispose();
    _keyboardHeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: _keyboardHeight,
      builder: (_, kbHeight, child) => Padding(
        padding: EdgeInsets.only(bottom: kbHeight),
        child: child,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: LiftdColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 16),
          Text(
            widget.initialName.isEmpty ? 'Add Exercise' : 'Edit Exercise',
            style: GoogleFonts.spaceMono(
                color: LiftdColors.cream,
                fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 18),
          // Name field
          ValueListenableBuilder<String>(
            valueListenable: _nameError,
            builder: (_, err, __) => TextField(
              controller: _nameCtrl,
              onChanged: _onNameChanged,
              autofocus: false,
              style: GoogleFonts.spaceMono(color: LiftdColors.cream, fontSize: 13),
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: 'Exercise name',
                labelText: 'Exercise',
                prefixIcon: const Icon(Icons.fitness_center_rounded,
                    color: LiftdColors.orange, size: 18),
                errorText: err.isEmpty ? null : err,
              ),
            ),
          ),
          // Suggestions
          ValueListenableBuilder<List<String>>(
            valueListenable: _suggestions,
            builder: (_, list, __) {
              if (list.isEmpty) return const SizedBox.shrink();
              final q = _nameCtrl.text.trim().toLowerCase();
              return Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: LiftdColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: LiftdColors.orange.withOpacity(0.3)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: list.asMap().entries.map((e) {
                    final i = e.key; final name = e.value;
                    final idx = name.toLowerCase().indexOf(q);
                    final s = idx < 0 ? 0 : idx;
                    final end = (s + q.length).clamp(0, name.length);
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _pickSuggestion(name),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: i < list.length - 1
                            ? BoxDecoration(border: Border(bottom: BorderSide(
                                color: Colors.white.withOpacity(0.05))))
                            : null,
                        child: RichText(text: TextSpan(children: [
                          if (s > 0) TextSpan(text: name.substring(0, s),
                              style: GoogleFonts.spaceMono(color: Colors.grey.shade400, fontSize: 12)),
                          TextSpan(text: name.substring(s, end),
                              style: GoogleFonts.spaceMono(color: LiftdColors.orange,
                                  fontWeight: FontWeight.w700, fontSize: 12)),
                          TextSpan(text: name.substring(end),
                              style: GoogleFonts.spaceMono(color: LiftdColors.cream, fontSize: 12)),
                        ])),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          // Sets + Reps
          Row(children: [
            Expanded(child: ValueListenableBuilder<String>(
              valueListenable: _setsError,
              builder: (_, err, __) => TextField(
                controller: _setsCtrl,
                style: GoogleFonts.spaceMono(color: LiftdColors.cream, fontSize: 13),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. 4', labelText: 'Sets',
                  prefixIcon: const Icon(Icons.repeat_rounded, color: LiftdColors.blue, size: 18),
                  errorText: err.isEmpty ? null : err,
                ),
              ),
            )),
            const SizedBox(width: 12),
            Expanded(child: ValueListenableBuilder<String>(
              valueListenable: _repsError,
              builder: (_, err, __) => TextField(
                controller: _repsCtrl,
                style: GoogleFonts.spaceMono(color: LiftdColors.cream, fontSize: 13),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'e.g. 10', labelText: 'Reps',
                  prefixIcon: const Icon(Icons.trending_up_rounded, color: LiftdColors.lifted, size: 18),
                  errorText: err.isEmpty ? null : err,
                ),
              ),
            )),
          ]),
          const SizedBox(height: 20),
          // Buttons
          Row(children: [
            Expanded(child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.white.withOpacity(0.05),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withOpacity(0.08))),
              ),
              child: Text('Cancel', style: GoogleFonts.spaceMono(
                  color: Colors.grey.shade400, fontWeight: FontWeight.w700, fontSize: 13)),
            )),
            const SizedBox(width: 10),
            Expanded(flex: 2, child: FilledButton(
              onPressed: () {
                if (!_validate()) return;
                Navigator.pop(context, {
                  'name': _nameCtrl.text.trim(),
                  'sets': _setsCtrl.text.trim(),
                  'reps': _repsCtrl.text.trim(),
                });
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: LiftdColors.orange.withOpacity(0.15),
                foregroundColor: LiftdColors.orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: LiftdColors.orange.withOpacity(0.55))),
              ),
              child: Text('Save Exercise', style: GoogleFonts.spaceMono(
                  color: LiftdColors.orange, fontWeight: FontWeight.w700, fontSize: 13)),
            )),
          ]),
        ]),
      ),
    );
  }
}

// ─── CALORIES SCREEN ──────────────────────────────────────────────────────────
class CaloriesScreen extends StatefulWidget {
  const CaloriesScreen({super.key});
  @override State<CaloriesScreen> createState() => _CaloriesScreenState();
}
class _CaloriesScreenState extends State<CaloriesScreen> {
  late Box fitBox;
  @override
  void initState() {
    super.initState(); fitBox = Hive.box(StorageKeys.boxName);
    if (!fitBox.containsKey(StorageKeys.calorieTarget)) fitBox.put(StorageKeys.calorieTarget, 2000);
  }

  int get _target => fitBox.get(StorageKeys.calorieTarget, defaultValue: 2000) as int;
  List<Map<String, dynamic>> _all() => List<Map<String, dynamic>>.from(
      ((fitBox.get(StorageKeys.calorieEntries, defaultValue: []) as List))
          .map((e) => Map<String, dynamic>.from(e)));
  List<Map<String, dynamic>> _today() {
    final n = DateTime.now();
    return _all().where((e) => e['year']==n.year && e['month']==n.month && e['day']==n.day).toList();
  }
  int get _total => _today().fold<int>(0, (s,e) => s + ((e['calories']??0) as int));

  void _setTarget() {
    final c = TextEditingController(text: _target.toString());
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: LiftdColors.surface,
      title: Text('Set Calorie Target', style: GoogleFonts.spaceMono(
          color: LiftdColors.cream, fontWeight: FontWeight.w700)),
      content: TextField(controller: c, keyboardType: TextInputType.number,
          style: GoogleFonts.spaceMono(color: LiftdColors.cream),
          decoration: const InputDecoration(hintText: 'Daily target')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.spaceMono(color: Colors.grey))),
        FilledButton(onPressed: () {
          final v = int.tryParse(c.text.trim());
          if (v != null && v > 0) { fitBox.put(StorageKeys.calorieTarget, v); setState((){}); Navigator.pop(context); }
        }, child: const Text('Save')),
      ],
    ));
  }

  void _add() {
    final fc = TextEditingController(), cc = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: LiftdColors.surface,
      title: Text('Add Food', style: GoogleFonts.spaceMono(
          color: LiftdColors.cream, fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: fc, style: GoogleFonts.spaceMono(color: LiftdColors.cream),
            decoration: const InputDecoration(hintText: 'Food name')),
        const SizedBox(height: 12),
        TextField(controller: cc, keyboardType: TextInputType.number,
            style: GoogleFonts.spaceMono(color: LiftdColors.cream),
            decoration: const InputDecoration(hintText: 'Calories')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.spaceMono(color: Colors.grey))),
        FilledButton(onPressed: () {
          final cal = int.tryParse(cc.text.trim()); final food = fc.text.trim();
          if (food.isEmpty || cal == null) return;
          final n = DateTime.now(); final entries = _all();
          entries.add({'food':food,'calories':cal,'year':n.year,'month':n.month,
              'day':n.day,'timestamp':n.toIso8601String()});
          fitBox.put(StorageKeys.calorieEntries, entries); setState((){}); Navigator.pop(context);
        }, child: const Text('Add')),
      ],
    ));
  }

  void _remove(int i) {
    final all = _all(); final today = _today(); final item = today[i];
    all.removeWhere((e) => e['timestamp']==item['timestamp'] &&
        e['food']==item['food'] && e['calories']==item['calories']);
    fitBox.put(StorageKeys.calorieEntries, all); setState((){});
  }

  @override
  Widget build(BuildContext context) {
    final target = _target, total = _total;
    final rem = target - total;
    final prog = (total / target).clamp(0.0, 1.0);
    final entries = _today();
    return AppPage(
      title: 'Calories', subtitle: 'fuel the machine.',
      actions: [IconButton(onPressed: _setTarget,
          icon: const Icon(Icons.tune_rounded, color: LiftdColors.cream))],
      child: ListView(children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: LiftdColors.card,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withOpacity(0.04))),
          child: Column(children: [
            Text("Today's Intake", style: GoogleFonts.spaceMono(
                color: LiftdColors.cream, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 18),
            SizedBox(width: 130, height: 130,
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(width: 130, height: 130,
                    child: CircularProgressIndicator(value: prog, strokeWidth: 10,
                        backgroundColor: Colors.white.withOpacity(0.06),
                        valueColor: const AlwaysStoppedAnimation<Color>(LiftdColors.orange))),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$total', style: GoogleFonts.spaceMono(
                      color: LiftdColors.cream, fontSize: 28, fontWeight: FontWeight.w700)),
                  Text('/ $target', style: GoogleFonts.spaceMono(
                      color: Colors.grey.shade500, fontSize: 10)),
                ]),
              ]),
            ),
            const SizedBox(height: 16),
            Text(rem >= 0 ? '$rem kcal remaining' : '${rem.abs()} kcal over',
                style: GoogleFonts.spaceMono(color: Colors.grey.shade400, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _StatusBtn(label: 'Add Food', color: LiftdColors.lifted,
              icon: Icons.add_rounded, onTap: _add)),
          const SizedBox(width: 10),
          Expanded(child: _StatusBtn(label: 'Set Target', color: LiftdColors.blue,
              icon: Icons.flag_outlined, onTap: _setTarget)),
        ]),
        const SizedBox(height: 18),
        const _SectionTitle(title: "Today's Entries"),
        const SizedBox(height: 12),
        if (entries.isEmpty)
          Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: LiftdColors.card, borderRadius: BorderRadius.circular(18)),
              child: Text('No entries yet.', style: GoogleFonts.spaceMono(
                  color: Colors.grey.shade500, fontSize: 12)))
        else
          ...List.generate(entries.length, (i) {
            final item = entries[i];
            return Padding(padding: const EdgeInsets.only(bottom: 10),
              child: Dismissible(
                key: ValueKey(item['timestamp']),
                direction: DismissDirection.endToStart,
                background: Container(alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(color: LiftdColors.benched.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.delete_outline, color: LiftdColors.benched)),
                onDismissed: (_) => _remove(i),
                child: _InfoCard(title: item['food'], value: '${item['calories']} kcal',
                    icon: Icons.restaurant_menu_outlined, fullWidth: true),
              ),
            );
          }),
      ]),
    );
  }
}

// ─── PROGRESS SCREEN ──────────────────────────────────────────────────────────
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});
  @override State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late Box fitBox;
  final _picker = ImagePicker();

  @override
  void initState() { super.initState(); fitBox = Hive.box(StorageKeys.boxName); }

  List<Map<String, dynamic>> _photos() => List<Map<String, dynamic>>.from(
      ((fitBox.get(StorageKeys.progressPhotos, defaultValue: []) as List))
          .map((e) => Map<String, dynamic>.from(e)));

  // Group photos by date key "day/month/year"
  Map<String, List<Map<String, dynamic>>> _grouped() {
    final all = _photos().reversed.toList();
    final map = <String, List<Map<String, dynamic>>>{};
    for (final p in all) {
      final key = '${p['day']}/${p['month']}/${p['year']}';
      map.putIfAbsent(key, () => []).add(p);
    }
    return map;
  }

  Future<void> _add(ImageSource src) async {
    final file = await _picker.pickImage(source: src, imageQuality: 85);
    if (file == null || !mounted) return;
    final nC = TextEditingController(), wC = TextEditingController();
    await showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: LiftdColors.surface,
      title: Text('Save Progress Photo', style: GoogleFonts.spaceMono(
          color: LiftdColors.cream, fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nC, style: GoogleFonts.spaceMono(color: LiftdColors.cream),
            decoration: const InputDecoration(hintText: 'Optional note')),
        const SizedBox(height: 12),
        TextField(controller: wC, keyboardType: TextInputType.number,
            style: GoogleFonts.spaceMono(color: LiftdColors.cream),
            decoration: const InputDecoration(hintText: 'Weight (optional)')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.spaceMono(color: Colors.grey))),
        FilledButton(onPressed: () {
          final n = DateTime.now(); final photos = _photos();
          photos.add({
            'path': file.path, 'note': nC.text.trim(), 'weight': wC.text.trim(),
            'year': n.year, 'month': n.month, 'day': n.day,
            'timestamp': n.toIso8601String(),
          });
          fitBox.put(StorageKeys.progressPhotos, photos);
          setState(() {}); Navigator.pop(context);
        }, child: const Text('Save')),
      ],
    ));
  }

  void _removeByTimestamp(String timestamp) {
    final photos = _photos();
    photos.removeWhere((p) => p['timestamp'] == timestamp);
    fitBox.put(StorageKeys.progressPhotos, photos);
    setState(() {});
  }

  // Download photo to device gallery using the gal package
  Future<void> _downloadPhoto(String path) async {
    try {
      final file = File(path);
      if (!file.existsSync()) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              duration: const Duration(seconds: 2),
              content: Text('File not found.',
                  style: GoogleFonts.spaceMono(
                      color: LiftdColors.cream, fontSize: 12)),
            ));
        }
        return;
      }
      // Request permission and save to gallery
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: true);
      }
      await Gal.putImage(path, album: 'Liftd');
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            duration: const Duration(seconds: 2),
            content: Row(children: [
              const Icon(Icons.download_done_rounded,
                  color: LiftdColors.lifted, size: 16),
              const SizedBox(width: 8),
              Text('Saved to gallery  ·  Liftd album',
                  style: GoogleFonts.spaceMono(
                      color: LiftdColors.cream, fontSize: 12)),
            ]),
          ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            duration: const Duration(seconds: 2),
            content: Text('Could not save to gallery.',
                style: GoogleFonts.spaceMono(
                    color: LiftdColors.cream, fontSize: 12)),
          ));
      }
    }
  }

  Future<Directory> _getAppDocDir() async {
    return Directory('/var/mobile/Containers/Data/Application');
  }

  // Open full-screen photo viewer
  void _openFullScreen(BuildContext context, List<Map<String, dynamic>> photos,
      int initialIndex) {
    Navigator.of(context).push(PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      pageBuilder: (_, __, ___) => _FullScreenViewer(
        photos: photos,
        initialIndex: initialIndex,
        onDelete: (ts) {
          _removeByTimestamp(ts);
          Navigator.of(context).pop();
        },
        onDownload: _downloadPhoto,
      ),
      transitionsBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped();
    final dateKeys = grouped.keys.toList();

    return AppPage(
      title: 'Transformation', subtitle: 'your private progress archive.',
      child: ListView(children: [
        Row(children: [
          Expanded(child: _StatusBtn(label: 'Camera', color: LiftdColors.lifted,
              icon: Icons.photo_camera_outlined, onTap: () => _add(ImageSource.camera))),
          const SizedBox(width: 10),
          Expanded(child: _StatusBtn(label: 'Gallery', color: LiftdColors.blue,
              icon: Icons.image_outlined, onTap: () => _add(ImageSource.gallery))),
        ]),
        const SizedBox(height: 20),

        if (dateKeys.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: LiftdColors.card,
                borderRadius: BorderRadius.circular(18)),
            child: Column(children: [
              Icon(Icons.photo_library_outlined,
                  color: Colors.grey.shade700, size: 36),
              const SizedBox(height: 10),
              Text('No progress photos yet.',
                  style: GoogleFonts.spaceMono(
                      color: Colors.grey.shade500, fontSize: 12)),
            ]),
          )
        else
          ...dateKeys.map((dateKey) {
            final dayPhotos = grouped[dateKey]!;
            // Collect all photos for this day (for the pager)
            return _DayGroup(
              dateKey: dateKey,
              photos: dayPhotos,
              onPhotoTap: (idx) => _openFullScreen(context, dayPhotos, idx),
              onDelete: (ts) => _removeByTimestamp(ts),
              onDownload: _downloadPhoto,
            );
          }),
      ]),
    );
  }
}

// ─── Day Group widget ──────────────────────────────────────────────────────────
class _DayGroup extends StatefulWidget {
  final String dateKey;
  final List<Map<String, dynamic>> photos;
  final ValueChanged<int> onPhotoTap;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onDownload;

  const _DayGroup({
    required this.dateKey, required this.photos,
    required this.onPhotoTap, required this.onDelete, required this.onDownload,
  });

  @override State<_DayGroup> createState() => _DayGroupState();
}

class _DayGroupState extends State<_DayGroup> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Date header row — tap to collapse/expand
      GestureDetector(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: LiftdColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: LiftdColors.orange),
            ),
            const SizedBox(width: 10),
            Text(widget.dateKey, style: GoogleFonts.spaceMono(
                color: LiftdColors.cream, fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: LiftdColors.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6)),
              child: Text('${widget.photos.length} photo${widget.photos.length > 1 ? 's' : ''}',
                  style: GoogleFonts.spaceMono(
                      color: LiftdColors.orange, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: _expanded ? 0 : -0.25,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.expand_more_rounded,
                  color: Colors.grey.shade600, size: 18),
            ),
          ]),
        ),
      ),

      // Photo grid for this day
      AnimatedCrossFade(
        duration: const Duration(milliseconds: 220),
        crossFadeState: _expanded
            ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        firstChild: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.photos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, mainAxisSpacing: 8,
              crossAxisSpacing: 8, childAspectRatio: 0.85),
          itemBuilder: (_, i) {
            final item = widget.photos[i];
            final f = File(item['path'] as String);
            return GestureDetector(
              onTap: () => widget.onPhotoTap(i),
              child: Container(
                decoration: BoxDecoration(
                  color: LiftdColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.04)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(fit: StackFit.expand, children: [
                    f.existsSync()
                        ? Image.file(f, fit: BoxFit.cover)
                        : Container(color: Colors.black26,
                            child: const Center(child: Icon(
                                Icons.broken_image_outlined,
                                color: Colors.white24))),
                    // Weight badge
                    if ((item['weight'] as String).isNotEmpty)
                      Positioned(
                        bottom: 5, left: 5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.65),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${item['weight']}kg',
                              style: GoogleFonts.spaceMono(
                                  color: LiftdColors.orange,
                                  fontSize: 9, fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ]),
                ),
              ),
            );
          },
        ),
        secondChild: const SizedBox.shrink(),
      ),
      const SizedBox(height: 18),
    ]);
  }
}

// ─── Full-Screen Photo Viewer ──────────────────────────────────────────────────
class _FullScreenViewer extends StatefulWidget {
  final List<Map<String, dynamic>> photos;
  final int initialIndex;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onDownload;

  const _FullScreenViewer({
    required this.photos, required this.initialIndex,
    required this.onDelete, required this.onDownload,
  });

  @override State<_FullScreenViewer> createState() => _FullScreenViewerState();
}

class _FullScreenViewerState extends State<_FullScreenViewer> {
  late PageController _pageCtrl;
  late int _cur;

  @override
  void initState() {
    super.initState();
    _cur = widget.initialIndex;
    _pageCtrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final item = widget.photos[_cur];
    final f = File(item['path'] as String);
    final hasNote   = (item['note']   as String).isNotEmpty;
    final hasWeight = (item['weight'] as String).isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [

        // ── PageView for swipe between photos ────────────────────────────────
        PageView.builder(
          controller: _pageCtrl,
          itemCount: widget.photos.length,
          onPageChanged: (i) => setState(() => _cur = i),
          itemBuilder: (_, i) {
            final pf = File(widget.photos[i]['path'] as String);
            return InteractiveViewer(
              minScale: 0.8, maxScale: 4.0,
              child: Center(
                child: pf.existsSync()
                    ? Image.file(pf, fit: BoxFit.contain)
                    : const Icon(Icons.broken_image_outlined,
                        color: Colors.white24, size: 64),
              ),
            );
          },
        ),

        // ── Top bar: close + page counter ────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              const Spacer(),
              if (widget.photos.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Text('${_cur + 1} / ${widget.photos.length}',
                      style: GoogleFonts.spaceMono(
                          color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
            ]),
          ),
        ),

        // ── Bottom bar: info + download + delete ─────────────────────────────
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.85), Colors.transparent],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 36),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Date
              Text('${item['day']}/${item['month']}/${item['year']}',
                  style: GoogleFonts.spaceMono(
                      color: Colors.white, fontWeight: FontWeight.w700,
                      fontSize: 15)),
              if (hasWeight) ...[
                const SizedBox(height: 4),
                Text('${item['weight']} kg',
                    style: GoogleFonts.spaceMono(
                        color: LiftdColors.orange,
                        fontWeight: FontWeight.w700, fontSize: 12)),
              ],
              if (hasNote) ...[
                const SizedBox(height: 4),
                Text(item['note'] as String,
                    style: GoogleFonts.spaceMono(
                        color: Colors.white70, fontSize: 11)),
              ],
              const SizedBox(height: 16),
              // Action buttons
              Row(children: [
                // Download
                _ViewerBtn(
                  icon: Icons.download_rounded,
                  label: 'Save',
                  color: LiftdColors.blue,
                  onTap: () => widget.onDownload(item['path'] as String),
                ),
                const SizedBox(width: 10),
                // Delete
                _ViewerBtn(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete',
                  color: LiftdColors.benched,
                  onTap: () {
                    showDialog(context: context, builder: (_) => AlertDialog(
                      backgroundColor: LiftdColors.surface,
                      title: Text('Delete Photo?',
                          style: GoogleFonts.spaceMono(
                              color: LiftdColors.cream, fontWeight: FontWeight.w700)),
                      content: Text('This cannot be undone.',
                          style: GoogleFonts.spaceMono(
                              color: Colors.grey.shade400, fontSize: 12)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context),
                            child: Text('Cancel',
                                style: GoogleFonts.spaceMono(color: Colors.grey))),
                        FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: LiftdColors.benched),
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onDelete(item['timestamp'] as String);
                          },
                          child: const Text('Delete'),
                        ),
                      ],
                    ));
                  },
                ),
              ]),
            ]),
          ),
        ),

        // ── Swipe hint arrows ─────────────────────────────────────────────────
        if (_cur > 0)
          Positioned(
            left: 12,
            top: 0, bottom: 0,
            child: Center(
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle),
                child: const Icon(Icons.chevron_left_rounded,
                    color: Colors.white54, size: 20),
              ),
            ),
          ),
        if (_cur < widget.photos.length - 1)
          Positioned(
            right: 12,
            top: 0, bottom: 0,
            child: Center(
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle),
                child: const Icon(Icons.chevron_right_rounded,
                    color: Colors.white54, size: 20),
              ),
            ),
          ),
      ]),
    );
  }
}

class _ViewerBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ViewerBtn({required this.icon, required this.label,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.45)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.spaceMono(
              color: color, fontWeight: FontWeight.w700, fontSize: 12)),
        ]),
      ),
    );
  }
}


// ─── PR & NOTES SCREEN ───────────────────────────────────────────────────────
class PRScreen extends StatefulWidget {
  const PRScreen({super.key});
  @override State<PRScreen> createState() => _PRScreenState();
}

class _PRScreenState extends State<PRScreen>
    with SingleTickerProviderStateMixin {
  late Box fitBox;
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    fitBox = Hive.box(StorageKeys.boxName);
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  // ── PR helpers ──────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _prs() => List<Map<String, dynamic>>.from(
      ((fitBox.get(StorageKeys.prRecords, defaultValue: []) as List))
          .map((e) => Map<String, dynamic>.from(e)));

  void _savePRs(List<Map<String, dynamic>> list) =>
      fitBox.put(StorageKeys.prRecords, list);

  void _deletePR(int i) {
    final list = _prs(); list.removeAt(i);
    _savePRs(list); setState(() {});
  }

  Future<void> _addOrEditPR({Map<String, dynamic>? existing, int? index}) async {
    final nameCtrl  = TextEditingController(text: existing?['exercise'] ?? '');
    final valueCtrl = TextEditingController(text: existing?['value'] ?? '');
    final unitCtrl  = TextEditingController(text: existing?['unit'] ?? 'kg');
    final suggestions = ValueNotifier<List<String>>([]);
    Timer? debounce;

    void onNameChanged(String v) {
      debounce?.cancel();
      final q = v.trim().toLowerCase();
      if (q.isEmpty) { suggestions.value = []; return; }
      debounce = Timer(const Duration(milliseconds: 180), () {
        final starts = <String>[], contains = <String>[];
        for (final e in kExerciseDatabase) {
          final l = e.toLowerCase();
          if (l.startsWith(q)) {
            starts.add(e);
          } else if (l.contains(q)) contains.add(e);
          if (starts.length + contains.length >= 8) break;
        }
        suggestions.value = [...starts, ...contains].take(5).toList();
      });
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => StatefulBuilder(builder: (ctx, ss) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: LiftdColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(existing == null ? 'Add PR' : 'Edit PR',
                  style: GoogleFonts.spaceMono(color: LiftdColors.cream,
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 18),
              // Exercise name with autocomplete
              TextField(
                controller: nameCtrl,
                onChanged: onNameChanged,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.spaceMono(color: LiftdColors.cream, fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Exercise', hintText: 'e.g. Bench Press',
                  prefixIcon: Icon(Icons.fitness_center_rounded,
                      color: LiftdColors.orange, size: 18),
                ),
              ),
              // Autocomplete dropdown
              ValueListenableBuilder<List<String>>(
                valueListenable: suggestions,
                builder: (_, list, __) {
                  if (list.isEmpty) return const SizedBox.shrink();
                  final q = nameCtrl.text.trim().toLowerCase();
                  return Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: LiftdColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: LiftdColors.orange.withOpacity(0.3)),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min,
                      children: list.asMap().entries.map((e) {
                        final i = e.key; final name = e.value;
                        final idx = name.toLowerCase().indexOf(q);
                        final s = idx < 0 ? 0 : idx;
                        final end = (s + q.length).clamp(0, name.length);
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            nameCtrl.text = name;
                            nameCtrl.selection = TextSelection.fromPosition(
                                TextPosition(offset: name.length));
                            suggestions.value = [];
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: i < list.length - 1
                                ? BoxDecoration(border: Border(bottom: BorderSide(
                                    color: Colors.white.withOpacity(0.05))))
                                : null,
                            child: RichText(text: TextSpan(children: [
                              if (s > 0) TextSpan(text: name.substring(0, s),
                                  style: GoogleFonts.spaceMono(color: Colors.grey.shade400, fontSize: 12)),
                              TextSpan(text: name.substring(s, end),
                                  style: GoogleFonts.spaceMono(color: LiftdColors.orange,
                                      fontWeight: FontWeight.w700, fontSize: 12)),
                              TextSpan(text: name.substring(end),
                                  style: GoogleFonts.spaceMono(color: LiftdColors.cream, fontSize: 12)),
                            ])),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              // Value + Unit side by side
              Row(children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: valueCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.spaceMono(color: LiftdColors.cream, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'PR Value', hintText: 'e.g. 100',
                      prefixIcon: Icon(Icons.emoji_events_rounded,
                          color: LiftdColors.orange, size: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: unitCtrl,
                    style: GoogleFonts.spaceMono(color: LiftdColors.cream, fontSize: 13),
                    decoration: const InputDecoration(
                      labelText: 'Unit', hintText: 'kg / lbs / reps',
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.white.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.08))),
                  ),
                  child: Text('Cancel', style: GoogleFonts.spaceMono(
                      color: Colors.grey.shade400, fontWeight: FontWeight.w700, fontSize: 13)),
                )),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: FilledButton(
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final val  = valueCtrl.text.trim();
                    final unit = unitCtrl.text.trim();
                    if (name.isEmpty || val.isEmpty) return;
                    final entry = {
                      'exercise': name,
                      'value': val,
                      'unit': unit.isEmpty ? 'kg' : unit,
                      'date': DateTime.now().toIso8601String(),
                    };
                    final list = _prs();
                    if (index != null) {
                      list[index] = entry;
                    } else {
                      list.add(entry);
                    }
                    _savePRs(list);
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: LiftdColors.orange.withOpacity(0.15),
                    foregroundColor: LiftdColors.orange,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: LiftdColors.orange.withOpacity(0.55))),
                  ),
                  child: Text('Save PR', style: GoogleFonts.spaceMono(
                      color: LiftdColors.orange, fontWeight: FontWeight.w700, fontSize: 13)),
                )),
              ]),
            ]),
          ),
        );
      }),
    );
    debounce?.cancel();
    suggestions.dispose();
  }

  // ── Notes helpers ────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _notes() => List<Map<String, dynamic>>.from(
      ((fitBox.get(StorageKeys.notes, defaultValue: []) as List))
          .map((e) => Map<String, dynamic>.from(e)));

  void _saveNotes(List<Map<String, dynamic>> list) =>
      fitBox.put(StorageKeys.notes, list);

  void _deleteNote(int i) {
    final list = _notes(); list.removeAt(i);
    _saveNotes(list); setState(() {});
  }

 Future<void> _addOrEditNote({Map<String, dynamic>? existing, int? index}) async {
  final titleCtrl = TextEditingController(text: existing?['title'] ?? '');
  final bodyCtrl  = TextEditingController(text: existing?['body'] ?? '');

  await showDialog(
    context: context,
    // Keeps the dialog centred; keyboard shifts it up via Dialog's built-in
    // viewInsets handling — no sliding sheet animation = no jank.
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        top: 20,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: LiftdColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Header
            Row(children: [
              Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: LiftdColors.blue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sticky_note_2_outlined,
                    color: LiftdColors.blue, size: 16),
              ),
              const SizedBox(width: 12),
              Text(existing == null ? 'New Note' : 'Edit Note',
                  style: GoogleFonts.spaceMono(color: LiftdColors.cream,
                      fontWeight: FontWeight.w700, fontSize: 16)),
            ]),
            const SizedBox(height: 18),
            // Title field
            TextField(
              controller: titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.spaceMono(color: LiftdColors.cream, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Title', hintText: 'Note title',
                prefixIcon: Icon(Icons.title_rounded,
                    color: LiftdColors.blue, size: 18),
              ),
            ),
            const SizedBox(height: 12),
            // Fixed maxLines avoids unbounded height re-layouts during typing
            TextField(
              controller: bodyCtrl,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.spaceMono(color: LiftdColors.cream, fontSize: 12),
              decoration: const InputDecoration(
                labelText: 'Note',
                hintText: 'Write anything...',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 60),
                  child: Icon(Icons.notes_rounded, color: LiftdColors.blue, size: 18),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.white.withOpacity(0.08))),
                ),
                child: Text('Cancel', style: GoogleFonts.spaceMono(
                    color: Colors.grey.shade400, fontWeight: FontWeight.w700, fontSize: 13)),
              )),
              const SizedBox(width: 10),
              Expanded(flex: 2, child: FilledButton(
                onPressed: () {
                  final title = titleCtrl.text.trim();
                  final body  = bodyCtrl.text.trim();
                  if (title.isEmpty && body.isEmpty) return;
                  final entry = {
                    'title': title.isEmpty ? 'Untitled' : title,
                    'body': body,
                    'date': DateTime.now().toIso8601String(),
                  };
                  final list = _notes();
                  if (index != null) {
                    list[index] = entry;
                  } else {
                    list.add(entry);
                  }
                  _saveNotes(list);
                  setState(() {});
                  Navigator.pop(ctx);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: LiftdColors.blue.withOpacity(0.15),
                  foregroundColor: LiftdColors.blue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: LiftdColors.blue.withOpacity(0.55))),
                ),
                child: Text('Save Note', style: GoogleFonts.spaceMono(
                    color: LiftdColors.blue, fontWeight: FontWeight.w700, fontSize: 13)),
              )),
            ]),
          ]),
        ),
      ),
    ),
  );
}
  String _fmtDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final prs   = _prs();
    final notes = _notes();

    return AppPage(
      title: 'PR & Notes',
      subtitle: 'track records. log thoughts.',
      actions: [
        IconButton(
          onPressed: _tab.index == 0
              ? () => _addOrEditPR()
              : () => _addOrEditNote(),
          icon: Icon(
            _tab.index == 0 ? Icons.add_rounded : Icons.note_add_rounded,
            color: LiftdColors.orange,
          ),
        ),
      ],
      child: Column(children: [
        // Tab selector
        Container(
          height: 44,
          decoration: BoxDecoration(
            color: LiftdColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(children: [
            _PRTab(label: '🏆  PRs',    selected: _tab.index == 0, onTap: () => _tab.animateTo(0)),
            _PRTab(label: '📝  Notes', selected: _tab.index == 1, onTap: () => _tab.animateTo(1)),
          ]),
        ),
        const SizedBox(height: 16),

        Expanded(child: TabBarView(
          controller: _tab,
          children: [
            // ── PR Tab ───────────────────────────────────────────────────────
            prs.isEmpty
                ? const _EmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: 'No PRs yet',
                    subtitle: 'Tap + to log your first personal record.',
                    color: LiftdColors.orange,
                  )
                : ListView.builder(
                    itemCount: prs.length,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemBuilder: (_, i) {
                      final pr = prs[i];
                      return _PRCard(
                        exercise: pr['exercise'] as String,
                        value: '${pr['value']} ${pr['unit']}',
                        date: _fmtDate(pr['date'] as String),
                        onEdit: () => _addOrEditPR(existing: pr, index: i),
                        onDelete: () => _deletePR(i),
                      );
                    },
                  ),

            // ── Notes Tab ────────────────────────────────────────────────────
            notes.isEmpty
                ? const _EmptyState(
                    icon: Icons.notes_rounded,
                    title: 'No notes yet',
                    subtitle: 'Tap + to write your first note.',
                    color: LiftdColors.blue,
                  )
                : ListView.builder(
                    itemCount: notes.length,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemBuilder: (_, i) {
                      final note = notes[i];
                      return _NoteCard(
                        title: note['title'] as String,
                        body: note['body'] as String,
                        date: _fmtDate(note['date'] as String),
                        onEdit: () => _addOrEditNote(existing: note, index: i),
                        onDelete: () => _deleteNote(i),
                      );
                    },
                  ),
          ],
        )),
      ]),
    );
  }
}

// ─── PR Tab Selector ──────────────────────────────────────────────────────────
class _PRTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _PRTab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? LiftdColors.orange.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: selected
                ? Border.all(color: LiftdColors.orange.withOpacity(0.4))
                : null,
          ),
          child: Center(
            child: Text(label, style: GoogleFonts.spaceMono(
                color: selected ? LiftdColors.orange : Colors.grey.shade500,
                fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ),
      ),
    );
  }
}

// ─── PR Card ──────────────────────────────────────────────────────────────────
class _PRCard extends StatelessWidget {
  final String exercise, value, date;
  final VoidCallback onEdit, onDelete;
  const _PRCard({required this.exercise, required this.value,
      required this.date, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LiftdColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: LiftdColors.orange.withOpacity(0.25)),
        boxShadow: [BoxShadow(
            color: LiftdColors.orange.withOpacity(0.06),
            blurRadius: 12, spreadRadius: -4)],
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: LiftdColors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: LiftdColors.orange.withOpacity(0.3)),
          ),
          child: const Icon(Icons.emoji_events_rounded,
              color: LiftdColors.orange, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(exercise, style: GoogleFonts.spaceMono(
              color: LiftdColors.cream, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          Row(children: [
            Text(value, style: GoogleFonts.spaceMono(
                color: LiftdColors.orange, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(width: 10),
            Text(date, style: GoogleFonts.spaceMono(
                color: Colors.grey.shade600, fontSize: 10)),
          ]),
        ])),
        IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, color: LiftdColors.blue, size: 18),
          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded,
              color: LiftdColors.benched, size: 18),
          padding: EdgeInsets.zero, constraints: const BoxConstraints(),
        ),
      ]),
    );
  }
}

// ─── Note Card ────────────────────────────────────────────────────────────────
class _NoteCard extends StatefulWidget {
  final String title, body, date;
  final VoidCallback onEdit, onDelete;
  const _NoteCard({required this.title, required this.body,
      required this.date, required this.onEdit, required this.onDelete});
  @override State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: LiftdColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: LiftdColors.blue.withOpacity(0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: LiftdColors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sticky_note_2_outlined,
                  color: LiftdColors.blue, size: 17),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title, style: GoogleFonts.spaceMono(
                  color: LiftdColors.cream, fontWeight: FontWeight.w700, fontSize: 13)),
              Text(widget.date, style: GoogleFonts.spaceMono(
                  color: Colors.grey.shade600, fontSize: 10)),
            ])),
            Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                color: Colors.grey.shade600, size: 18),
            const SizedBox(width: 4),
            IconButton(
              onPressed: widget.onEdit,
              icon: const Icon(Icons.edit_outlined, color: LiftdColors.blue, size: 17),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: widget.onDelete,
              icon: const Icon(Icons.delete_outline_rounded,
                  color: LiftdColors.benched, size: 17),
              padding: EdgeInsets.zero, constraints: const BoxConstraints(),
            ),
          ]),
          if (_expanded && widget.body.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white.withOpacity(0.06), height: 1),
            const SizedBox(height: 10),
            Text(widget.body, style: GoogleFonts.spaceMono(
                color: Colors.grey.shade400, fontSize: 12, height: 1.5)),
          ],
        ]),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  const _EmptyState({required this.icon, required this.title,
      required this.subtitle, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color.withOpacity(0.4), size: 52),
        const SizedBox(height: 14),
        Text(title, style: GoogleFonts.spaceMono(
            color: LiftdColors.cream, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 6),
        Text(subtitle, style: GoogleFonts.spaceMono(
            color: Colors.grey.shade600, fontSize: 11),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ─── SETTINGS SCREEN ──────────────────────────────────────────────────────────
class SettingsScreen extends StatelessWidget {
  final VoidCallback onRefreshAll;
  const SettingsScreen({super.key, required this.onRefreshAll});

  void _confirm(BuildContext ctx, String title, String msg, VoidCallback fn) {
    showDialog(context: ctx, builder: (_) => AlertDialog(
      backgroundColor: LiftdColors.surface,
      title: Text(title, style: GoogleFonts.spaceMono(
          color: LiftdColors.cream, fontWeight: FontWeight.w700)),
      content: Text(msg, style: GoogleFonts.spaceMono(
          color: Colors.grey.shade400, fontSize: 12)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.spaceMono(color: Colors.grey))),
        FilledButton(onPressed: () {
          fn(); Navigator.pop(ctx);
          ScaffoldMessenger.of(ctx)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              duration: const Duration(seconds: 2),
              content: Text('$title done',
                  style: GoogleFonts.spaceMono(color: LiftdColors.cream, fontSize: 12))));
          onRefreshAll();
        }, child: const Text('Reset')),
      ],
    ));
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Reset Attendance','Clears Lifted, Benched, Recovered marks.',
          Icons.calendar_month_outlined,LiftdColors.blue,AppDataUtils.resetAttendance),
      ('Reset Workout Progress','Clears exercise completion data.',
          Icons.fitness_center_outlined,LiftdColors.lifted,AppDataUtils.resetWorkoutProgress),
      ('Reset Calories','Clears food logs and resets target to 2000.',
          Icons.local_fire_department_outlined,const Color(0xFFEAB308),AppDataUtils.resetCalories),
      ('Reset Photos','Clears your transformation archive.',
          Icons.photo_library_outlined,const Color(0xFFA78BFA),AppDataUtils.resetProgressPhotos),
      ('Reset Everything','Clears all local data.',
          Icons.delete_forever_outlined,LiftdColors.benched,AppDataUtils.resetEverything),
    ];

    return AppPage(
      title: 'Settings', subtitle: 'reset only what you need.',
      child: ListView(children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: LiftdColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: LiftdColors.orange.withOpacity(0.2))),
          child: Row(children: [
            Container(width: 56, height: 56,
                decoration: BoxDecoration(color: const Color(0xFF0E0E0E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: LiftdColors.orange.withOpacity(0.3))),
                child: const Center(child: LiftdLogo(size: 32))),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              RichText(text: TextSpan(children: [
                TextSpan(text: 'liftd', style: GoogleFonts.spaceMono(
                    color: LiftdColors.cream, fontSize: 22, fontWeight: FontWeight.w700)),
                TextSpan(text: '.', style: GoogleFonts.spaceMono(
                    color: LiftdColors.orange, fontSize: 22, fontWeight: FontWeight.w700)),
              ])),
              Text('track every lift', style: GoogleFonts.spaceMono(
                  color: Colors.grey.shade500, fontSize: 10, letterSpacing: 1.2)),
            ]),
          ]),
        ),
        const SizedBox(height: 22),
        const _SectionTitle(title: 'Reset Data'),
        const SizedBox(height: 12),
        ...items.map((it) => Padding(padding: const EdgeInsets.only(bottom: 12),
            child: _SetCard(title: it.$1, subtitle: it.$2, icon: it.$3, color: it.$4,
                onTap: () => _confirm(context, it.$1, it.$2, it.$5)))),
      ]),
    );
  }
}

class _SetCard extends StatefulWidget {
  final String title, subtitle; final IconData icon; final Color color; final VoidCallback onTap;
  const _SetCard({required this.title, required this.subtitle, required this.icon,
      required this.color, required this.onTap});
  @override State<_SetCard> createState() => _SetCardState();
}
class _SetCardState extends State<_SetCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 130));
    _s = Tween<double>(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _c, curve: Curves.easeIn));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(scale: _s,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: LiftdColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.04))),
          child: Row(children: [
            Container(width: 44, height: 44,
                decoration: BoxDecoration(color: widget.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(widget.icon, color: widget.color, size: 20)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.title, style: GoogleFonts.spaceMono(
                  color: LiftdColors.cream, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 3),
              Text(widget.subtitle, style: GoogleFonts.spaceMono(
                  color: Colors.grey.shade500, fontSize: 10)),
            ])),
          ]),
        ),
      ),
    );
  }
}