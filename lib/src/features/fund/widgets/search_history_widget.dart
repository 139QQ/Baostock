import 'package:flutter/material.dart';

/// 搜索历史组件
class SearchHistoryWidget extends StatelessWidget {
  final List<String> history;
  final Function(String) onSearch;
  final VoidCallback onClear;

  const SearchHistoryWidget({
    super.key,
    required this.history,
    required this.onSearch,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '搜索历史',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear_all, size: 16),
              label: const Text('清空'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildHistoryList(context),
      ],
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    if (history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(
              Icons.history,
              size: 20,
              color: Colors.grey[400],
            ),
            const SizedBox(width: 8),
            Text(
              '暂无搜索历史',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: history.map((item) {
        return _buildHistoryChip(context, item);
      }).toList(),
    );
  }

  Widget _buildHistoryChip(BuildContext context, String item) {
    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              item,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      onPressed: () => onSearch(item),
      backgroundColor: Colors.grey[100],
      elevation: 0,
      pressElevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

/// 搜索建议组件
class SearchSuggestionsWidget extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSuggestionSelected;
  final String currentQuery;

  const SearchSuggestionsWidget({
    super.key,
    required this.suggestions,
    required this.onSuggestionSelected,
    required this.currentQuery,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return _buildSuggestionItem(context, suggestion);
        },
      ),
    );
  }

  Widget _buildSuggestionItem(BuildContext context, String suggestion) {
    return ListTile(
      dense: true,
      leading: Icon(
        Icons.search,
        size: 20,
        color: Colors.grey[600],
      ),
      title: RichText(
        text: TextSpan(
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 14,
          ),
          children: [
            // 高亮匹配的部分
            if (suggestion.toLowerCase().startsWith(currentQuery.toLowerCase()))
              TextSpan(
                text: currentQuery,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            // 剩余部分
            TextSpan(
              text: suggestion.substring(currentQuery.length),
            ),
          ],
        ),
      ),
      onTap: () => onSuggestionSelected(suggestion),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

/// 热门搜索组件
class PopularSearchesWidget extends StatelessWidget {
  final List<String> popularSearches;
  final Function(String) onSearch;

  const PopularSearchesWidget({
    super.key,
    required this.popularSearches,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.trending_up,
              color: Colors.orange[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '热门搜索',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: popularSearches.map((search) {
            return _buildPopularChip(context, search);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPopularChip(BuildContext context, String search) {
    return ActionChip(
      label: Text(search),
      onPressed: () => onSearch(search),
      backgroundColor: Colors.orange[50],
      elevation: 0,
      pressElevation: 2,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      labelStyle: TextStyle(
        color: Colors.orange[700],
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      avatar: Icon(
        Icons.local_fire_department,
        size: 16,
        color: Colors.orange[600],
      ),
    );
  }
}
