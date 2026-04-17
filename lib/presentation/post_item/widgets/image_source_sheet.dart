import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

enum CustomImageSource { camera, gallery }

class ImageSourceSheet extends StatelessWidget {
  const ImageSourceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: const BoxDecoration(
        color: AppTheme.mustGreenSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 45,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white38,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'SELECT SOURCE',
            style: TextStyle(
              color: Colors.white70,
              letterSpacing: 4.5,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 36),
          Row(
            children: [
              Expanded(
                child: _buildOptionButton(
                  context: context,
                  icon: Icons.camera_enhance_outlined,
                  label: 'Camera',
                  source: CustomImageSource.camera,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildOptionButton(
                  context: context,
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  source: CustomImageSource.gallery,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required CustomImageSource source,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, source),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        decoration: BoxDecoration(
          color: AppTheme.mustGreenSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.2),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.mustGold, size: 32),
            const SizedBox(height: 14),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}