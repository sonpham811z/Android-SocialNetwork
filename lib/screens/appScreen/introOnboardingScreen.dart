import 'package:flutter/material.dart';

import '../../config/theme.dart';

class IntroOnboardingScreen extends StatefulWidget {
  final Future<void> Function() onCompleted;

  const IntroOnboardingScreen({
    super.key,
    required this.onCompleted,
  });

  @override
  State<IntroOnboardingScreen> createState() => _IntroOnboardingScreenState();
}

class _IntroOnboardingScreenState extends State<IntroOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isCompleting = false;

  final List<_IntroSlide> _slides = const [
    _IntroSlide(
      imagePath: 'assets/images/logo_app.png',
      title: 'Welcome to Zest',
      description: 'Kham pha cong dong, ket noi va chia se moi khoanh khac cua ban.',
    ),
    _IntroSlide(
      imagePath: 'assets/images/anh.png',
      title: 'Dang Bai De Dang',
      description: 'Viet status, them anh va tro chuyen voi ban be trong vai giay.',
    ),
    _IntroSlide(
      imagePath: 'assets/images/google_logo.png',
      title: 'Theo Doi Tuong Tac',
      description: 'Nhan thong bao, like, comment va giu lien lac moi luc moi noi.',
    ),
    _IntroSlide(
      imagePath: 'assets/images/logo_app.png',
      title: 'San Sang Chua?',
      description: 'Luot het 4 anh intro, Zest se dua ban vao bang tin ngay.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeIfLast() async {
    if (_isCompleting) {
      return;
    }
    if (_currentIndex != _slides.length - 1) {
      return;
    }

    _isCompleting = true;
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) {
      return;
    }
    await widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F10) : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                  _completeIfLast();
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(28),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? const [Color(0xFF1B1D22), Color(0xFF111318)]
                                    : const [Color(0xFFF4F7FF), Color(0xFFEAF1FF)],
                              ),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withOpacity(0.06)
                                    : AppTheme.slate200,
                              ),
                            ),
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              children: [
                                Expanded(
                                  child: Hero(
                                    tag: 'intro-image-$index',
                                    child: Image.asset(
                                      slide.imagePath,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  slide.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : AppTheme.slate900,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  slide.description,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                    color: isDark ? AppTheme.slate400 : AppTheme.slate600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 20 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? AppTheme.violetPrimary
                        : (isDark ? AppTheme.slate700 : AppTheme.slate300),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
              child: Row(
                children: [
                  if (_currentIndex < _slides.length - 1)
                    TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          _slides.length - 1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      },
                      child: const Text('Bo qua'),
                    )
                  else
                    Text(
                      _isCompleting ? 'Dang vao bang tin...' : 'Dang vao bang tin...',
                      style: TextStyle(
                        color: isDark ? AppTheme.slate500 : AppTheme.slate600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _currentIndex == _slides.length - 1
                        ? null
                        : () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeOut,
                            );
                          },
                    child: const Text('Tiep'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroSlide {
  final String imagePath;
  final String title;
  final String description;

  const _IntroSlide({
    required this.imagePath,
    required this.title,
    required this.description,
  });
}
