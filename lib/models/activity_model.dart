import 'package:flutter/material.dart';

/// Represents a single item in the "Recent Activity" feed.
class ActivityModel {
  final String title;
  final String description;
  final String timeAgo;
  final IconData icon;
  final Color iconColor;

  const ActivityModel({
    required this.title,
    required this.description,
    required this.timeAgo,
    required this.icon,
    required this.iconColor,
  });
}
