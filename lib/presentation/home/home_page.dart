import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import '../camera/custom_camera_page.dart';
import '../post_item/widgets/image_source_sheet.dart';
import '../profile/profile_sheet.dart';
import '../post_item/post_item_page.dart';
import 'item_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Stream<QuerySnapshot> _listingsStream;

  @override
  void initState() {
    super.initState();
    // Initialize the listings stream from Firestore
    _listingsStream = FirebaseFirestore.instance
        .collection('listings')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Helper to format currency values
  String _formatPrice(dynamic price) {
    final n = num.tryParse(price.toString().replaceAll(',', '')) ?? 0;
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.mustGreenBody,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'comat',
          style: TextStyle(
              color: AppTheme.mustGold,
              fontWeight: FontWeight.w200,
              letterSpacing: 2.5),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: AppTheme.mustGold),
            onPressed: () {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                ProfileSheet.show(context, user.uid);
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _handleSellAction(context),
        backgroundColor: AppTheme.mustGreenSurface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.mustGold.withOpacity(0.6), width: 1.5),
        ),
        label: const Text('SELL',
            style: TextStyle(color: Colors.white, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w600)),
        icon: const Icon(Icons.add_circle_outline, color: AppTheme.mustGold, size: 20),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Text('Welcome back,', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),

                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      String displayName = FirebaseAuth.instance.currentUser?.displayName ?? 'Comrade';

                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        if (data != null && data['displayName'] != null && data['displayName'].toString().trim().isNotEmpty) {
                          displayName = data['displayName'];
                        }
                      }

                      return Text(
                        displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w400),
                      );
                    },
                  ),

                  const SizedBox(height: 30),
                  // Search interface
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.mustGreenSurface.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      cursorColor: AppTheme.mustGold,
                      decoration: InputDecoration(
                        icon: const Icon(Icons.search_rounded, color: AppTheme.mustGold, size: 22),
                        hintText: 'Search for items...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TRENDING', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 4.5, fontWeight: FontWeight.w700)),
                      Icon(Icons.tune_rounded, color: AppTheme.mustGold, size: 18),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Grid display for item listings
          StreamBuilder<QuerySnapshot>(
            stream: _listingsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverToBoxAdapter(child: _buildErrorBanner());
              }
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator(color: AppTheme.mustGold)),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text("No items found", style: TextStyle(color: Colors.white38))),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      final doc = docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildItemCard(context, data, doc.id);
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // Handles logic for adding a new item
  Future<void> _handleSellAction(BuildContext context) async {
    final CustomImageSource? source = await showModalBottomSheet<CustomImageSource>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ImageSourceSheet(),
    );

    if (!context.mounted || source == null) return;

    String? selectedImagePath;

    if (source == CustomImageSource.camera) {
      selectedImagePath = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CustomCameraPage()),
      );
    }
    else if (source == CustomImageSource.gallery) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        selectedImagePath = result.files.single.path;
      }
    }

    if (!context.mounted || selectedImagePath == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PostItemPage(imagePath: selectedImagePath!),
      ),
    );

    if (result == 'reselect' && context.mounted) {
      _handleSellAction(context);
    }
  }

  // Individual item card UI
  Widget _buildItemCard(BuildContext context, Map<String, dynamic> data, String docId) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ItemDetailsPage(data: data, docId: docId),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.mustGreenSurface.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.mustGold.withOpacity(0.3), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: CachedNetworkImage(
                  imageUrl: data['imageUrl'] ?? '',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(color: AppTheme.mustGold, strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white38),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? 'Unnamed Item',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'KSH ${_formatPrice(data['price'])}',
                    style: const TextStyle(color: AppTheme.mustGold, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Error display banner
  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: Colors.redAccent),
          SizedBox(width: 15),
          Text("SYSTEM ERROR\nCOULD NOT LOAD LISTINGS",
              style: TextStyle(color: Colors.redAccent, fontSize: 10, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}