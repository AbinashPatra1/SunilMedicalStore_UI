import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:sunil_medical_store/core/models/prescription.dart';
import 'package:sunil_medical_store/core/network/api_exception.dart';
import 'package:sunil_medical_store/features/prescriptions/domain/prescription_repository.dart';
import 'package:uuid/uuid.dart';

/// [PrescriptionRepository] backed by Firebase Storage (for the image
/// bytes) + `/v1/prescriptions` (for the metadata: status, review note,
/// ownership). The backend never sees the raw file — it only stores the
/// download URL Firebase Storage hands back, keeping the ASP.NET Core side
/// free of multipart/blob handling.
///
/// Requires Firebase Storage security rules that let a signed-in user write
/// under `prescriptions/{their own uid}/**` — see CLAUDE.md.
class ApiPrescriptionRepository implements PrescriptionRepository {
  ApiPrescriptionRepository(this._dio);

  final Dio _dio;
  static const _uuid = Uuid();

  @override
  Future<List<Prescription>> list() async {
    try {
      final response = await _dio.get<List<dynamic>>('/prescriptions');
      return (response.data ?? const []).cast<Map<String, dynamic>>().map(_fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Prescription> upload(File imageFile) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw const ApiException('unauthorized', 'Please sign in again.');
    }
    final extension = imageFile.path.split('.').last;
    final ref = FirebaseStorage.instance.ref('prescriptions/$uid/${_uuid.v4()}.$extension');
    final String imageUrl;
    try {
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      throw ApiException('storage_error', e.message ?? 'Could not upload the image.');
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/prescriptions',
        data: {'imageUrl': imageUrl},
      );
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  @override
  Future<Prescription> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/prescriptions/$id');
      return _fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Prescription _fromJson(Map<String, dynamic> json) => Prescription(
    id: json['id'] as String,
    imageUrl: json['imageUrl'] as String,
    uploadedOn: DateTime.parse(json['uploadedOn'] as String),
    status: PrescriptionStatus.values.byName(json['status'] as String),
    note: json['note'] as String?,
  );
}
