import 'package:flutter/material.dart';

class Book {
  final String id;
  final String title;
  final String category;
  final Color coverColor;
  final bool isSelected;
  final String pdfPath;

  Book({
    required this.id,
    required this.title,
    required this.category,
    required this.coverColor,
    required this.isSelected,
    required this.pdfPath,
  });

  Book copyWith({
    String? id,
    String? title,
    String? category,
    Color? coverColor,
    bool? isSelected,
    String? pdfPath,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      coverColor: coverColor ?? this.coverColor,
      isSelected: isSelected ?? this.isSelected,
      pdfPath: pdfPath ?? this.pdfPath,
    );
  }
}
