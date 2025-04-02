import 'dart:math' as math;
import 'dart:ui';

import 'package:digital_library/core/app_colors.dart';
import 'package:digital_library/screens/enter_email.dart';
import 'package:digital_library/screens/pdf_viewer_screen.dart';
import 'package:digital_library/widgets/book_card.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/book.dart';

class BookshelfScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;
  final Map<String, Book> selectedBooks;
  final bool isCheckout;

  const BookshelfScreen({
    super.key,
    this.categoryId,
    this.categoryName,
    required this.selectedBooks,
    this.isCheckout = false,
  });

  @override
  State<BookshelfScreen> createState() => _BookshelfScreenState();
}

class _BookshelfScreenState extends State<BookshelfScreen>
    with TickerProviderStateMixin {
  late List<Book> _books = [];
  List<Book> _cart = [];
  final GlobalKey _cartKey = GlobalKey();
  late AnimationController _cartAnimationController;
  late Animation<Offset> _cartSlideAnimation;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  // Book falling animation
  late AnimationController _bookFallController;
  late Animation<double> _bookFallAnimation;
  Book? _fallingBook;
  Offset? _startPosition;
  Offset? _endPosition;
  String _cartImage = "assets/images/empty_cart.png";

  @override
  void initState() {
    super.initState();
    _cart = widget.selectedBooks.values.toList();

    _cartAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _cartSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),
      end: const Offset(8.5, 0),
    ).animate(CurvedAnimation(
      parent: _cartAnimationController,
      curve: Curves.easeInOutBack,
    ));

    // Book falling animation
    _bookFallController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    // Add curved animation
    _bookFallAnimation = CurvedAnimation(
      parent: _bookFallController,
      curve: Curves.easeIn,
    );

    _bookFallController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _fallingBook = null;
          _startPosition = null;
          _endPosition = null;
        });
      }
    });

    _updateCartImage();

    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get books from the 'books' table
      var query = Supabase.instance.client.from('books').select();

      // If categoryId is provided, filter by it
      if (widget.categoryId != null) {
        query = query.filter('category_id', 'eq', widget.categoryId);
      }

      final response = await query.order('created_at');

      // Get list of files from the 'books' bucket
      final List<FileObject> pdfFiles =
          await Supabase.instance.client.storage.from('books').list();

      _books = response.map((book) {
        final pdfFile = pdfFiles.firstWhere(
          (file) => file.name == book['pdf_filename'],
          orElse: () =>
              throw Exception('PDF file not found: ${book["pdf_filename"]}'),
        );

        return Book(
          id: book['id'],
          title: book['title'],
          category: book['category'],
          coverColor: Color(int.parse(book['cover_color'])),
          // Check if book is in selectedBooks map
          isSelected: widget.selectedBooks.containsKey(book['id']),
          pdfPath: pdfFile.name,
        );
      }).toList();

      // If this is checkout mode, only show selected books
      if (widget.isCheckout) {
        _books = _books
            .where((book) => widget.selectedBooks.containsKey(book.id))
            .toList();
        // Add selected books to cart
        _cart.addAll(_books);
      }
    } catch (e) {
      debugPrint('Error loading books: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load books: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleBackNavigation() {
    final Map<String, Book> selectedBooks = {
      for (var book in _cart) book.id: book
    };
    Navigator.of(context).pop<Map<String, Book>>(selectedBooks);
  }

  void _selectBook(Book book, Offset bookPosition) {
    final RenderBox? cartBox =
        _cartKey.currentContext?.findRenderObject() as RenderBox?;
    if (cartBox == null) return;

    final cartPosition = cartBox.localToGlobal(Offset.zero);
    final cartCenter = Offset(
      cartPosition.dx + cartBox.size.width / 2,
      cartPosition.dy + cartBox.size.height / 2,
    );

    setState(() {
      final index = _books.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        _books[index] = _books[index].copyWith(isSelected: true);
      }

      _fallingBook = book;
      _startPosition = bookPosition;
      _endPosition = cartCenter;

      _bookFallController.reset();
      _bookFallController.forward().then((_) {
        setState(() {
          if (!_cart.any((b) => b.id == book.id)) {
            _cart.add(book);
          }
          _updateCartImage();
          _fallingBook = null;
        });
      });
    });
  }

  void _toggleCartView() {
    showDialog(
      context: context,
      builder: (context) => SizedBox(
        child: AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: AppColors.primary, width: 3)),
          title: Text('Your Cart'),
          content: Container(
            width: 600,
            constraints: BoxConstraints(maxHeight: 400),
            child: _cart.isEmpty
                ? Center(
                    child: Text(
                      'Your cart is empty',
                      style: TextStyle(
                        color: Colors.black87,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final book = _cart[index];
                      return ListTile(
                        leading: Image.asset("assets/images/pdf_icon.png",
                            height: 40),
                        title: Text(
                          book.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _removeFromCart(book);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _updateCartImage() {
    setState(() {
      if (_cart.isEmpty) {
        _cartImage = "assets/images/empty_cart.png";
      } else if (_cart.length == 1) {
        _cartImage = "assets/images/single_pdf.png";
      } else {
        _cartImage = "assets/images/multiple_pdfs.png";
      }
    });
  }

  void _removeFromCart(Book book) {
    setState(() {
      _cart.removeWhere((b) => b.id == book.id);
      final index = _books.indexWhere((b) => b.id == book.id);
      if (index != -1) {
        _books[index] = _books[index].copyWith(isSelected: false);
      }
      _updateCartImage();
    });
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one book'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      await _cartAnimationController.forward();

      // Add delay before navigation
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        // Create a map of selected books from the cart
        final Map<String, Book> selectedBooks = {
          for (var book in _cart) book.id: book
        };

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => EnterEmail(
              selectedBooks: selectedBooks, // Pass the selected books here
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send email: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _cartAnimationController.dispose();
    _bookFallController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        _handleBackNavigation();
        return Future.value(false);
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              "assets/images/category_screen_bg.jpg",
              fit: BoxFit.cover,
            ),
            Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(color: AppColors.white),
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Row(
                        children: [
                          if (!widget.isCheckout)
                            IconButton(
                              icon: Icon(
                                Icons.arrow_back,
                                color: AppColors.primary,
                                size: 30,
                              ),
                              onPressed: _handleBackNavigation,
                            ),
                          SizedBox(width: 30),
                          Image.asset(
                            "assets/images/tata_logo.png",
                            height: 80,
                          ),
                          Spacer(),
                          Image.asset(
                            "assets/images/logo.png",
                            height: 70,
                          ),
                          SizedBox(width: 40),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.09,
                  decoration: BoxDecoration(color: AppColors.primary),
                  child: Text(
                    "Leadership Forum 2025",
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white),
                  ),
                ),
                Expanded(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 03.0,
                        sigmaY: 03.0,
                      ),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        width: MediaQuery.of(context).size.width * 0.9,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(40),
                            bottomRight: Radius.circular(40),
                          ),
                          color: AppColors.white.withValues(alpha: 0.2),
                          border: Border(
                            left: BorderSide(
                                color: AppColors.white.withValues(alpha: 0.5),
                                width: 4),
                            right: BorderSide(
                                color: AppColors.white.withValues(alpha: 0.5),
                                width: 4),
                            bottom: BorderSide(
                                color: AppColors.white.withValues(alpha: 0.5),
                                width: 4),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10.0),
                              child: Text(
                                "Please select the PDFs you would like to receive in your inbox",
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                            _isLoading
                                ? Center(
                                    child: CircularProgressIndicator(
                                    color: AppColors.white,
                                  ))
                                : Stack(
                                    children: [
                                      Column(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12),
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.425,
                                            child: ScrollbarTheme(
                                              data: ScrollbarThemeData(
                                                  mainAxisMargin: 10,
                                                  radius: Radius.circular(20),
                                                  trackColor:
                                                      WidgetStateProperty.all(
                                                          Colors.transparent),
                                                  thumbColor:
                                                      WidgetStateProperty.all(
                                                          AppColors.white)),
                                              child: Scrollbar(
                                                trackVisibility: true,
                                                controller: _scrollController,
                                                thickness: 5,
                                                radius: Radius.circular(8),
                                                thumbVisibility: true,
                                                child: ListView(
                                                  controller: _scrollController,
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  children: [
                                                    Row(
                                                      children: List.generate(
                                                        _books.length,
                                                        (index) => Padding(
                                                          padding:
                                                              EdgeInsets.all(8),
                                                          child: Column(
                                                            children: [
                                                              BookCard(
                                                                key: GlobalKey(
                                                                    debugLabel:
                                                                        'book_card_$index'),
                                                                book: _books[
                                                                    index],
                                                                onSelect: (book,
                                                                        position) =>
                                                                    _selectBook(
                                                                        book,
                                                                        position),
                                                              ),
                                                              SizedBox(
                                                                height: 8,
                                                              ),
                                                              ElevatedButton
                                                                  .icon(
                                                                style: ElevatedButton.styleFrom(
                                                                    minimumSize:
                                                                        Size(195,
                                                                            34),
                                                                    backgroundColor:
                                                                        Colors
                                                                            .white,
                                                                    shape: RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.zero)),
                                                                onPressed: () {
                                                                  if (_books[
                                                                          index]
                                                                      .isSelected) {
                                                                    // Remove from cart
                                                                    _removeFromCart(
                                                                        _books[
                                                                            index]);
                                                                  } else {
                                                                    // Add to cart
                                                                    final RenderBox
                                                                        bookCardBox =
                                                                        (context.findRenderObject() as RenderBox).parent
                                                                            as RenderBox;
                                                                    final position =
                                                                        bookCardBox
                                                                            .localToGlobal(Offset.zero);
                                                                    _selectBook(
                                                                        _books[
                                                                            index],
                                                                        position);
                                                                  }
                                                                },
                                                                label: Row(
                                                                  children: [
                                                                    Text(
                                                                        _books[index].isSelected
                                                                            ? "Delete from Cart"
                                                                            : "Add to Cart",
                                                                        style: TextStyle(
                                                                            color:
                                                                                AppColors.primary)),
                                                                    SizedBox(
                                                                        width:
                                                                            6),
                                                                    Icon(
                                                                      _books[index].isSelected
                                                                          ? Icons
                                                                              .remove_shopping_cart
                                                                          : Icons
                                                                              .shopping_cart,
                                                                      color: AppColors
                                                                          .primary,
                                                                    )
                                                                  ],
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                height: 8,
                                                              ),
                                                              ElevatedButton
                                                                  .icon(
                                                                style: ElevatedButton.styleFrom(
                                                                    minimumSize:
                                                                        Size(195,
                                                                            34),
                                                                    backgroundColor:
                                                                        Colors
                                                                            .white,
                                                                    shape: RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.zero)),
                                                                onPressed: () {
                                                                  Navigator
                                                                      .push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              PDFViewerScreen(
                                                                        pdfPath:
                                                                            _books[index].pdfPath,
                                                                        title: _books[index]
                                                                            .title,
                                                                      ),
                                                                    ),
                                                                  );
                                                                },
                                                                label: Row(
                                                                  children: [
                                                                    Text(
                                                                        "View PDF",
                                                                        style: TextStyle(
                                                                            color:
                                                                                AppColors.primary)),
                                                                    SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                    Icon(
                                                                      Icons
                                                                          .remove_red_eye,
                                                                      color: AppColors
                                                                          .primary,
                                                                    )
                                                                  ],
                                                                ),
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(height: 48),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SlideTransition(
                                                position: _cartSlideAnimation,
                                                child: GestureDetector(
                                                  onTap: _toggleCartView,
                                                  child: Image.asset(
                                                    key: _cartKey,
                                                    _cartImage,
                                                    width: 120,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => _checkout(),
                                                style: ElevatedButton.styleFrom(
                                                  elevation: 0,
                                                  backgroundColor: AppColors
                                                      .white
                                                      .withValues(alpha: 0.4),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.zero,
                                                    side: BorderSide(
                                                      color: AppColors.white,
                                                      width: 2.0,
                                                    ),
                                                  ),
                                                ),
                                                child: Text(
                                                  "Checkout",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.black,
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              )
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Falling book animation
                                      if (_fallingBook != null &&
                                          _startPosition != null &&
                                          _endPosition != null)
                                        AnimatedBuilder(
                                          animation: _bookFallAnimation,
                                          builder: (context, child) {
                                            final double t =
                                                _bookFallAnimation.value;

                                            // Calculate horizontal movement with easing
                                            final double xProgress =
                                                Curves.easeInOut.transform(t);
                                            final double x = _startPosition!
                                                    .dx +
                                                (_endPosition!.dx -
                                                        _startPosition!.dx) *
                                                    xProgress;

                                            // Improve vertical movement with adjusted parabolic curve
                                            final double yDistance =
                                                _endPosition!.dy -
                                                    _startPosition!.dy;

                                            // Adjust the parabola height based on horizontal distance
                                            final double horizontalDistance =
                                                (_endPosition!.dx -
                                                        _startPosition!.dx)
                                                    .abs();
                                            final double parabolaHeight =
                                                horizontalDistance *
                                                    0.5; // Adjust this multiplier as needed

                                            // Create smoother parabolic motion
                                            final double parabolicT =
                                                -(t * (t - 1));
                                            final double y =
                                                _startPosition!.dy +
                                                    yDistance * t -
                                                    parabolicT * parabolaHeight;

                                            // Add slight rotation based on direction
                                            final double direction =
                                                _endPosition!.dx <
                                                        _startPosition!.dx
                                                    ? 1
                                                    : -1;
                                            final double rotation =
                                                direction * t * math.pi * 0.75;

                                            return Positioned(
                                              left: x - 125,
                                              top: y - 250,
                                              child: Transform.rotate(
                                                angle: rotation,
                                                child: Opacity(
                                                  opacity: 1.0 - (0.99 * t),
                                                  child: SizedBox(
                                                    width: 50,
                                                    height: 90,
                                                    child: Image.asset(
                                                        "assets/images/pdf_icon.png"),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
              ],
            )
          ],
        ),
      ),
    );
  }
}
