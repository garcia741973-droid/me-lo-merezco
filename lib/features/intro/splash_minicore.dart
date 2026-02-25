import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';

class SplashMiniCore extends StatefulWidget {
  const SplashMiniCore({super.key});

  @override
  State<SplashMiniCore> createState() => _SplashMiniCoreState();
}

class _SplashMiniCoreState extends State<SplashMiniCore>
    with TickerProviderStateMixin {

  // Animación entrada MiniCore
  late AnimationController _miniController;
  late Animation<double> _miniFadeScale;

  // Shine APPS
  late AnimationController _shineController;
  late Animation<double> _shine;

  // Transición fondo híbrido
  late AnimationController _transitionController;
  late Animation<double> _finalSlide;
  late Animation<double> _meLoFade;
  late Animation<double> _taglineFade;
  late Animation<double> _buttonsFade;

  @override
  void initState() {
    super.initState();

    _initPush();  // 👈 ESTA LÍNEA
//    WidgetsBinding.instance.addPostFrameCallback((_) {
//      _initPush();
//      });
      
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

    _finalSlide = CurvedAnimation(
      parent: _transitionController,
      curve: const Cubic(0.22, 1, 0.36, 1),
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
  }


Future<void> _initPush() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    String? token = await messaging.getToken();
    debugPrint("FCM TOKEN: $token");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint("Foreground message: ${message.messageId}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint("Notification clicked: ${message.messageId}");
    });

  } catch (e) {
    debugPrint("Push init error: $e");
  }
}

  void _start() async {
    await _miniController.forward();
    _shineController.repeat();
    await Future.delayed(const Duration(milliseconds: 600));
    await _transitionController.forward();
  }

  @override
  void dispose() {
    _miniController.dispose();
    _shineController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  // ===============================
  // MINI CORE EN ESQUINA
  // ===============================
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
            crossAxisAlignment: CrossAxisAlignment.center,
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

  // ===============================
  // SHINE APPS
  // ===============================
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

  // ===============================
  // FONDO HÍBRIDO FINAL
  // ===============================
  Widget _buildHybridFinal() {
    return AnimatedBuilder(
      animation: _finalSlide,
      builder: (context, child) {
        return Opacity(
          opacity: _finalSlide.value,
          child: Transform.scale(
            scale: 1.05 - (_finalSlide.value * 0.05),
            child: Image.asset(
              "assets/logos/fondo_hibrido_final.png",
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        );
      },
    );
  }

  // ===============================
  // LOGO ME LO MEREZCO
  // ===============================
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
              child: Image.asset(
                "assets/logos/logo_me_lo_merezco_transparente.png",
                fit: BoxFit.fitWidth,
              ),
            ),
          ),
        );
      },
    );
  }

  // ===============================
  // TAGLINE (TU VERSIÓN INTACTA)
  // ===============================
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
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
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

  // ===============================
  // BOTONES AUTH
  // ===============================
Widget _buildAuthButtons() {
  return AnimatedBuilder(
    animation: _buttonsFade,
    builder: (context, child) {
      return Transform.translate(
        offset: Offset(0, 30 * (1 - _buttonsFade.value)),
        child: Opacity(
          opacity: _buttonsFade.value,
          child: Padding(
            padding: const EdgeInsets.only(top: 35),
            child: Column(
              children: [

                // ===============================
                // BOTÓN PRINCIPAL GLASS
                // ===============================
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.78,
                  height: 56,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      children: [

                        // BLUR REAL
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(),
                        ),

                        // CAPA GLASS
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.35),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                        ),

                        // CONTENIDO
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(32),
                            onTap: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            child: Center(
                              child: Text(
                                "INICIAR SESIÓN",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.2,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // ===============================
                // BOTÓN SECUNDARIO GLASS LIGHT
                // ===============================
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.78,
                  height: 56,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      children: [

                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(),
                        ),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                        ),

                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(32),
                            onTap: () {
                              Navigator.pushNamed(context, '/register');
                            },
                            child: Center(
                              child: Text(
                                "CREAR CUENTA",
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.1,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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

// ===============================
// LOGOS DECORATIVOS STORES
// ===============================
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

              // APPLE
              Image.asset(
                "assets/logos/apple_mini_white.png",
                height: 18,
                color: Colors.white.withOpacity(0.85),
              ),

              const SizedBox(width: 22),

              // GOOGLE PLAY
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


  // ===============================
  // BUILD
  // ===============================
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

          Positioned.fill(child: _buildHybridFinal()),

          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).size.height * 0.38,
            child: Column(
              children: [
                _buildMeLoMerezco(),
                _buildTagline(),
                _buildAuthButtons(),
                _buildStoreLogos(),
              ],
            ),
          ),

          _buildMiniCoreCorner(),
        ],
      ),
    );
  }

}