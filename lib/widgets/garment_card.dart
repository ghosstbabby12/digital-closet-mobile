import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/image_url.dart';
import '../models/garment.dart';

class GarmentCard extends StatelessWidget {
  final Garment garment;
  final VoidCallback? onDelete;

  const GarmentCard({super.key, required this.garment, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  fullImageUrl(garment.imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(color: AppColors.line, child: Icon(Icons.checkroom)),
                ),
                if (onDelete != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: Colors.black45,
                      shape: const CircleBorder(),
                      child: IconButton(
                        iconSize: 18,
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: onDelete,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  garment.name.isNotEmpty ? garment.name : garment.category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600),
                ),
                if (garment.color.isNotEmpty)
                  Text(
                    garment.color,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
