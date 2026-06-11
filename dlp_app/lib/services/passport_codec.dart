/// Encodes a learner profile into a compact, signed QR payload and back.
///
/// Proof-of-concept signing: an HMAC-style digest over the canonical JSON
/// body with a shared demo secret. The production design replaces this with
/// an Ed25519 signature issued by the institution's edge server, so the
/// recruiter app can verify authenticity fully offline against the
/// institution's published public key.
library;

import 'dart:convert';

import '../models/models.dart';

const _demoSecret = 'knovik-dlp-poc-2026';

class DecodedPassport {
  final LearnerProfile profile;

  /// True when the signature matches — shown as "institution-verified".
  final bool verified;

  const DecodedPassport(this.profile, this.verified);
}

String _digest(String body) {
  // FNV-1a over secret + body; placeholder for Ed25519 in production.
  var hash = 0x811c9dc5;
  for (final unit in utf8.encode('$_demoSecret|$body')) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

String encodePassport(
  LearnerProfile profile, {
  bool includeScores = true,
  bool includeEngagement = true,
}) {
  final body = jsonEncode(profile.toJson(
    includeScores: includeScores,
    includeEngagement: includeEngagement,
  ));
  final envelope = jsonEncode({'v': 1, 'sig': _digest(body), 'p': body});
  return base64UrlEncode(utf8.encode(envelope));
}

/// Returns null when the payload is not a DLP passport at all.
DecodedPassport? decodePassport(String raw) {
  try {
    final envelope =
        jsonDecode(utf8.decode(base64Url.decode(raw.trim())))
            as Map<String, dynamic>;
    final body = envelope['p'] as String;
    final profile =
        LearnerProfile.fromJson(jsonDecode(body) as Map<String, dynamic>);
    return DecodedPassport(profile, envelope['sig'] == _digest(body));
  } catch (_) {
    return null;
  }
}
