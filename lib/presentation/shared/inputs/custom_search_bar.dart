import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/application/usecases/location/search_locations_usecase.dart';

class CustomSearchBar extends HookConsumerWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final ValueChanged<LocationCandidateDto>? onCandidateSelected;

  const CustomSearchBar({
    super.key,
    required this.hintText,
    this.onChanged,
    this.controller,
    this.onCandidateSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = controller ?? useTextEditingController();
    final candidates = useState<List<LocationCandidateDto>>([]);
    final isLoading = useState(false);

    Future<void> onSearch() async {
      isLoading.value = true;
      final results = await ref
          .read(searchLocationsUsecaseProvider)
          .execute(textController.text);
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
