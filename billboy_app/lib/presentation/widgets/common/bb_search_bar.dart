import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class BBSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback? onFilter;

  const BBSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Search bills, products, stores...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        if (onFilter != null) ...[
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: IconButton(
              icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
              onPressed: onFilter,
            ),
          ),
        ],
      ],
    );
  }
}
