import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Yeh provider poori app mein Duas supply karega
final duaProvider = FutureProvider<List<dynamic>>((ref) async {
  // 1000 duas load hone mein sirf 0.1 second lagega!
  final String response = await rootBundle.loadString('assets/data/hisnul_muslim.json');
  final data = await json.decode(response);
  return data;
});