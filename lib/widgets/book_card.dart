// ignore_for_file: unused_field

import 'package:digital_library/core/app_colors.dart';
import 'package:flutter/material.dart';

import '../models/book.dart';

class BookCard extends StatefulWidget {
  final Book book;
  final Function(Book, Offset) onSelect;
  final bool isAnimating;

  const BookCard({
    super.key,
    required this.book,
    required this.onSelect,
    this.isAnimating = false,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _hoverController,
        curve: Curves.easeOut,
      ),
    );

    _elevationAnimation = Tween<double>(begin: 4.0, end: 8.0).animate(
      CurvedAnimation(
        parent: _hoverController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovering) {
    if (!widget.book.isSelected && !widget.isAnimating) {
      setState(() {
        _isHovering = isHovering;
      });

      if (isHovering) {
        _hoverController.forward();
      } else {
        _hoverController.reverse();
      }
    }
  }

  void _onTap() {
    if (!widget.book.isSelected && !widget.isAnimating) {
      final RenderBox box = context.findRenderObject() as RenderBox;
      final position = box.localToGlobal(Offset.zero);
      widget.onSelect(widget.book, position);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.isAnimating ? 1.0 : _scaleAnimation.value,
              child: Container(
                width: 190,
                height: 230,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.white, width: 3),
                ),
                child: Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12)),
                            width: double.infinity,
                            child: Image.asset(
                              "assets/images/pdf_icon.png",
                              height: 100,
                            ),
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Text(
                            textAlign: TextAlign.center,
                            widget.book.title,
                            style: const TextStyle(
                              height: 1.25,
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Selected overlay
                    if (widget.book.isSelected)
                      Container(
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
