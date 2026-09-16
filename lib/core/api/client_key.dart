/// Shared client secret used to derive the `X-KEY` header.
///
/// **Placeholder — MUST be replaced before shipping.** Set this to the
/// same value your backend loads for its HMAC comparison (typically
/// `Jwt:ClientSecretKey` or equivalent). The backend computes the same
/// HMAC over `window|METHOD|path` and rejects requests whose `X-KEY`
/// doesn't match.
///
/// **What this is:** a low-bar "you're a real mobile client" signal.
///
/// **What this is NOT:** a real secret. Anyone with a decompiled APK /
/// IPA can lift this value. Treat it as a bot-deterrent / curl-tarpit,
/// not as authentication. Real user identity rides `Authorization` +
/// per-device `X-Request-Key`.
///
/// If you need per-environment rotation, lift this into
/// `AppConfig.clientSecret` and override in each flavor entrypoint.
const String kClientSecretKey = 'REPLACE_WITH_YOUR_SHARED_CLIENT_SECRET';
