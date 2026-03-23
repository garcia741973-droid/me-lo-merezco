import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/services/network_monitor.dart';

//import '../client/client_main_menu_screen.dart';
import '../client/client_home_screen.dart';

class SplashMiniCore extends StatefulWidget {
  const SplashMiniCore({super.key});

  @override
  State<SplashMiniCore> createState() => _SplashMiniCoreState();
}

class _SplashMiniCoreState extends State<SplashMiniCore>
    with TickerProviderStateMixin {

  String appVersion = "";

  final String _appDescription =
      "Cotiza, paga y recibe productos del mundo en Bolivia.";

  String _visibleDescription = "";
  int _descIndex = 0;

  late AnimationController _miniController;
  late Animation<double> _miniFadeScale;

  late AnimationController _shineController;
  late Animation<double> _shine;

  late AnimationController _transitionController;
  late Animation<double> _meLoFade;
  late Animation<double> _taglineFade;
  late Animation<double> _buttonsFade;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NetworkMonitor.start(context);
    });

    _loadVersion();

    _miniController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _miniFadeScale =
        CurvedAnimation(parent: _miniController, curve: Curves.easeOut);

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _shine = Tween<double>(begin: -40, end: 40).animate(
      CurvedAnimation(
        parent: _shineController,
        curve: Curves.linear,
      ),
    );

    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _meLoFade = CurvedAnimation(
      parent: _transitionController,
      curve: const Interval(0.45, 0.8, curve: Curves.easeOut),
    );

    _taglineFade = CurvedAnimation(
      parent: _transitionController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );

    _buttonsFade = CurvedAnimation(
      parent: _transitionController,
      curve: const Interval(0.8, 1.0, curve: Curves.easeOut),
    );

    _start();
    _startDescriptionTyping();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();

    setState(() {
      appVersion = info.version;
    });
  }

  void _start() async {
    await _miniController.forward();
    _shineController.repeat();
    await Future.delayed(const Duration(milliseconds: 600));
    await _transitionController.forward();
  }

  void _startDescriptionTyping() async {

    await Future.delayed(const Duration(milliseconds: 400));

    while (_descIndex < _appDescription.length) {

      await Future.delayed(const Duration(milliseconds: 28));

      setState(() {
        _visibleDescription += _appDescription[_descIndex];
        _descIndex++;
      });

    }
  }

  @override
  void dispose() {
    _miniController.dispose();
    _shineController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  Widget _buildMiniCoreCorner() {
    return Positioned(
      top: 50,
      left: 20,
      child: FadeTransition(
        opacity: _miniFadeScale,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(_miniFadeScale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyan.withOpacity(0.35),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Image.asset(
                  "assets/logos/logo_fondo_transparente_miniCore.png",
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "MINI",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "{CORE}",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.cyan,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),
              _buildShinyApps(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShinyApps() {
    return AnimatedBuilder(
      animation: _shine,
      builder: (context, child) {
        return Stack(
          children: [
            const Text(
              "APPS",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            Positioned(
              left: _shine.value,
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.white.withOpacity(0.9),
                      Colors.transparent,
                    ],
                  ).createShader(bounds);
                },
                child: const Text(
                  "APPS",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMeLoMerezco() {
    return AnimatedBuilder(
      animation: _meLoFade,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 40 * (1 - _meLoFade.value)),
          child: Opacity(
            opacity: _meLoFade.value,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FractionallySizedBox(
                  widthFactor: 0.7, // 30% más pequeño
                  child: Image.asset(
                    "assets/logos/logo_me_lo_merezco_transparente.png",
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTagline() {
    return AnimatedBuilder(
      animation: Listenable.merge([_taglineFade, _shine]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 12 * (1 - _taglineFade.value)),
          child: Opacity(
            opacity: _taglineFade.value,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "EL MUNDO LLEGA A 🇧🇴",
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppDescription() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22, left: 30, right: 30),
      child: Text(
        _visibleDescription,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 7,
          fontWeight: FontWeight.w500,
          color: Colors.white.withOpacity(0.95),
          height: 1.4,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildAuthButtons() {
    return AnimatedBuilder(
      animation: _buttonsFade,
      builder: (context, child) {
        return Opacity(
          opacity: _buttonsFade.value,
          child: Padding(
            padding: const EdgeInsets.only(top: 35),
            child: Column(
              children: [

                // 🔹 INVITADO (discreto arriba)
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.78,
                  height: 40,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientHomeScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "CONTINUAR COMO INVITADO",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.78,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text("INICIAR SESIÓN"),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.78,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/register');
                    },
                    child: const Text("CREAR CUENTA"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStoreLogos() {
    return AnimatedBuilder(
      animation: _buttonsFade,
      builder: (context, child) {
        return Opacity(
          opacity: _buttonsFade.value * 0.85,
          child: Padding(
            padding: const EdgeInsets.only(top: 26),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                Image.asset(
                  "assets/logos/apple_mini_white.png",
                  height: 18,
                  color: Colors.white.withOpacity(0.85),
                ),

                const SizedBox(width: 22),

                Image.asset(
                  "assets/logos/google_play_mini_white.png",
                  height: 18,
                  color: Colors.white.withOpacity(0.85),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          Positioned.fill(
            child: Image.asset(
              "assets/logos/fondoGeneral1.png",
              fit: BoxFit.cover,
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).size.height * 0.28,
            child: Column(
              children: [

                _buildAppDescription(),

                _buildMeLoMerezco(),

                _buildTagline(),

                _buildAuthButtons(),

                _buildStoreLogos(),

              ],
            ),
          ),

          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Column(
              children: [

                Text(
                  "MiniCore Apps - Me Lo Merezco",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.75),
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "Versión $appVersion",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),

          _buildMiniCoreCorner(),
        ],
      ),
    );
  }
}