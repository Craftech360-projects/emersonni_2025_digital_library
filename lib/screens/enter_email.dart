import 'dart:ui';

import 'package:digital_library/core/app_colors.dart';
import 'package:digital_library/models/book.dart';
import 'package:digital_library/screens/confirmation_screen.dart';
import 'package:digital_library/services/email.dart';
import 'package:flutter/material.dart';
import 'package:virtual_keyboard_multi_language/virtual_keyboard_multi_language.dart';

class EnterEmail extends StatefulWidget {
  final Map<String, Book> selectedBooks;
  const EnterEmail({
    super.key,
    required this.selectedBooks,
  });

  @override
  State<EnterEmail> createState() => _EnterEmailState();
}

class _EnterEmailState extends State<EnterEmail> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  final _emailService = EmailService();
  bool _showKeyboard = false;

  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    String pattern = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
    RegExp regex = RegExp(pattern);
    if (!regex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Extract book IDs and details
      final List<String> bookIds = widget.selectedBooks.keys.toList();
      final List<Map<String, dynamic>> bookDetails = widget.selectedBooks.values
          .map((book) => {
                'id': book.id,
                'title': book.title,
              })
          .toList();


      // Send email with download link
      await _emailService.sendDownloadEmail(
        toEmail: email,
        bookIds: bookIds,
        bookDetails: bookDetails,
      );

      // Navigate to confirmation screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationScreen(
              bookCount: widget.selectedBooks.length,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send email: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        Image.asset(
          "assets/images/category_screen_bg.jpg",
          fit: BoxFit.cover,
        ),
        if (_isLoading)
          Center(
            child: CircularProgressIndicator(
              color: AppColors.white,
            ),
          ),
        Column(
          children: [
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
            SizedBox(
              height: 60,
            ),
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 10.0,
                  sigmaY: 10.0,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  width: MediaQuery.of(context).size.width * 0.7,
                  height: MediaQuery.of(context).size.height * 0.65,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: AppColors.white.withValues(alpha: 0.4),
                      border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.5),
                          width: 4)),
                  child: SizedBox(
                    width: 600,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Enter Your Email to Receive the PDFs",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 26),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: 500,
                          child: TextField(
                            controller: _emailController,
                            readOnly: true,
                            onTap: () {
                              setState(() {
                                _showKeyboard = true;
                              });
                            },
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.mail),
                              hintText: 'Enter email',
                              hintStyle: TextStyle(color: AppColors.black),
                              filled: true,
                              fillColor: AppColors.white,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: AppColors.white, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: AppColors.white, width: 2),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.red, width: 2),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.red, width: 2),
                              ),
                            ),
                            style: TextStyle(color: AppColors.black),
                            keyboardType: TextInputType.emailAddress,
                            autocorrect: false,
                            onChanged: (value) {
                              String pattern =
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
                              RegExp regex = RegExp(pattern);
                              if (!regex.hasMatch(value)) {
                                // Handle invalid email
                              }
                            },
                            onSubmitted: (value) {
                              if (value.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Please enter your email')),
                                );
                                return;
                              }
                              String pattern =
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
                              RegExp regex = RegExp(pattern);
                              if (!regex.hasMatch(value)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text('Please enter a valid email')),
                                );
                                return;
                              }
                              // Handle valid email submission here
                            },
                          ),
                        ),
                        SizedBox(
                          height: 30,
                        ),
                        if (_showKeyboard)
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.4,
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: VirtualKeyboard(
                              height: MediaQuery.of(context).size.height * 0.4,
                              textColor: Colors.black,
                              fontSize: 24,
                              type: VirtualKeyboardType.Alphanumeric,
                              postKeyPress: (key) {
                                if (key.action ==
                                    VirtualKeyboardKeyAction.Return) {
                                  setState(() {
                                    _showKeyboard = false;
                                  });
                                } else if (key.action ==
                                    VirtualKeyboardKeyAction.Backspace) {
                                  if (_emailController.text.isNotEmpty) {
                                    _emailController.text =
                                        _emailController.text.substring(
                                      0,
                                      _emailController.text.length - 1,
                                    );
                                  }
                                } else {
                                  _emailController.text += key.text!;
                                }
                              },
                            ),
                          ),
                        if (!_showKeyboard)
                          ElevatedButton(
                            onPressed: _isLoading ? null : _submitEmail,
                            style: ElevatedButton.styleFrom(
                              minimumSize: Size(160, 34),
                              elevation: 0,
                              backgroundColor:
                                  AppColors.white.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                                side: BorderSide(
                                  color: AppColors.white,
                                  width: 2.0,
                                ),
                              ),
                            ),
                            child: Text(
                              _isLoading ? "Processing..." : "Submit",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                                fontSize: 20,
                              ),
                            ),
                          )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ]),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
