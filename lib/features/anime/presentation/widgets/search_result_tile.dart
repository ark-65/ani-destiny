import 'package:flutter/material.dart';

import '../../domain/entities/search_result.dart';

class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    required this.result,
    required this.onTap,
    super.key,
  });

  final SearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 56,
          height: 56,
          child: result.coverUrl == null
              ? const Icon(Icons.movie_outlined)
              : Image.network(
                  result.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.movie_outlined),
                ),
        ),
      ),
      title: Text(result.title),
      subtitle: Text(
        result.description ?? result.sourceId,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
