import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../utils/app_theme.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final bool isSelected;
  final VoidCallback onTap;

  const ServiceCard({
    super.key,
    required this.service,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconForCategory(service.category),
                  color: AppTheme.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${service.durationInMinutes} min',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.attach_money, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          'R\$ ${service.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: AppTheme.primary)
              else
                const Icon(Icons.add_circle_outline, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Unhas':
        return Icons.back_hand_outlined;
      case 'Cabelo':
        return Icons.content_cut;
      case 'Sobrancelha':
        return Icons.remove_red_eye_outlined;
      case 'Estética':
        return Icons.face_retouching_natural;
      default:
        return Icons.spa_outlined;
    }
  }
}
