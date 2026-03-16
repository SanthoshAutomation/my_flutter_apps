import 'package:flutter/material.dart';

void main() {
  runApp(const TicTacToeApp());
}

class TicTacToeApp extends StatelessWidget {
  const TicTacToeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tic Tac Toe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const TicTacToeGame(),
    );
  }
}

class TicTacToeGame extends StatefulWidget {
  const TicTacToeGame({super.key});

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame>
    with TickerProviderStateMixin {
  List<String> _board = List.filled(9, '');
  String _currentPlayer = 'X';
  String _statusMessage = "Player X's Turn";
  bool _gameOver = false;
  List<int> _winningCells = [];
  int _scoreX = 0;
  int _scoreO = 0;
  int _draws = 0;

  late List<AnimationController> _cellControllers;
  late List<Animation<double>> _cellAnimations;
  late AnimationController _winController;
  late Animation<double> _winAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _cellControllers = List.generate(
      9,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _cellAnimations = _cellControllers
        .map(
          (c) => CurvedAnimation(parent: c, curve: Curves.elasticOut),
        )
        .toList();

    _winController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _winAnimation = CurvedAnimation(
      parent: _winController,
      curve: Curves.easeInOut,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    for (final c in _cellControllers) {
      c.dispose();
    }
    _winController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (_board[index].isNotEmpty || _gameOver) return;

    setState(() {
      _board[index] = _currentPlayer;
    });
    _cellControllers[index].forward(from: 0);

    final winner = _checkWinner();
    if (winner != null) {
      setState(() {
        _gameOver = true;
        _statusMessage = '🎉 Player $winner Wins!';
        if (winner == 'X') _scoreX++;
        if (winner == 'O') _scoreO++;
      });
      _winController.forward(from: 0);
      return;
    }

    if (!_board.contains('')) {
      setState(() {
        _gameOver = true;
        _statusMessage = "It's a Draw! 🤝";
        _draws++;
      });
      return;
    }

    setState(() {
      _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';
      _statusMessage = "Player $_currentPlayer's Turn";
    });
  }

  String? _checkWinner() {
    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];
    for (final line in lines) {
      if (_board[line[0]].isNotEmpty &&
          _board[line[0]] == _board[line[1]] &&
          _board[line[1]] == _board[line[2]]) {
        setState(() => _winningCells = line);
        return _board[line[0]];
      }
    }
    return null;
  }

  void _resetGame() {
    setState(() {
      _board = List.filled(9, '');
      _currentPlayer = 'X';
      _statusMessage = "Player X's Turn";
      _gameOver = false;
      _winningCells = [];
    });
    for (final c in _cellControllers) {
      c.reset();
    }
    _winController.reset();
  }

  void _resetScores() {
    setState(() {
      _scoreX = 0;
      _scoreO = 0;
      _draws = 0;
    });
    _resetGame();
  }

  Color get _currentPlayerColor =>
      _currentPlayer == 'X' ? const Color(0xFFFF6B9D) : const Color(0xFF4ECDC4);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
              Color(0xFF0F3460),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildTitle(),
              const SizedBox(height: 20),
              _buildScoreBoard(),
              const SizedBox(height: 24),
              _buildStatusBanner(),
              const SizedBox(height: 24),
              _buildBoard(),
              const SizedBox(height: 30),
              _buildButtons(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFFF6B9D), Color(0xFFFFE66D), Color(0xFF4ECDC4)],
      ).createShader(bounds),
      child: const Text(
        'TIC TAC TOE',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 6,
        ),
      ),
    );
  }

  Widget _buildScoreBoard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScoreCard('X', _scoreX, const Color(0xFFFF6B9D)),
          _buildDivider(),
          _buildScoreCard('DRAW', _draws, const Color(0xFFFFE66D)),
          _buildDivider(),
          _buildScoreCard('O', _scoreO, const Color(0xFF4ECDC4)),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String label, int score, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$score',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 50,
      width: 1,
      color: Colors.white.withValues(alpha: 0.15),
    );
  }

  Widget _buildStatusBanner() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _gameOver ? _pulseAnimation.value : 1.0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 28),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: _gameOver
                    ? [const Color(0xFFFF6B9D), const Color(0xFFFFE66D)]
                    : [
                        _currentPlayerColor.withValues(alpha: 0.3),
                        _currentPlayerColor.withValues(alpha: 0.15),
                      ],
              ),
              border: Border.all(
                color: _gameOver
                    ? const Color(0xFFFFE66D)
                    : _currentPlayerColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_gameOver
                          ? const Color(0xFFFF6B9D)
                          : _currentPlayerColor)
                      .withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.1),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: 9,
            itemBuilder: (context, index) => _buildCell(index),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int index) {
    final isWinning = _winningCells.contains(index);
    final value = _board[index];
    final isEmpty = value.isEmpty;

    return GestureDetector(
      onTap: () => _handleTap(index),
      child: AnimatedBuilder(
        animation: _cellAnimations[index],
        builder: (context, child) {
          return AnimatedBuilder(
            animation: _winAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isEmpty ? 1.0 : _cellAnimations[index].value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: _getCellGradient(value, isWinning),
                    boxShadow: [
                      if (isWinning)
                        BoxShadow(
                          color: (value == 'X'
                                  ? const Color(0xFFFF6B9D)
                                  : const Color(0xFF4ECDC4))
                              .withValues(alpha: 0.6 * _winAnimation.value),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(2, 4),
                      ),
                    ],
                    border: Border.all(
                      color: isWinning
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.1),
                      width: isWinning ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: isEmpty
                        ? null
                        : value == 'X'
                        ? _buildX(isWinning)
                        : _buildO(isWinning),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  LinearGradient _getCellGradient(String value, bool isWinning) {
    if (value == 'X') {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isWinning
            ? [const Color(0xFFFF6B9D), const Color(0xFFFF8E53)]
            : [
                const Color(0xFFFF6B9D).withValues(alpha: 0.25),
                const Color(0xFFFF8E53).withValues(alpha: 0.15),
              ],
      );
    } else if (value == 'O') {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isWinning
            ? [const Color(0xFF4ECDC4), const Color(0xFF44A8FF)]
            : [
                const Color(0xFF4ECDC4).withValues(alpha: 0.25),
                const Color(0xFF44A8FF).withValues(alpha: 0.15),
              ],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.white.withValues(alpha: 0.07),
        Colors.white.withValues(alpha: 0.03),
      ],
    );
  }

  Widget _buildX(bool isWinning) {
    return CustomPaint(
      size: const Size(48, 48),
      painter: XPainter(
        color: isWinning ? Colors.white : const Color(0xFFFF6B9D),
        strokeWidth: isWinning ? 5 : 4,
      ),
    );
  }

  Widget _buildO(bool isWinning) {
    return CustomPaint(
      size: const Size(48, 48),
      painter: OPainter(
        color: isWinning ? Colors.white : const Color(0xFF4ECDC4),
        strokeWidth: isWinning ? 5 : 4,
      ),
    );
  }

  Widget _buildButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildButton(
          label: 'New Game',
          icon: Icons.refresh_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B9D), Color(0xFFFF8E53)],
          ),
          onTap: _resetGame,
        ),
        const SizedBox(width: 16),
        _buildButton(
          label: 'Reset All',
          icon: Icons.delete_sweep_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF4ECDC4), Color(0xFF44A8FF)],
          ),
          onTap: _resetScores,
        ),
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class XPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  XPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final padding = size.width * 0.15;
    canvas.drawLine(
      Offset(padding, padding),
      Offset(size.width - padding, size.height - padding),
      paint,
    );
    canvas.drawLine(
      Offset(size.width - padding, padding),
      Offset(padding, size.height - padding),
      paint,
    );
  }

  @override
  bool shouldRepaint(XPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

class OPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  OPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * 0.7;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(OPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
