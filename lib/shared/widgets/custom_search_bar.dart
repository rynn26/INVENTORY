import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final Widget? suffixIcon;
  final bool autofocus;

  const CustomSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Cari...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.suffixIcon,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: Border.all(
          color: AppColors.border,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(
            Icons.search_rounded,
            color: AppColors.textMuted,
            size: 21,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autofocus,
              textInputAction: TextInputAction.search,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13.5,
                  fontWeight: FontWeight.normal,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.clear_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
              onPressed: () {
                controller.clear();
                onChanged?.call('');
                onClear?.call();
              },
            )
          else if (suffixIcon != null) ...[
            suffixIcon!,
          ],
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}
