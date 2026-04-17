import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/constants/app_constants.dart';

class EditItemPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;

  const EditItemPage({super.key, required this.data, required this.docId});

  @override
  State<EditItemPage> createState() => _EditItemPageState();
}

class _EditItemPageState extends State<EditItemPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _priceController;

  String? _selectedCategory;
  String? _selectedCondition;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill controllers with existing data
    _titleController = TextEditingController(text: widget.data['title'] ?? '');
    _descController = TextEditingController(text: widget.data['description'] ?? '');

    // Format existing price for display
    final String rawPrice = widget.data['price']?.toString() ?? '';
    final formattedPrice = rawPrice.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    _priceController = TextEditingController(text: formattedPrice);

    // Initialize dropdown selections
    _selectedCategory = AppConstants.categories.contains(widget.data['category'])
        ? widget.data['category']
        : AppConstants.categories.first;

    _selectedCondition = AppConstants.conditions.contains(widget.data['condition'])
        ? widget.data['condition']
        : AppConstants.conditions.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (_titleController.text.trim().isEmpty || _priceController.text.trim().isEmpty) {
      UIUtils.showError(context, "Title and Price cannot be empty.", 3);
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final String rawPrice = _priceController.text.replaceAll(',', '');

      // Update document in Firestore
      await FirebaseFirestore.instance.collection('listings').doc(widget.docId).update({
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'price': int.tryParse(rawPrice) ?? 0,
        'category': _selectedCategory,
        'condition': _selectedCondition,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Listing updated successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showError(context, "Failed to update: ${e.toString()}", 4);
        setState(() => _isUpdating = false);
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
        title: const Text('EDIT ITEM', style: TextStyle(color: AppTheme.mustGold, fontSize: 12, letterSpacing: 3)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSleekField('TITLE', _titleController),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(child: _buildSleekDropdown('CATEGORY', _selectedCategory, AppConstants.categories, (val) => setState(() => _selectedCategory = val))),
                const SizedBox(width: 16),
                Expanded(child: _buildSleekDropdown('CONDITION', _selectedCondition, AppConstants.conditions, (val) => setState(() => _selectedCondition = val))),
              ],
            ),
            const SizedBox(height: 20),

            _buildSleekField('PRICE (KSH)', _priceController, isPrice: true),
            const SizedBox(height: 20),

            _buildSleekField('DESCRIPTION', _descController, maxLines: 5, isDescription: true),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.mustGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isUpdating ? null : _handleUpdate,
                child: _isUpdating
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSleekField(String label, TextEditingController controller, {int maxLines = 1, bool isPrice = false, bool isDescription = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: isDescription ? null : maxLines,
          minLines: isDescription ? 3 : 1,
          keyboardType: isPrice ? TextInputType.number : TextInputType.multiline,
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
            prefixStyle: const TextStyle(color: AppTheme.mustGold, fontWeight: FontWeight.bold),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.mustGold, width: 0.5)),
          ),
          onChanged: isPrice ? (value) {
            if (value.isEmpty) return;
            final n = num.tryParse(value.replaceAll(',', ''));
            if (n != null) {
              final formatted = n.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
              controller.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
            }
          } : null,
        ),
      ],
    );
  }

  Widget _buildSleekDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 2)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          dropdownColor: AppTheme.mustGreenSurface,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppTheme.mustGreenSurface.withOpacity(0.3),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: items.map((String item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}