import 'package:flutter/material.dart';
import 'package:memora/application/dtos/trip/location_dto.dart';

class LocationDetailBottomSheet extends StatelessWidget {
  const LocationDetailBottomSheet({
    super.key,
    required this.location,
    required this.onClose,
  });

  final LocationDto location;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final name = location.name?.isNotEmpty == true ? location.name! : '場所名未設定';
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        elevation: 8,
        child: SafeArea(
          top: false,
          child: Container(
            key: const Key('location_detail_bottom_sheet'),
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '閉じる',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
