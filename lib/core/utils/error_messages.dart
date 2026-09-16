import '../error/app_exception.dart';

/// Translates known backend / transport error strings to friendly Arabic
/// copy shown to the user. Unknown strings fall through to [fallback] so
/// we don't ship English or opaque codes to production customers.
///
/// Case-insensitive substring matching — the backend can send
/// `"invalid_otp"`, `"Invalid OTP"`, or `"invalid otp"` and they all map
/// to the same Arabic message. Add rows here whenever a real customer
/// support ticket surfaces a message we hadn't mapped.
///
/// The raw string is preserved on [AppException.cause] for debugging;
/// this function only affects what the customer sees.
String arabicErrorFor(
  String? raw, {
  String fallback = 'حدث خطأ غير متوقع. حاول مرة أخرى.',
}) {
  if (raw == null) return fallback;
  final r = raw.toLowerCase().trim();
  if (r.isEmpty) return fallback;

  // ── OTP / Twilio Verify ─────────────────────────────────────────────
  if (r.contains('invalid_otp') || r.contains('invalid otp')) {
    return 'رمز التحقق غير صحيح أو منتهي الصلاحية.';
  }
  if (r.contains('otp_expired') || r.contains('expired')) {
    return 'انتهت صلاحية رمز التحقق. اطلب رمزًا جديدًا.';
  }
  if (r.contains('otp_not_found') || r.contains('sid')) {
    return 'تعذّر التحقق من الرمز. اطلب رمزًا جديدًا.';
  }

  // ── Subscription gate ───────────────────────────────────────────────
  if (r.contains('subscription is required') ||
      r.contains('subscription required')) {
    return 'هذا القسم متاح للمشتركين. اشترك للوصول إليه.';
  }
  if (r.contains('already have an active subscription')) {
    return 'لديك اشتراك فعّال بالفعل.';
  }
  if (r.contains('plan not found')) {
    return 'الخطة المطلوبة غير متاحة.';
  }
  if (r.contains('nothing to cancel')) {
    return 'لا يوجد اشتراك لإلغائه.';
  }

  // ── User lookup / registration ──────────────────────────────────────
  if (r.contains('user_not_found') ||
      r.contains('user not found') ||
      r.contains('phone_not_registered')) {
    return 'لا يوجد حساب بهذا الرقم. أنشئ حسابًا جديدًا أو راجع رقم الهاتف.';
  }
  if (r.contains('duplicateusername') ||
      r.contains('duplicate user name') ||
      r.contains('phone_already_registered') ||
      r.contains('already registered') ||
      r.contains('already taken') ||
      r.contains('is already')) {
    return 'هذا الرقم مسجّل مسبقًا. سجّل الدخول أو استخدم رقمًا آخر.';
  }

  // ── ASP.NET Identity password policy ────────────────────────────────
  if (r.contains('passwordmismatch') || r.contains('incorrect password')) {
    return 'كلمة المرور غير صحيحة.';
  }
  if (r.contains('passwordrequiresdigit') ||
      r.contains('at least one digit')) {
    return 'كلمة المرور يجب أن تحتوي على رقم على الأقل.';
  }
  if (r.contains('passwordrequiresnonalphanumeric') ||
      r.contains('non-alphanumeric') ||
      r.contains('non alphanumeric')) {
    return 'كلمة المرور يجب أن تحتوي على رمز خاص (مثل ! @ #).';
  }
  if (r.contains('passwordrequireslower') ||
      r.contains('at least one lowercase')) {
    return 'كلمة المرور يجب أن تحتوي على حرف صغير.';
  }
  if (r.contains('passwordrequiresupper') ||
      r.contains('at least one uppercase')) {
    return 'كلمة المرور يجب أن تحتوي على حرف كبير.';
  }
  if (r.contains('passwordtooshort') ||
      (r.contains('at least') && r.contains('character'))) {
    return 'كلمة المرور قصيرة جدًا. استخدم ٨ أحرف على الأقل.';
  }

  // ── Login ──────────────────────────────────────────────────────────
  if (r.contains('invalid credentials') ||
      r.contains('invalid_credentials') ||
      r.contains('invalid login') ||
      r.contains('wrong password')) {
    return 'اسم المستخدم أو كلمة المرور غير صحيحة.';
  }
  if (r.contains('account is locked') ||
      r.contains('lockout') ||
      r.contains('locked')) {
    return 'الحساب مغلق مؤقتًا بسبب محاولات فاشلة. حاول لاحقًا.';
  }
  if (r.contains('account is disabled') ||
      r.contains('user is disabled') ||
      r.contains('account disabled') ||
      r.contains('isenabled')) {
    return 'الحساب معطّل. تواصل مع الدعم لمزيد من المعلومات.';
  }
  if (r.contains('email not confirmed') ||
      r.contains('phone not confirmed')) {
    return 'لم يتم تأكيد الهاتف بعد.';
  }

  // ── Phone validation ───────────────────────────────────────────────
  if (r.contains('invalid phone') || r.contains('invalid_phone')) {
    return 'رقم الهاتف غير صحيح.';
  }
  if (r.contains('phone_required') || r.contains('phone is required')) {
    return 'رقم الهاتف مطلوب.';
  }

  // ── Authorization ──────────────────────────────────────────────────
  if (r.contains('unauthorized') || r.contains(' 401 ')) {
    return 'انتهت الجلسة. سجّل الدخول من جديد.';
  }
  if (r.contains('forbidden') || r.contains(' 403 ')) {
    return 'ليس لديك صلاحية لهذا الإجراء.';
  }

  // ── Transport / network ────────────────────────────────────────────
  if (r.contains('connection refused') ||
      r.contains('connectionerror') ||
      r.contains('failed host lookup') ||
      r.contains('sockettimeout') ||
      r.contains('no internet')) {
    return 'تعذّر الاتصال. تحقّق من الإنترنت وحاول مرة أخرى.';
  }
  if (r.contains('connectiontimeout') || r.contains('timeout')) {
    return 'انتهت مهلة الاتصال. حاول مرة أخرى.';
  }
  if (r.contains(' 429 ') || r.contains('rate') || r.contains('too many')) {
    return 'محاولات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.';
  }
  if (r.contains(' 500 ') ||
      r.contains(' 502 ') ||
      r.contains(' 503 ') ||
      r.contains(' 504 ') ||
      r.contains('badresponse') ||
      r.contains('server error')) {
    return 'مشكلة في الخادم. حاول لاحقًا.';
  }

  // If the raw string already contains Arabic characters, trust it —
  // the backend probably localised the message for us (e.g.
  // domain-specific validation messages).
  if (RegExp(r'[؀-ۿ]').hasMatch(raw)) return raw;

  return fallback;
}

/// Convenience for the common pattern of localising an [AppException]'s
/// message. Preserves the original message on the exception itself — this
/// only affects display.
String arabicMessageForException(
  Object e, {
  String fallback = 'حدث خطأ غير متوقع. حاول مرة أخرى.',
}) {
  if (e is AppException) return arabicErrorFor(e.message, fallback: fallback);
  return arabicErrorFor(e.toString(), fallback: fallback);
}
