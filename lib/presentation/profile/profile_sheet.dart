import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/ui_utils.dart';
import '../home/item_details_page.dart';

class ProfileSheet extends StatefulWidget {
  final String userId;
  const ProfileSheet({super.key, required this.userId});

  static void show(BuildContext context, String userId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.mustGreenSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => ProfileSheet(userId: userId),
    );
  }

  @override
  State<ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<ProfileSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  late bool _isCurrentUser;

  @override
  void initState() {
    super.initState();
    _isCurrentUser = FirebaseAuth.instance.currentUser?.uid == widget.userId;
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['displayName'] ?? '';
        _phoneController.text = data['phoneNumber'] ?? '';
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: CustomScrollView(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Profile header and editable fields
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      _isCurrentUser ? 'MY PROFILE' : 'SELLER PROFILE',
                      style: const TextStyle(
                        color: AppTheme.mustGold,
                        letterSpacing: 2,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: _nameController,
                    enabled: _isCurrentUser,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      labelStyle: TextStyle(color: AppTheme.mustGold, fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _phoneController,
                    enabled: _isCurrentUser,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp Number',
                      labelStyle: TextStyle(color: AppTheme.mustGold, fontSize: 10),
                    ),
                  ),
                  if (_isCurrentUser) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.mustGold,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSaving
                            ? null
                            : () async {
                                setState(() => _isSaving = true);
                                try {
                                  await FirebaseFirestore.instance.collection('users').doc(widget.userId).set({
                                    'displayName': _nameController.text.trim(),
                                    'phoneNumber': _phoneController.text.trim(),
                                  }, SetOptions(merge: true));
                                  if (mounted) Navigator.pop(context);
                                } catch (e) {
                                  if (mounted) {
                                    UIUtils.showError(context, "Failed to update profile", 3);
                                    setState(() => _isSaving = false);
                                  }
                                }
                              },
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Text("SAVE PROFILE"),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 20),
                  Text(
                    _isCurrentUser ? 'MANAGE MY LISTINGS' : 'ITEMS BY THIS SELLER',
                    style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),

          // User listings display
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('listings')
                .where('sellerId', isEqualTo: widget.userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(color: AppTheme.mustGold),
                    ),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text(
                        "No items listed yet.",
                        style: TextStyle(color: Colors.white24),
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final doc = docs[index];
                      final item = doc.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: NetworkImage(item['imageUrl']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          title: Text(
                            item['title'],
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                          subtitle: Text(
                            "KSH ${item['price']}",
                            style: const TextStyle(color: AppTheme.mustGold, fontSize: 12),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ItemDetailsPage(data: item, docId: doc.id)),
                            );
                          },
                        ),
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),

          // Sign out option
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 40,
                left: 24,
                right: 24,
                top: 20,
              ),
              child: _isCurrentUser
                  ? TextButton(
                      onPressed: () => FirebaseAuth.instance.signOut().then(
                            (_) => Navigator.pushReplacementNamed(context, AppRoutes.login),
                          ),
                      child: const Text(
                        "LOGOUT",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }
}