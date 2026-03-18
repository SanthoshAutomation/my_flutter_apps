import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final StorageService storage;
  const OnboardingScreen({super.key, required this.storage});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  final _apiKeyController = TextEditingController();
  int _currentPage = 0;
  bool _isApiKeyVisible = false;
  bool _isSaving = false;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      emoji: '🇩🇪',
      title: 'Willkommen!\nWelcome!',
      subtitle: 'Your personal AI German teacher is here.\nLearn German the smart way — every single day.',
      color: const Color(0xFF1a1a2e),
    ),
    _OnboardingPage(
      emoji: '🤖',
      title: 'AI-Powered\nLessons',
      subtitle: 'Get custom lessons, homework, audio practice, and feedback — all powered by Claude AI.',
      color: const Color(0xFF16213e),
    ),
    _OnboardingPage(
      emoji: '🔥',
      title: 'Track Your\nProgress',
      subtitle: 'Build streaks, earn XP, level up from A1 to C2.\nBreak your limits every day.',
      color: const Color(0xFF0f3460),
    ),
    _OnboardingPage(
      emoji: '🔑',
      title: 'Enter Your\nClaude API Key',
      subtitle: 'Get your free API key at console.anthropic.com\nYour key stays on your device only.',
      color: const Color(0xFF533483),
      isApiKeyPage: true,
    ),
  ];

  Future<void> _finish() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your Claude API key to continue'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);
    await widget.storage.saveApiKey(key);
    await widget.storage.setOnboardingComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomeScreen(storage: widget.storage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _pages.length,
            itemBuilder: (_, i) => _buildPage(_pages[i]),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Page indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i
                            ? Colors.white
                            : Colors.white30,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _currentPage == _pages.length - 1
                      ? _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : ElevatedButton(
                              onPressed: _finish,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                minimumSize: const Size(double.infinity, 56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Start Learning! 🚀',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                      : ElevatedButton(
                          onPressed: () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Weiter →',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: page.color,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(page.emoji, style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 32),
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              if (page.isApiKeyPage) ...[
                const SizedBox(height: 32),
                TextField(
                  controller: _apiKeyController,
                  obscureText: !_isApiKeyVisible,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'sk-ant-...',
                    labelStyle: const TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isApiKeyVisible ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white54,
                      ),
                      onPressed: () =>
                          setState(() => _isApiKeyVisible = !_isApiKeyVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Get your key at console.anthropic.com',
                  style: TextStyle(
                    color: Colors.blue[300],
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.blue[300],
                  ),
                ),
              ],
              const SizedBox(height: 120), // Space for bottom buttons
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }
}

class _OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final bool isApiKeyPage;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    this.isApiKeyPage = false,
  });
}
