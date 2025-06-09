import 'package:flutter/material.dart';
import 'package:memora/domain/services/location_search_service.dart';
import 'package:memora/domain/entities/location_candidate.dart';

class CustomSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final LocationSearchService? locationSearchService;
  final ValueChanged<LocationCandidate>? onCandidateSelected;

  const CustomSearchBar({
    super.key,
    required this.hintText,
    this.onChanged,
    this.controller,
    this.locationSearchService,
    this.onCandidateSelected,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;
  List<LocationCandidate> _candidates = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  Future<void> _onSearch() async {
    if (widget.locationSearchService == null) return;
    setState(() => _isLoading = true);
    final results = await widget.locationSearchService!.searchByKeyword(
      _controller.text,
    );
    setState(() {
      _candidates = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.hintText,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(width: 1, color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(width: 1, color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: const BorderSide(width: 2, color: Colors.blue),
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _controller.clear();
                          _candidates = [];
                        });
                        widget.onChanged?.call('');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
            ),
            onChanged: (value) {
              setState(() {});
              widget.onChanged?.call(value);
            },
            onSubmitted: (_) => _onSearch(),
          ),
        ),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: LinearProgressIndicator(),
          ),
        if (_candidates.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SizedBox(
              // 最大高さを設定し、超えた分はスクロール
              height: _candidates.length > 5 ? 400 : null,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _candidates.length,
                itemBuilder: (context, index) {
                  final candidate = _candidates[index];
                  return ListTile(
                    title: Text(candidate.name),
                    subtitle: Text(candidate.address),
                    onTap: () {
                      widget.onCandidateSelected?.call(candidate);
                      setState(() {
                        _candidates = [];
                      });
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
