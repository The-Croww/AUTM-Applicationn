// lib/services/google_drive_service.dart

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class GoogleDriveService {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  // ✅ CRITICAL: Replace with your actual Google Drive folder ID
  static const String _capturesFolderId = '1LQ992Mqg-q3hvf_T92NmvinwS8RLw6le';

  final _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  GoogleSignInAccount? _currentUser;
  drive.DriveApi? _driveApi;
  AuthClient? _authClient;

  // ── Sign In ─────────────────────────────────────────────────
  Future<void> signIn() async {
    try {
      _currentUser = await _googleSignIn.signInSilently()
          ?? await _googleSignIn.signIn();
      if (_currentUser == null) throw Exception('Sign-in cancelled by user');

      await _refreshAuth();
      debugPrint('✅ Google Drive signed in as: ${_currentUser!.email}');
    } catch (e) {
      debugPrint('❌ Google Drive sign-in failed: $e');
      rethrow;
    }
  }

  Future<void> _refreshAuth() async {
    if (_currentUser == null) throw Exception('Not signed in');

    final auth = await _currentUser!.authentication;
    final client = http.Client();
    final credentials = AccessCredentials(
      AccessToken(
        'Bearer',
        auth.accessToken!,
        DateTime.now().add(const Duration(hours: 1)).toUtc(),
      ),
      auth.idToken,
      _googleSignIn.scopes,
    );

    _authClient?.close();
    _authClient = authenticatedClient(client, credentials);
    _driveApi = drive.DriveApi(_authClient!);
  }

  Future<void> _ensureAuth() async {
    if (_driveApi == null || _currentUser == null) {
      debugPrint('🔐 Drive auth needed, signing in...');
      await signIn();
    }
    // Check if token expired and refresh if needed
    try {
      await _driveApi!.about.get();
    } catch (e) {
      debugPrint('🔄 Token expired, refreshing...');
      await _refreshAuth();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ FIXED: Upload from bytes — returns FILE ID (not URL)
  // This matches your original working API
  // ─────────────────────────────────────────────────────────────
  Future<String> uploadImageBytes({
    required Uint8List bytes,
    required String fileName,
    String? folderId,
  }) async {
    await _ensureAuth();

    debugPrint('📤 Uploading "$fileName" (${bytes.length} bytes) to Google Drive...');

    // ✅ FIXED: Use Stream.fromIterable with explicit List<int> typing
    // This was the original working approach — just ensure proper typing
    final List<int> intBytes = bytes;
    final stream = Stream.fromIterable([intBytes]);

    final driveFile = drive.File()
      ..name = fileName
      ..parents = [folderId ?? _capturesFolderId];

    final media = drive.Media(stream, bytes.length);

    try {
      final result = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      debugPrint('✅ File uploaded to Drive with ID: ${result.id}');

      // Make it publicly readable
      await _makeFilePublic(result.id!);

      // ✅ Return FILE ID (not URL) — matches your original working API
      // Your camera screen stores this as imageUrl, and downloadImage expects fileId
      return result.id!;
    } catch (e) {
      debugPrint('❌ Drive upload failed: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Upload from file path — FIXED variable name collision
  // ─────────────────────────────────────────────────────────────
  Future<String> uploadImage(String filePath, String fileName) async {
    await _ensureAuth();

    debugPrint('📤 Uploading file "$fileName" from path: $filePath');

    final localFile = File(filePath);
    if (!localFile.existsSync()) {
      throw Exception('File does not exist: $filePath');
    }

    final driveFile = drive.File()
      ..name = fileName
      ..parents = [_capturesFolderId];

    final media = drive.Media(
      localFile.openRead(),
      localFile.lengthSync(),
    );

    try {
      final result = await _driveApi!.files.create(
        driveFile,
        uploadMedia: media,
      );

      await _makeFilePublic(result.id!);

      // ✅ Return FILE ID (consistent with uploadImageBytes)
      return result.id!;
    } catch (e) {
      debugPrint('❌ Drive upload failed: $e');
      rethrow;
    }
  }

  // ── Delete file from Drive ───────────────────────────────────
  Future<void> deleteFile(String fileId) async {
    await _ensureAuth();
    try {
      await _driveApi!.files.delete(fileId);
      debugPrint('🗑️ Deleted Drive file: $fileId');
    } catch (e) {
      debugPrint('⚠️ Failed to delete Drive file: $e');
      // Don't throw — replacement should succeed even if delete fails
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Make file publicly readable
  // ─────────────────────────────────────────────────────────────
  Future<void> _makeFilePublic(String fileId) async {
    try {
      await _ensureAuth();

      final permission = drive.Permission()
        ..type = 'anyone'
        ..role = 'reader';

      await _driveApi!.permissions.create(permission, fileId);
      debugPrint('🔓 File $fileId is now public');
    } catch (e) {
      debugPrint('⚠️ Failed to make file public: $e');
      // Don't rethrow - upload succeeded, just can't share publicly
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ✅ FIXED: downloadImage — handles both fileId and URL
  // ─────────────────────────────────────────────────────────────
  Future<List<int>> downloadImage(String fileIdOrUrl) async {
    await _ensureAuth();

    // Extract fileId if it's a URL, otherwise use as-is
    final fileId = _extractFileId(fileIdOrUrl) ?? fileIdOrUrl;

    debugPrint('📥 Downloading file ID: $fileId');

    try {
      final media = await _driveApi!.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = await media.stream.expand((chunk) => chunk).toList();
      debugPrint('✅ Downloaded ${bytes.length} bytes');
      return bytes;
    } catch (e) {
      debugPrint('❌ Download failed: $e');
      rethrow;
    }
  }

  /// Extracts fileId from Google Drive URL formats
  /// Returns null if the input is already a fileId (no URL pattern found)
  String? _extractFileId(String url) {
    if (url.isEmpty) return null;

    // If it's already just a fileId (no slashes, no query params)
    if (!url.contains('/') && !url.contains('?')) return null;

    // Extract from https://drive.google.com/uc?export=view&id=FILE_ID
    final idMatch = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)').firstMatch(url);
    if (idMatch != null) return idMatch.group(1);

    // Extract from https://drive.google.com/file/d/FILE_ID/view
    final pathMatch = RegExp(r'/d/([a-zA-Z0-9_-]+)').firstMatch(url);
    if (pathMatch != null) return pathMatch.group(1);

    // Extract from open?id=FILE_ID
    final openMatch = RegExp(r'open[?]id=([a-zA-Z0-9_-]+)').firstMatch(url);
    if (openMatch != null) return openMatch.group(1);

    return null;
  }

  // ─────────────────────────────────────────────────────────────
  // List files in the captures folder
  // ─────────────────────────────────────────────────────────────
  Future<List<String>> listFiles() async {
    await _ensureAuth();

    try {
      final result = await _driveApi!.files.list(
        q: "'$_capturesFolderId' in parents and trashed=false",
        $fields: 'files(name, id, createdTime, size)',
      );

      final files = result.files
          ?.map((f) => '${f.name} (${f.size} bytes) - ID: ${f.id}')
          .toList() ?? [];

      debugPrint('📁 Found ${files.length} files in Drive folder');
      return files;
    } catch (e) {
      debugPrint('❌ Failed to list files: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Auth status
  // ─────────────────────────────────────────────────────────────
  bool get isSignedIn => _currentUser != null;

  String? get currentUserEmail => _currentUser?.email;

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _authClient?.close();
    _currentUser = null;
    _driveApi = null;
    _authClient = null;
    debugPrint('👋 Signed out from Google Drive');
  }
}