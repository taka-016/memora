import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/domain/services/location_search_service.dart';
import 'package:memora/domain/value_objects/location_candidate.dart';

class CustomSearchBar extends HookWidget {
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
  Widget build(BuildContext context) {
    final textController = controller ?? useTextEditingController();
    final candidates = useState<List<LocationCandidate>>([]);
    final isLoading = useState(false);

    Future<void> onSearch() async {
      if (locationSearchService == null) return;
      isLoading.value = true;
      final results = await locationSearchService!.searchByKeyword(
        textController.text,
      );
      candidates.value = results;
      isLoading.value = false;
    }

    void onFieldChanged(String value) {
      onChanged?.call(value);
    }

    Widget? buildClearButton() {
      if (textController.text.isEmpty) return null;

      return IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          textController.clear();
          candidates.value = [];
          onChanged?.call('');
        },
      );
    }

    Widget buildSearchField() {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: textController,
          decoration: InputDecoration(
            hintText: hintText,
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
            suffixIcon: buildClearButton(),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 10,
              horizontal: 12,
            ),
          ),
          onChanged: onFieldChanged,
          onSubmitted: (_) => onSearch(),
        ),
      );
    }

    Widget buildLoadingIndicator() {
      if (!isLoading.value) return const SizedBox.shrink();

      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: LinearProgressIndicator(),
      );
    }

    Widget buildCandidateItem(BuildContext context, int index) {
      final candidate = candidates.value[index];
      return ListTile(
        title: Text(candidate.name),
        subtitle: Text(candidate.address),
        onTap: () {
          onCandidateSelected?.call(candidate);
          candidates.value = [];
        },
      );
    }

    Widget buildCandidatesList() {
      if (candidates.value.isEmpty) return const SizedBox.shrink();

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: SizedBox(
          height: candidates.value.length > 5 ? 400 : null,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: candidates.value.length,
            itemBuilder: buildCandidateItem,
          ),
        ),
      );
    }

    useListenable(textController);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSearchField(),
        buildLoadingIndicator(),
        buildCandidatesList(),
      ],
    );
  }
}
