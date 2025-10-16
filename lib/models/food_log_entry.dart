// models/food_log_entry.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FoodLogEntry {
  final String name;
  final int kcal;
  final DateTime timestamp;
  final IconData icon;
  final bool isRecommended;

  FoodLogEntry({
    required this.name,
    required this.kcal,
    required this.timestamp,
    required this.icon,
    this.isRecommended = false,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'kcal': kcal,
      'timestamp': Timestamp.fromDate(timestamp),
      'iconCodePoint': icon.codePoint,
      'isRecommended': isRecommended,
    };
  }

  // Create from Map (for array storage)
  factory FoodLogEntry.fromMap(Map<String, dynamic> data) {
    return FoodLogEntry(
      name: data['name'] ?? 'Unknown Food',
      kcal: (data['kcal'] as num?)?.toInt() ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      icon: IconData(data['iconCodePoint'] ?? Icons.restaurant.codePoint,
          fontFamily: 'MaterialIcons'),
      isRecommended: data['isRecommended'] ?? false,
    );
  }
}