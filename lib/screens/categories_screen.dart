import 'dart:ui';

import 'package:digital_library/core/app_colors.dart';
import 'package:digital_library/models/book.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bookshelf_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({
    super.key,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();
    _loadCategories();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _categories = [];
  // Change to store more information about selected books
  final Map<String, Book> _selectedBooks = {};

  final Map<String, String> categoryImages = {
    'Transportation': 'assets/images/transportation.jpg',
    'PXI Platforms & Modules': 'assets/images/pxi.jpg',
    'Aerospace & Defence': 'assets/images/aerospace.jpg',
    'Electrical Machinery, Life Sciences & Energy':
        'assets/images/electrical.jpg',
    'NI Hardware Platforms': 'assets/images/ni_hardware.jpg',
    'NI Software Platforms': 'assets/images/ni_software.jpg',
    'Semiconductor & Electronics': 'assets/images/semiconductor.jpg',
  };

  Future<void> _loadCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('categories')
          .select()
          .order('created_at', ascending: true);

      setState(() {
        _categories = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load categories: $e')),
        );
      }
    }
  }

  void _onCategorySelected(Map<String, dynamic> category) async {
    final result = await Navigator.push<Map<String, Book>>(
      context,
      MaterialPageRoute(
        builder: (context) => BookshelfScreen(
          categoryId: category['id'],
          categoryName: category['name'],
          selectedBooks: _selectedBooks,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        // Update instead of clear and add
        _selectedBooks.addAll(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scaffold(
          body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            "assets/images/category_screen_bg.jpg",
            fit: BoxFit.cover,
          ),
          Column(children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(color: AppColors.white),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset(
                          "assets/images/tata_logo.png",
                          height: 80,
                        ),
                        Image.asset(
                          "assets/images/logo.png",
                          height: 70,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.08,
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
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 03.0,
                    sigmaY: 03.0,
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    width: MediaQuery.of(context).size.width * 0.9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      color: AppColors.white.withValues(alpha: 0.4),
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Please select the category you would like to know more about",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                            color: AppColors.white,
                          ),
                        ),
                        GridView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            shrinkWrap: true,
                            itemCount: _categories.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 6,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    mainAxisExtent: 300),
                            itemBuilder: (context, index) {
                              final category = _categories[index];
                              return InkWell(
                                  onTap: () => _onCategorySelected(category),
                                  child: Container(
                                    margin: EdgeInsets.symmetric(vertical: 16),
                                    padding: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: AppColors.white, width: 3),
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.transparent,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            // borderRadius: BorderRadius.only(
                                            //     topLeft: Radius.circular(14),
                                            //     topRight: Radius.circular(14)),
                                            child: Image.asset(
                                              categoryImages[_categories[index]
                                                      ['name']] ??
                                                  'assets/images/pdf_icon.png',
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: 140,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Image.asset(
                                                  'assets/images/pdf_icon.png',
                                                  fit: BoxFit.cover,
                                                  height: 140,
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8.0),
                                            child: Text(
                                              textAlign: TextAlign.center,
                                              _categories[index]['name']!,
                                              style: TextStyle(
                                                height: 1.1,
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.secondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ));
                            }),
                        Image.asset("assets/images/shelf.png"),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30),
          ]),
        ],
      )),
    );
  }
}
