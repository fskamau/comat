import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../data/services/gemini_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/services/upload_service.dart';

class PostItemPage extends StatefulWidget {
  final String imagePath;

  const PostItemPage({super.key, required this.imagePath});

  @override
  State<PostItemPage> createState() => _PostItemPageState();
}

class _PostItemPageState extends State<PostItemPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _selectedMeetup;
  Map<String, String> _activeMeetupLocations = {};
  bool _isPosting = false;

  String? _selectedCategory;
  String? _selectedCondition;
  bool _isAnalyzing = true;

  @override
  void initState() {
    super.initState();
    _activeMeetupLocations = Map.from(AppConstants.defaultMeetupLocations);
    _selectedMeetup = _activeMeetupLocations.keys.first;
    // Perform AI analysis on the selected image
    _runLiveAIScan().then((success) {
      if (!success && mounted) {
        Navigator.pop(context, 'reselect');
      }
    });
  }

  // Analyzes the listing image using Gemini AI
  Future<bool> _runLiveAIScan() async {
    final gemini = GeminiService();
    final result = await gemini.analyzeListing(widget.imagePath);

    if (!mounted) return false;

    if (result == null) {
      await UIUtils.showError(
        context,
        "Analysis failed. Please try again.",
        7,
      );
      return false;
    }

    if (result.containsKey('error')) {
      await UIUtils.showError(context, result['error'], 7);
      return false;
    }

    setState(() {
      _titleController.text = result['title'] ?? "";
      _descController.text = result['description'] ?? "";
      _priceController.text = result['price']?.toString() ?? "";

      _selectedCategory = AppConstants.categories.contains(result['category'])
          ? result['category']
          : AppConstants.categories.first;

      _selectedCondition = AppConstants.conditions.contains(result['condition'])
          ? result['condition']
          : AppConstants.conditions.first;

      _isAnalyzing = false;
    });

    return true;
  }

  // Handles the final submission of the item listing
  Future<void> _handleFinalPost() async {
    if (_titleController.text.isEmpty || _priceController.text.isEmpty) {
      UIUtils.showError(context, "Please ensure Title and Price are set.", 3);
      return;
    }

    setState(() => _isPosting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not authenticated");

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();

      // Check for seller contact information
      if (userData == null ||
          userData['phoneNumber'] == null ||
          userData['phoneNumber'].toString().trim().isEmpty) {
        if (mounted) {
          UIUtils.showError(
            context,
            "Contact info required: Please add your phone number in profile settings before selling.",
            6,
          );
          setState(() => _isPosting = false);
        }
        return;
      }

      final String sellerName =
          userData['displayName'] ?? user.displayName ?? 'Comrade';
      final String sellerPhone = userData['phoneNumber'];

      final uploadService = UploadService();
      final String? imageUrl = await uploadService.uploadItemImage(
        File(widget.imagePath),
      );

      if (imageUrl == null) throw Exception("Image upload failed");

      final String rawPrice = _priceController.text.replaceAll(',', '');

      // Create a new listing document in Firestore
      await FirebaseFirestore.instance.collection('listings').add({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'price': int.tryParse(rawPrice) ?? 0,
        'category': _selectedCategory,
        'condition': _selectedCondition,
        'imageUrl': imageUrl,
        'sellerId': user.uid,
        'sellerName': sellerName,
        'sellerPhone': sellerPhone,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'meetupName': _selectedMeetup,
        'meetupUrl': _activeMeetupLocations[_selectedMeetup],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Listing posted successfully!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showError(context, "Post failed: ${e.toString()}", 5);
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mustGreenBody,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'POST ITEM',
          style: TextStyle(
            color: AppTheme.mustGold,
            fontSize: 12,
            letterSpacing: 3,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Preview of the selected item image
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.mustGold.withOpacity(0.3)),
                image: DecorationImage(
                  image: FileImage(File(widget.imagePath)),
                  fit: BoxFit.cover,
                ),
              ),
              child: _isAnalyzing
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: AppTheme.mustGold,
                              strokeWidth: 2,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'ANALYZING IMAGE...',
                              style: TextStyle(
                                color: AppTheme.mustGold,
                                fontSize: 10,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 30),

            _buildSleekField('TITLE', _titleController, enabled: !_isAnalyzing),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildSleekDropdown(
                    'CATEGORY',
                    _selectedCategory,
                    AppConstants.categories,
                    (val) => setState(() => _selectedCategory = val),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSleekDropdown(
                    'CONDITION',
                    _selectedCondition,
                    AppConstants.conditions,
                    (val) => setState(() => _selectedCondition = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _buildMeetupDropdown(),
            const SizedBox(height: 20),
            _buildSleekField(
              'PRICE (KSH)',
              _priceController,
              enabled: !_isAnalyzing,
              isPrice: true,
            ),
            const SizedBox(height: 20),

            _buildSleekField(
              'DESCRIPTION',
              _descController,
              maxLines: 5,
              enabled: !_isAnalyzing,
              isDescription: true,
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.mustGold,
                  disabledBackgroundColor: AppTheme.mustGold.withOpacity(0.1),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: (_isAnalyzing || _isPosting)
                    ? null
                    : _handleFinalPost,
                child: _isPosting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'CONFIRM & POST',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSleekField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool enabled = true,
    bool isPrice = false,
    bool isDescription = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: isDescription
              ? null
              : maxLines,
          minLines: isDescription ? 3 : 1,
          enabled: enabled,
          keyboardType: isPrice
              ? TextInputType.number
              : TextInputType.multiline,
          style: TextStyle(
            color: isPrice ? AppTheme.mustGold : Colors.white,
            fontSize: isPrice ? 18 : 15,
            fontWeight: isPrice ? FontWeight.bold : FontWeight.w400,
            letterSpacing: isPrice ? 1.2 : 0.5,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.mustGreenSurface.withOpacity(0.3),
            prefixText: isPrice ? 'KSH ' : null,
            prefixStyle: const TextStyle(
              color: AppTheme.mustGold,
              fontWeight: FontWeight.bold,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppTheme.mustGold,
                width: 0.5,
              ),
            ),
          ),
          onChanged: isPrice
              ? (value) {
                  if (value.isEmpty) return;
                  final n = num.tryParse(value.replaceAll(',', ''));
                  if (n != null) {
                    final formatted = n.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                    );
                    controller.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(
                        offset: formatted.length,
                      ),
                    );
                  }
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildSleekDropdown(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: AppTheme.mustGreenSurface,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.mustGreenSurface.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: _isAnalyzing ? null : onChanged,
        ),
      ],
    );
  }

  Widget _buildMeetupDropdown() {
    List<String> items = [
      ..._activeMeetupLocations.keys,
      '+ ADD CUSTOM LOCATION',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MEETUP LOCATION',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedMeetup,
          dropdownColor: AppTheme.mustGreenSurface,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.mustGreenSurface.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          items: items.map((String item) {
            return DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: TextStyle(
                  color: item.startsWith('+')
                      ? AppTheme.mustGold
                      : Colors.white,
                  fontWeight: item.startsWith('+')
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
          onChanged: _isAnalyzing
              ? null
              : (val) {
                  if (val == '+ ADD CUSTOM LOCATION') {
                    _showAddLocationDialog();
                  } else {
                    setState(() => _selectedMeetup = val);
                  }
                },
        ),
      ],
    );
  }

  // Opens a dialog to add a new custom meetup location
  Future<void> _showAddLocationDialog() async {
    final TextEditingController nameCtrl = TextEditingController();
    final TextEditingController urlCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.mustGreenSurface,
        title: const Text(
          "NEW LOCATION",
          style: TextStyle(color: AppTheme.mustGold, fontSize: 12, letterSpacing: 2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Location Name",
                labelStyle: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Google Maps URL",
                labelStyle: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              final String name = nameCtrl.text.trim();
              final String url = urlCtrl.text.trim();

              if (name.isEmpty || url.isEmpty) {
                await UIUtils.showError(context, "Both fields are required.", 2);
                return;
              }

              final Uri? uri = Uri.tryParse(url);
              final bool isValidUrl = uri != null && uri.hasAbsolutePath;

              if (!isValidUrl) {
                await UIUtils.showError(context, "Please enter a valid URL.", 2);
                return;
              }

              final bool isGoogleMaps = url.contains('google.com/maps') ||
                  url.contains('maps.app.goo.gl') ||
                  url.contains('goo.gl/maps');

              if (!isGoogleMaps) {
                await UIUtils.showError(context, "Link must be a Google Maps URL.", 2);
                return;
              }

              setState(() {
                _activeMeetupLocations[name] = url;
                _selectedMeetup = name;
              });
              Navigator.pop(context);
            },
            child: const Text("ADD", style: TextStyle(color: AppTheme.mustGold)),
          ),
        ],
      ),
    );

    if (_selectedMeetup == '+ ADD CUSTOM LOCATION') {
      setState(() => _selectedMeetup = _activeMeetupLocations.keys.first);
    }
  }
}