import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void showErrorToast(BuildContext context, String title, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Alert(
        title: Text(title),
        content: Text(message),
        trailing: Icon(Icons.dangerous_outlined),
        destructive: true,
      ),
    ),
  );
}
