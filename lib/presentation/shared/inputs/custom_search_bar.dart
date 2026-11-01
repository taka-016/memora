import 'package:memora/composition_root/providers/location_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:memora/application/dtos/location/location_candidate_dto.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:memora/core/app_logger.dart';

class CustomSearchBar extends HookConsumerWidget {
  final String hintText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final ValueChanged<LocationCandidateDto>? onCandidateSelected;

  const CustomSearchBar({
    super.key,
    required this.hintText,
    this.enabled = true,
    this.onChanged,
    this.controller,
    this.onCandidateSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = controller ?? useTextEditingController();
    final candidates = useState<List<LocationCandidateDto>>([]);
    final isLoading = useState(false);
    final message = useState<String?>(null);

    Future<void> onSearch() async {
      if (!enabled || isLoading.value) return;
      isLoading.value = true;
      candidates.value = [];
      message.value = null;
      try {
        final results = await ref
            .read(searchLocationsUsecaseProvider)
            .execute(textController.text);
        if (!context.mounted) {
          return;
        }
        candidates.value = results;
        message.value = results.isEmpty ? '検索結果がありません' : null;
      } catch (e, stack) {
        if (!context.mounted) return;
        message.value = '場所を検索できませんでした。再検索してください';
        logger.e(
          'CustomSearchBar.onSearch: ${e.toString()}',
          error: e,
          stackTrace: stack,
        );
      } finally {
        if (context.mounted) {
          isLoading.value = false;
        }
      }
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
          message.value = null;
          onChanged?.call('');
        },
      );
    }

    Widget buildSearchField() {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: textController,
          enabled: enabled,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(
                width: 1,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(
                width: 1,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(
                width: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (textController.text.isNotEmpty) buildClearButton()!,
                IconButton(
                  tooltip: '場所を検索',
                  icon: const Icon(Icons.search),
                  onPressed: enabled && !isLoading.value ? onSearch : null,
                ),
              ],
            ),
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
      return Material(
        type: MaterialType.transparency,
        child: ListTile(
          title: Text(candidate.name),
          subtitle: Text(candidate.address),
          onTap: !enabled
              ? null
              : () {
                  onCandidateSelected?.call(candidate);
                  candidates.value = [];
                  message.value = null;
                },
        ),
      );
    }

    Widget buildCandidatesList() {
      if (candidates.value.isEmpty) return const SizedBox.shrink();

      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
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
        if (message.value != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(message.value!),
          ),
        buildCandidatesList(),
      ],
    );
  }
}
