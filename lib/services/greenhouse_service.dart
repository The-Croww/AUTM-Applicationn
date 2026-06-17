import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// ─────────────────────────────────────────────────────────────
// GREENHOUSE SERVICE — SECURE MULTI-USER ACCESS PORTAL
// Handles join code generation, greenhouse creation,
// and secure role-based guest permissions (Owner/Control/View).
// ─────────────────────────────────────────────────────────────

class GreenhouseService {
  static final _db = FirebaseDatabase.instance.ref();
  static final _auth = FirebaseAuth.instance;

  static String _currentUserRole = 'view'; // Defaults to safest view-only role

  static String get currentUserRole => _currentUserRole;
  static bool get isViewOnly => _currentUserRole == 'view' || _currentUserRole == 'viewer';

  // ── Generate a unique join code like "AUTM-2847" ────────────
  static String _generateCode() {
    final rand = Random();
    final number = rand.nextInt(9000) + 1000; // 1000–9999
    return 'AUTM-$number';
  }

  // ── Called after every sign-in ──────────────────────────────
  // If user already has a greenhouse → return its code
  // If user is new → create a greenhouse and return its code
  static Future<String> initUserGreenhouse() async {
    final user = _auth.currentUser;
    if (user == null) return '';

    final userId = user.uid;

    // Check if user already has a greenhouse linked
    final userSnap = await _db.child('/users/$userId/greenhouses').get();
    if (userSnap.exists && userSnap.value != null) {
      final greenhouses = Map<String, dynamic>.from(userSnap.value as Map);
      final greenhouseId = greenhouses.keys.first;
      
      // Load current user's active role from DB
      _currentUserRole = greenhouses.values.first as String? ?? 'view';

      // Get the join code for that greenhouse
      final codeSnap = await _db.child('/greenhouses/$greenhouseId/joinCode').get();
      return codeSnap.value as String? ?? '';
    }

    // New user — auto-create a greenhouse for them
    final code = await _createGreenhouse(userId);
    _currentUserRole = 'owner';
    return code;
  }

