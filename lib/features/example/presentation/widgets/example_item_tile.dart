import 'package:app_core/features/example/domain/entities/example_item.dart';
import 'package:flutter/material.dart';

class ExampleItemTile extends StatelessWidget {
  const new({required this.item, super.key});

  final ExampleItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text('${item.id}')),
      title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis),
    );
  }
}
