import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';

class GooglePlacesSearchBar extends StatefulWidget {
  final void Function(double lat, double lng)? onPlaceSelected;
  final String apiKey;

  const GooglePlacesSearchBar({
    super.key,
    required this.apiKey,
    this.onPlaceSelected,
  });

  @override
  GooglePlacesSearchBarState createState() => GooglePlacesSearchBarState();
}

class GooglePlacesSearchBarState extends State<GooglePlacesSearchBar> {
  final TextEditingController _controller = TextEditingController();

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GooglePlaceAutoCompleteTextField(
        textEditingController: _controller,
        googleAPIKey: widget.apiKey,
        inputDecoration: const InputDecoration(
          hintText: '場所を検索',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
        ),
        debounceTime: 400,
        isLatLngRequired: true,
        getPlaceDetailWithLatLng: (prediction) {
          try {
            final lat = double.tryParse(prediction.lat ?? '');
            final lng = double.tryParse(prediction.lng ?? '');
            if (lat != null &&
                lng != null &&
                widget.onPlaceSelected != null &&
                mounted) {
              widget.onPlaceSelected!(lat, lng);
            }
          } catch (e) {
            debugPrint('Google Places error: $e');
            _showError('場所の検索でエラーが発生しました');
          }
        },
        itemClick: (prediction) {
          // itemClickコールバックがないと処理が固まるため、必須
          try {
            _controller.text = prediction.description ?? '';
          } catch (e) {
            debugPrint('ItemClick error: $e');
            _showError('場所の選択でエラーが発生しました');
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
