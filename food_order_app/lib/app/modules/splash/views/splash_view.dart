import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF120804),
      body: Stack(
        children: [
          // Deep Luxury Gourmet Gradient Background
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.0, -0.2),
                  radius: 1.2,
                  colors: [
                    Color(0xFF2E1308), // Rich warm roast espresso
                    Color(0xFF1A0B05),
                    Color(0xFF0F0502), // Deep charcoal black
                  ],
                ),
              ),
            ),
          ),

          // Ambient Warm Golden Glow behind logo
          Positioned(
            top: size.height * 0.22,
            left: (size.width - 340) / 2,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFF9E1B).withOpacity(0.22),
                    const Color(0xFFD4AF37).withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1.18, 1.18),
                  duration: 2600.ms,
                  curve: Curves.easeInOut,
                ),
          ),

          // Floating Decorative Golden Spice Particles
          Positioned(
            top: size.height * 0.12,
            right: 40,
            child: _buildSparkle(16, const Color(0xFFFFD54F))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -14, duration: 2200.ms, curve: Curves.easeInOut)
                .fadeIn(duration: 800.ms),
          ),
          Positioned(
            top: size.height * 0.28,
            left: 36,
            child: _buildSparkle(12, const Color(0xFFFFB300))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: 12, duration: 2800.ms, curve: Curves.easeInOut)
                .fadeIn(duration: 800.ms, delay: 200.ms),
          ),
          Positioned(
            bottom: size.height * 0.26,
            right: 50,
            child: _buildSparkle(10, const Color(0xFFFFCC80))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -10, duration: 2400.ms, curve: Curves.easeInOut)
                .fadeIn(duration: 800.ms, delay: 400.ms),
          ),
          Positioned(
            bottom: size.height * 0.20,
            left: 45,
            child: _buildSparkle(14, const Color(0xFFD4AF37))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: 14, duration: 2600.ms, curve: Curves.easeInOut)
                .fadeIn(duration: 800.ms, delay: 300.ms),
          ),

          // Main Center Content
          SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // Hero Restaurant Logo Emblem
                  _buildHeroLogo(size),

                  const SizedBox(height: 32),

                  // Brand Title: SPICE HAVEN
                  Text(
                    'SPICE HAVEN',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 4.5,
                      color: const Color(0xFFFFF8F0),
                      shadows: [
                        Shadow(
                          color: const Color(0xFFFF8F00).withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 2),
                        ),
                        Shadow(
                          color: Colors.black.withOpacity(0.8),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 800.ms, delay: 350.ms)
                      .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 12),

                  // Elegant Gold Flourish Divider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 38,
                        height: 1.2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFD4AF37).withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(
                          Icons.eco_rounded,
                          size: 14,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 1.2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFD4AF37).withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 700.ms, delay: 500.ms)
                      .scale(begin: const Offset(0.5, 1.0), end: const Offset(1.0, 1.0)),

                  const SizedBox(height: 12),

                  // Official Tagline
                  Text(
                    'GOOD FOOD BRIGHTER DAYS',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3.2,
                      color: const Color(0xFFFFD199),
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.7),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 700.ms, delay: 650.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 22),

                  // Refined Pill Feature Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withOpacity(0.35),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.restaurant_rounded,
                          size: 13,
                          color: Color(0xFFFF9E1B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'FINE DINING • ARTISAN CUISINE',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.8,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 850.ms)
                      .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack),

                  const Spacer(flex: 4),

                  // Luxury Shimmer Dot Loader
                  _buildLuxuryLoader(),

                  const SizedBox(height: 18),

                  // Bottom subtle footer
                  Text(
                    'Crafted with passion for authentic taste',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.8,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 1100.ms),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroLogo(Size size) {
    final double logoSize = (size.width * 0.48).clamp(180.0, 230.0);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer Glowing Aura Ring
        Container(
          width: logoSize + 36,
          height: logoSize + 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFFFFB300).withOpacity(0.28),
                const Color(0xFFD4AF37).withOpacity(0.12),
                Colors.transparent,
              ],
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1.12, 1.12),
              duration: 2000.ms,
              curve: Curves.easeInOut,
            ),

        // Double Gold Border Frame Container
        Container(
          width: logoSize + 12,
          height: logoSize + 12,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFDF7D), // Shimmering light gold
                Color(0xFFD4AF37), // Pure gold
                Color(0xFF8C581E), // Deep bronze
                Color(0xFFF7D070),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF9E1B).withOpacity(0.35),
                blurRadius: 36,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.65),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF1E0E06),
            ),
            // Logo Image Clip
            child: ClipOval(
              child: Container(
                color: const Color(0xFFFFFDF8), // Matching ivory logo tone
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF2A1508),
                      child: const Center(
                        child: Icon(
                          Icons.restaurant_menu_rounded,
                          size: 72,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        )
            .animate()
            .scale(
              duration: 900.ms,
              curve: Curves.easeOutBack,
              begin: const Offset(0.65, 0.65),
              end: const Offset(1.0, 1.0),
            )
            .fadeIn(duration: 700.ms)
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: 0,
              end: -6,
              duration: 2400.ms,
              curve: Curves.easeInOut,
            ),
      ],
    );
  }

  Widget _buildSparkle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.7),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: size * 1.5,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildLuxuryLoader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFDF7D), Color(0xFFD4AF37)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.6),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .scale(
              delay: Duration(milliseconds: 200 * index),
              duration: 650.ms,
              begin: const Offset(0.5, 0.5),
              end: const Offset(1.3, 1.3),
              curve: Curves.easeInOut,
            )
            .then()
            .scale(
              duration: 650.ms,
              begin: const Offset(1.3, 1.3),
              end: const Offset(0.5, 0.5),
              curve: Curves.easeInOut,
            );
      }),
    ).animate().fadeIn(duration: 600.ms, delay: 950.ms);
  }
}