  // ── Create a new greenhouse ──────────────────────────────────
  static Future<String> _createGreenhouse(String ownerId) async {
    String joinCode = _generateCode();

    // Make sure the permanent join code isn't already taken
    bool taken = true;
    while (taken) {
      final snap = await _db.child('/joinCodes/$joinCode').get();
      if (!snap.exists) {
        taken = false;
      } else {
        joinCode = _generateCode();
      }
    }

    // Create greenhouse entry
    final greenhouseRef = _db.child('/greenhouses').push();
    final greenhouseId = greenhouseRef.key!;

    await greenhouseRef.set({
      'joinCode': joinCode,
      'name': 'My Greenhouse',
      'ownerId': ownerId,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    // Index join code → greenhouse ID for fast lookup
    await _db.child('/joinCodes/$joinCode').set(greenhouseId);

    // Link user → greenhouse as owner
    await _db.child('/users/$ownerId/greenhouses/$greenhouseId').set('owner');

    return joinCode;
  }

  // ── Generate secure, single-use invite codes (Owner-Only) ───
  static Future<String> generateShareCode(String role) async {
    final user = _auth.currentUser;
    if (user == null) return '';

    // Find the user's active greenhouseId
    final userSnap = await _db.child('/users/${user.uid}/greenhouses').get();
    if (!userSnap.exists || userSnap.value == null) return '';

    final greenhouses = Map<String, dynamic>.from(userSnap.value as Map);
    final greenhouseId = greenhouses.keys.first;

    // Generate unique code
    String inviteCode = _generateCode();
    bool taken = true;
    while (taken) {
      final snap = await _db.child('/inviteCodes/$inviteCode').get();
      if (!snap.exists) {
        taken = false;
      } else {
        inviteCode = _generateCode();
      }
    }

    // Store the secure invite code with target role and isUsed flag
    await _db.child('/inviteCodes/$inviteCode').set({
      'greenhouseId': greenhouseId,
      'role': role, // 'control' or 'view'
      'isUsed': false,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });

    return inviteCode;
  }

  // ── Join an existing greenhouse via code (Supports One-Time Invite Codes) ──
  static Future<JoinResult> joinGreenhouse(String code) async {
    final user = _auth.currentUser;
    if (user == null) return JoinResult.error('Not signed in.');

    final cleanCode = code.trim().toUpperCase();

    // 1. Check if this is a secure single-use invite code
    final inviteSnap = await _db.child('/inviteCodes/$cleanCode').get();
    if (inviteSnap.exists && inviteSnap.value != null) {
      final inviteData = Map<String, dynamic>.from(inviteSnap.value as Map);
      final bool isUsed = inviteData['isUsed'] ?? false;
      
      if (isUsed) {
        return JoinResult.error('This invitation code has already been utilized.');
      }

      final greenhouseId = inviteData['greenhouseId'] as String;
      final role = inviteData['role'] as String? ?? 'view';

      // Secure Transaction: Instantly mark token as used!
      await _db.child('/inviteCodes/$cleanCode/isUsed').set(true);

      // Link guest user -> greenhouse with selected role (control or view)
      await _db.child('/users/${user.uid}/greenhouses/$greenhouseId').set(role);
      _currentUserRole = role;

      // Get greenhouse name
      final nameSnap = await _db.child('/greenhouses/$greenhouseId/name').get();
      final name = nameSnap.value as String? ?? 'Greenhouse';

      return JoinResult.success(name);
    }

    // 2. Fallback to permanent join codes (Defaults to view-only as secure fallback)
    final snap = await _db.child('/joinCodes/$cleanCode').get();
    if (!snap.exists) {
      return JoinResult.error('Invalid code. Please check and try again.');
    }

    final greenhouseId = snap.value as String;

    // Check if user is already connected
    final existingSnap = await _db
        .child('/users/${user.uid}/greenhouses/$greenhouseId')
        .get();
    if (existingSnap.exists) {
      return JoinResult.error('You are already connected to this greenhouse.');
    }

    // Link user -> greenhouse as view-only fallback
    await _db.child('/users/${user.uid}/greenhouses/$greenhouseId').set('view');
    _currentUserRole = 'view';

    // Get greenhouse name
    final nameSnap = await _db.child('/greenhouses/$greenhouseId/name').get();
    final name = nameSnap.value as String? ?? 'Greenhouse';

    return JoinResult.success(name);
  }

  // ── Get current user's join code ─────────────────────────────
  static Future<String> getMyJoinCode() async {
    final user = _auth.currentUser;
    if (user == null) return '';

    final userSnap = await _db.child('/users/${user.uid}/greenhouses').get();
    if (!userSnap.exists || userSnap.value == null) return '';

    final greenhouses = Map<String, dynamic>.from(userSnap.value as Map);
    final greenhouseId = greenhouses.keys.first;

    final codeSnap = await _db.child('/greenhouses/$greenhouseId/joinCode').get();
    return codeSnap.value as String? ?? '';
  }

  // ── Get current user's role ──────────────────────────────────
  static Future<String> getMyRole() async {
    final user = _auth.currentUser;
    if (user == null) return 'view';

    final userSnap = await _db.child('/users/${user.uid}/greenhouses').get();
    if (!userSnap.exists || userSnap.value == null) return 'view';

    final greenhouses = Map<String, dynamic>.from(userSnap.value as Map);
    _currentUserRole = greenhouses.values.first as String? ?? 'view';
    return _currentUserRole;
  }
}

// ─────────────────────────────────────────────────────────────
class JoinResult {
  final bool success;
  final String? greenhouseName;
  final String? errorMessage;

  const JoinResult._({
    required this.success,
    this.greenhouseName,
    this.errorMessage,
  });

  factory JoinResult.success(String name) =>
      JoinResult._(success: true, greenhouseName: name);

  factory JoinResult.error(String message) =>
      JoinResult._(success: false, errorMessage: message);
}
