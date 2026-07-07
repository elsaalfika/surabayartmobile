import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/pameran_model.dart';
import '../core/theme.dart';

/// Card kecil untuk grid horizontal (Now Showing / Upcoming Show)
class EventCard extends StatelessWidget {
  final PameranModel pameran;
  final VoidCallback? onTap;
  final bool showReserveLabel;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggle;

  const EventCard({
    super.key,
    required this.pameran,
    this.onTap,
    this.showReserveLabel = true,
    this.isFavorite = false,
    this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: pameran.posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: pameran.posterUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: AppColors.border),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.border,
                          child: const Icon(Icons.image_not_supported_outlined),
                        ),
                      )
                    : Container(
                        color: AppColors.border,
                        child: const Icon(Icons.image_outlined),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              pameran.namaPameran,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppColors.textDark,
              ),
            ),
            Text(
              '${dateFormat.format(pameran.tanggalMulai)} - ${dateFormat.format(pameran.tanggalSelesai)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
            const SizedBox(height: 4),
            if (showReserveLabel)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'reserve',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              )
            else
              GestureDetector(
                onTap: onFavoriteToggle,
                child: Row(
                  children: [
                    Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      size: 14,
                      color: isFavorite ? AppColors.danger : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        pameran.namaPameran,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Card besar untuk list vertikal (misalnya di My Event organizer)
class EventCardWide extends StatelessWidget {
  final PameranModel pameran;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Color? accentColor;

  const EventCardWide({
    super.key,
    required this.pameran,
    this.onEdit,
    this.onDelete,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMMM yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: accentColor ?? AppColors.pending, width: 4),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(pameran.namaPameran,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 6),
          Text(
            '${dateFormat.format(pameran.tanggalMulai)} - ${dateFormat.format(pameran.tanggalSelesai)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          Text(pameran.lokasi, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (onEdit != null)
                TextButton(onPressed: onEdit, child: const Text('Edit')),
              if (onDelete != null)
                TextButton(
                  onPressed: onDelete,
                  child: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}