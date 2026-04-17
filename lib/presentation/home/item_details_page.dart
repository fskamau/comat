import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_utils.dart';
import '../post_item/edit_item_page.dart';
import '../profile/profile_sheet.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ItemDetailsPage extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? docId;

  const ItemDetailsPage({super.key, required this.data, required this.docId});

  String _formatPrice(dynamic price) {
    final n = num.tryParse(price.toString().replaceAll(',', '')) ?? 0;
    return n.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},'
    );
  }

  // Opens a full-screen image viewer
  void _showFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                placeholder: (context, url) => const CircularProgressIndicator(color: AppTheme.mustGold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Launches an external map application
  Future<void> _launchMap(BuildContext context, String url) async {
    final Uri mapUri = Uri.parse(url);
    try {
      if (await canLaunchUrl(mapUri)) {
        await launchUrl(mapUri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Cannot launch Map';
      }
    } catch (e) {
      if (context.mounted) UIUtils.showError(context, "Could not open Google Maps.");
    }
  }

  // Handles item deletion logic
  Future<void> _handleDelete(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.mustGreenSurface,
        title: const Text("DELETE LISTING?", style: TextStyle(color: AppTheme.mustGold, fontSize: 14, letterSpacing: 2)),
        content: const Text("This action is permanent. Remove this item and its image from the market?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL", style: TextStyle(color: Colors.white38))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("DELETE", style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );

    if (confirm == true) {
      if (docId == null) {
        await UIUtils.showError(context, "Error: Item ID is missing.", 2);
        return;
      }

      try {
        final String? imageUrl = data['imageUrl'];
        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            await FirebaseStorage.instance.refFromURL(imageUrl).delete();
          } catch (storageError) {
            debugPrint("Storage Delete Warning: $storageError");
          }
        }

        await FirebaseFirestore.instance.collection('listings').doc(docId).delete();

        if (context.mounted) {
          Navigator.pop(context);
          await UIUtils.showError(context, "Listing and image permanently removed.", 2);
        }
      } catch (e) {
        if (context.mounted) {
          await UIUtils.showError(context, "Failed to remove listing: ${e.toString()}", 2);
        }
      }
    }
  }

  // Opens communication apps (WhatsApp or Dialer) to contact the seller
  Future<void> _handleContactSeller(BuildContext context) async {
    final String? rawPhone = data['sellerPhone']?.toString();

    if (rawPhone == null || rawPhone.trim().isEmpty) {
      UIUtils.showError(context, "Seller hasn't provided a WhatsApp number.");
      return;
    }

    String cleanPhone = rawPhone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '254${cleanPhone.substring(1)}';
    } else if (cleanPhone.startsWith('7') || cleanPhone.startsWith('1')) {
      cleanPhone = '254$cleanPhone';
    }

    final String itemTitle = data['title'] ?? "item";
    final String sellerName = data['sellerName'] ?? "Comrade";
    final String message = "Hello $sellerName, I saw your listing for '$itemTitle' on comat. Is it still available?";

    final Uri whatsappUrl = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}");
    final Uri dialerUrl = Uri.parse("tel:$rawPhone");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(dialerUrl)) {
        await launchUrl(dialerUrl);
      } else {
        throw 'Could not launch any contact app';
      }
    } catch (e) {
      if (context.mounted) UIUtils.showError(context, "Could not open WhatsApp or Dialer.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isOwner = currentUser?.uid == data['sellerId'];

    return Scaffold(
      backgroundColor: AppTheme.mustGreenBody,
      body: Stack(
        children: [
          // Content scroll area
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Image with tap-to-zoom
                GestureDetector(
                  onTap: () => _showFullImage(context, data['imageUrl'] ?? ''),
                  child: Stack(
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height * 0.35,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.mustGreenSurface,
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(data['imageUrl'] ?? ''),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(30)),
                          child: const Icon(Icons.zoom_out_map, color: Colors.white70, size: 20),
                        ),
                      )
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Owner specific actions
                      if (isOwner) ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(color: Colors.redAccent),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => _handleDelete(context),
                                child: const Icon(Icons.delete_outline_rounded),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white10,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () {
                                  if (docId != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditItemPage(data: data, docId: docId!),
                                      ),
                                    );
                                  } else {
                                    UIUtils.showError(context, "Cannot edit item. ID is missing.");
                                  }
                                },
                                child: const Text("EDIT LISTING", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Item category tag
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.mustGold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.mustGold.withOpacity(0.3)),
                        ),
                        child: Text(
                          data['category']?.toString().toUpperCase() ?? 'GENERAL',
                          style: const TextStyle(color: AppTheme.mustGold, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title and Price display
                      Text(
                        data['title'] ?? 'Unnamed Item',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w300),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "KSH ${_formatPrice(data['price'])}",
                        style: const TextStyle(color: AppTheme.mustGold, fontSize: 22, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 24),

                      // Item details (Condition and Seller)
                      Row(
                        children: [
                          _buildInfoChip(Icons.stars_rounded, "CONDITION", data['condition'] ?? "Good"),
                          const SizedBox(width: 30),
                          GestureDetector(
                            onTap: () {
                              final sellerId = data['sellerId'];
                              if (sellerId != null) ProfileSheet.show(context, sellerId);
                            },
                            child: _buildInfoChip(Icons.person_outline_rounded, "SELLER", isOwner ? "You" : (data['sellerName'] ?? "Comrade")),
                          )
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Meetup location section
                      if (data['meetupName'] != null && data['meetupName'].toString().isNotEmpty) ...[
                        const Text("MEETUP LOCATION", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.mustGreenSurface.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: AppTheme.mustGold, size: 28),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  data['meetupName'],
                                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                                ),
                              ),
                              if (data['meetupUrl'] != null && data['meetupUrl'].toString().isNotEmpty)
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.mustGold,
                                    backgroundColor: AppTheme.mustGold.withOpacity(0.1),
                                  ),
                                  onPressed: () => _launchMap(context, data['meetupUrl']),
                                  child: const Text("DIRECTIONS", style: TextStyle(fontSize: 10, letterSpacing: 1)),
                                )
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Item description
                      const Text("DESCRIPTION", style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
                      const SizedBox(height: 12),
                      Text(
                        data['description'] ?? 'No description provided.',
                        style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15, height: 1.6),
                      ),

                      // Padding for bottom action button
                      SizedBox(height: isOwner ? 40 : 120),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Custom back button
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black38,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Sticky contact button for non-owners
          if (!isOwner)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppTheme.mustGreenBody.withOpacity(0), AppTheme.mustGreenBody],
                  ),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.mustGold,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                  ),
                  onPressed: () => _handleContactSeller(context),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded),
                      SizedBox(width: 12),
                      Text("CONTACT SELLER", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, letterSpacing: 1)),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(icon, color: AppTheme.mustGold, size: 16),
            const SizedBox(width: 8),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}