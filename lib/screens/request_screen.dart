import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../core/constants/app_colors.dart';

class RequestScreen extends StatelessWidget {
  const RequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HeroIcon(
            HeroIcons.documentText,
            size: 64,
            style: HeroIconStyle.outline,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Requests',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Time off, attendance, and other requests',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }
}
