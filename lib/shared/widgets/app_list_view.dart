import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppListView<T> extends StatelessWidget {
  final List<T> items;
  final Future<void> Function()? onRefresh;
  final String emptyMessage;
  final Widget Function(T item) titleBuilder;
  final Widget Function(T item) subtitleBuilder;
  final Widget Function(T item)? leadingBuilder;
  final Widget Function(T item)? trailingBuilder;
  final EdgeInsets padding;
  final Color cardColor;

  const AppListView({
    super.key,
    required this.items,
    this.onRefresh,
    required this.emptyMessage,
    required this.titleBuilder,
    required this.subtitleBuilder,
    this.leadingBuilder,
    this.trailingBuilder,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    this.cardColor = AppTheme.surface,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: const TextStyle(color: AppTheme.white, fontSize: AppTheme.small),
        ),
      );
    }

    final list = ListView.builder(
      padding: padding,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          color: cardColor,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 1),
            leading: leadingBuilder?.call(item),
            title: titleBuilder(item),
            subtitle: subtitleBuilder(item),
            trailing: trailingBuilder?.call(item),
          ),
        );
      },
    );

    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        color: AppTheme.active,
        backgroundColor: AppTheme.header,
        child: list,
      );
    }

    return list;
  }
}
