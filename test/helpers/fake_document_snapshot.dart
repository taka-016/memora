// ignore_for_file: subtype_of_sealed_class

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';

class FakeDocumentSnapshot extends Fake
    implements DocumentSnapshot<Map<String, dynamic>> {
  FakeDocumentSnapshot({
    required this.docId,
    Map<String, dynamic>? data,
    this.existsValue = true,
  }) : _data = data;

  final String docId;
  final Map<String, dynamic>? _data;
  final bool existsValue;

  @override
  String get id => docId;

  @override
  bool get exists => existsValue;

  @override
  Map<String, dynamic>? data() => _data;
}
