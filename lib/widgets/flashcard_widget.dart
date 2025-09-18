// ignore_for_file: deprecated_member_use, valid_regexps

import 'package:flutter/material.dart';
import 'dart:math';

class FlashcardWidget extends StatefulWidget {
  final String question;
  final String answer;
  final int index;
  final String? type; // mcq | true_false | fill_blank
  final List<String>? options; // for mcq
  final void Function(bool isCorrect)? onAnswered; // callback when user answers
  final bool initiallyAnswered; // persist-lock state across rebuilds

  const FlashcardWidget({
    super.key,
    required this.question,
    required this.answer,
    required this.index,
    this.type,
    this.options,
    this.onAnswered,
    this.initiallyAnswered = false,
  });

  @override
  State<FlashcardWidget> createState() => _FlashcardWidgetState();
}

class _FlashcardWidgetState extends State<FlashcardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isFlipped = false;
  bool _answered = false;
  bool? _isCorrect;
  int? _selectedIndex; // for mcq
  final TextEditingController _inputController = TextEditingController();

  // Extract just the raw answer value, stripping any leading "Answer:" label
  // and discarding any appended explanation after the first newline.
  String _extractCorrectAnswer(String full) {
    String s = full;
    s = s.replaceFirst(RegExp(r'^\s*Answer:\s*', caseSensitive: false), '');
    final newline = s.indexOf('\n');
    if (newline != -1) {
      s = s.substring(0, newline);
    }
    return s.trim();
  }

  // Normalize text for robust comparison: trim, lowercase, remove common
  // surrounding punctuation/quotes, and collapse whitespace.
  String _normalizeForCompare(String input) {
    var s = input;
    // Safely remove various straight/curly quotes without using a fragile regex
    const quoteChars = [
      '\u201C', // “
      '\u201D', // ”
      '\u2018', // ‘
      '\u2019', // ’
      '"', // double quote
      "'", // single quote
      '`', // backtick
    ];
    for (final q in quoteChars) {
      s = s.replaceAll(q, '');
    }
    s = s.trim();
    s = s.replaceAll(RegExp(r'[.,;:!?()\[\]{}<>]'), ' ');
    s = s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    // Respect persisted answered state so options remain disabled
    _answered = widget.initiallyAnswered;
  }

  @override
  void dispose() {
    _inputController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_controller.isAnimating) return;
    if (_isFlipped) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * -pi;
          final transform =
              Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle);

          final showingBack = _controller.value >= 0.5;
          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child:
                showingBack
                    ? _buildCardFace(
                      isFront: false,
                      transform: Matrix4.identity()..rotateY(pi),
                      title: 'Answer',
                      content: widget.answer,
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      icon: Icons.check_circle_outline,
                    )
                    : _buildCardFace(
                      isFront: true,
                      transform: Matrix4.identity(),
                      title: 'Question ${widget.index + 1}',
                      content: widget.question,
                      color: Colors.grey.shade100,
                      icon: Icons.help_outline,
                    ),
          );
        },
      ),
    );
  }

  Widget _buildCardFace({
    required bool isFront,
    required Matrix4 transform,
    required String title,
    required String content,
    required Color color,
    required IconData icon,
  }) {
    return Transform(
      transform: transform,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).primaryColor.withOpacity(0.8),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            SelectableText(
              content,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            if (isFront) ...[
              const SizedBox(height: 12),
              _buildInteractionArea(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionArea() {
    final type = widget.type;
    if (type == 'mcq') {
      final options = widget.options ?? const <String>[];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(options.length, (i) {
            final selected = _selectedIndex == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap:
                    _answered
                        ? null
                        : () {
                          setState(() => _selectedIndex = i);
                        },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        _answered
                            ? Colors.grey.shade100
                            : selected
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Colors.white,
                    border: Border.all(
                      color:
                          _answered
                              ? Colors.grey.shade300
                              : selected
                              ? Theme.of(context).primaryColor
                              : Colors.grey.shade300,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                _answered
                                    ? Colors.grey
                                    : selected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey,
                          ),
                          color:
                              _answered
                                  ? Colors.grey.shade200
                                  : selected
                                  ? Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1)
                                  : Colors.transparent,
                        ),
                        child:
                            selected && !_answered
                                ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          options[i],
                          style: TextStyle(
                            color:
                                _answered
                                    ? Colors.grey.shade600
                                    : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed:
                  (!_answered && _selectedIndex != null)
                      ? () {
                        final selectedText =
                            (widget.options ??
                                const <String>[])[_selectedIndex!];
                        final correctText = _extractCorrectAnswer(
                          widget.answer,
                        );
                        final isCorrect =
                            _normalizeForCompare(selectedText) ==
                            _normalizeForCompare(correctText);
                        setState(() {
                          _answered = true;
                          _isCorrect = isCorrect;
                        });
                        widget.onAnswered?.call(isCorrect);
                        Future.delayed(
                          const Duration(milliseconds: 200),
                          _flipCard,
                        );
                      }
                      : null,
              child: const Text('Submit'),
            ),
          ),
          if (_answered) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _isCorrect == true ? Icons.check_circle : Icons.cancel,
                  color: _isCorrect == true ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Text(
                  _isCorrect == true ? 'Correct!' : 'Incorrect',
                  style: TextStyle(
                    color: _isCorrect == true ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    if (type == 'true_false') {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _answered ? null : () => _handleTrueFalse(true),
              icon: const Icon(Icons.check),
              label: const Text('True'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _answered
                        ? Colors.grey.shade100
                        : Colors.green.withOpacity(0.1),
                foregroundColor: _answered ? Colors.grey : Colors.green[800],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _answered ? null : () => _handleTrueFalse(false),
              icon: const Icon(Icons.close),
              label: const Text('False'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _answered
                        ? Colors.grey.shade100
                        : Colors.red.withOpacity(0.1),
                foregroundColor: _answered ? Colors.grey : Colors.red[800],
              ),
            ),
          ),
        ],
      );
    }

    // fill_blank or unknown: simple input + check
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _inputController,
            enabled: !_answered,
            decoration: const InputDecoration(
              hintText: 'Type your answer',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed:
              _answered
                  ? null
                  : () {
                    final guess = _inputController.text;
                    final correct = _extractCorrectAnswer(widget.answer);
                    final isCorrect =
                        _normalizeForCompare(guess) ==
                        _normalizeForCompare(correct);
                    setState(() {
                      _answered = true;
                      _isCorrect = isCorrect;
                    });
                    widget.onAnswered?.call(isCorrect);
                    Future.delayed(
                      const Duration(milliseconds: 200),
                      _flipCard,
                    );
                  },
          child: const Text('Check'),
        ),
      ],
    );
  }

  void _handleTrueFalse(bool userChoice) {
    final correctStr = _normalizeForCompare(
      _extractCorrectAnswer(widget.answer),
    );
    final correct = correctStr == 'true';
    final isCorrect = userChoice == correct;
    setState(() {
      _answered = true;
      _isCorrect = isCorrect;
    });
    widget.onAnswered?.call(isCorrect);
    Future.delayed(const Duration(milliseconds: 200), _flipCard);
  }
}
