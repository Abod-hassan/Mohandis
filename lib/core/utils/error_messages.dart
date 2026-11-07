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

  // A developer-exception page is not a message. When the server is in
  // Development it answers a 500 with its entire stack trace as the body, and
  // substring-matching that against keywords is hopeless — `RateLimiting`
  // appears in it as an ASP.NET NAMESPACE, which is how a null-reference crash
  // in FeedController came out as "too many attempts, wait a little". Word
  // boundaries do not save you: the dot in `Microsoft.AspNetCore.RateLimiting.`
  // is one. Nothing this long is copy meant for a person, so it does not get
  // matched at all.
  //
  // Arabic is exempt. A long message that is already in Arabic is the backend
  // localising something for us — a concatenated validation list, Identity's
  // full password policy — and that is precisely what the passthrough at the
  // bottom of this function is for. Swallowing it here replaced real, useful
  // copy with "something went wrong".
  final isArabic = RegExp(r'[؀-ۿ]').hasMatch(raw);
  if (!isArabic && (r.length > 300 || r.contains('\n   at '))) {
    return fallback;
  }

  // ── E-mail codes ────────────────────────────────────────────────────
  // Before the OTP block on purpose: `email_code_expired` contains "expired"
  // and would otherwise be answered with the phone-code wording, sending
  // someone to look at their messages for a code that went to their inbox.
  if (r.contains('email_code_resend_too_soon')) {
    return 'انتظر قليلًا قبل طلب رمز جديد.';
  }
  if (r.contains('email_code_rate_limited')) {
    return 'طلبت رموزًا كثيرة خلال ساعة. حاول بعد قليل.';
  }
  if (r.contains('email_code_expired')) {
    return 'انتهت صلاحية رمز البريد. اطلب رمزًا جديدًا.';
  }
  if (r.contains('email_code_locked')) {
    return 'محاولات كثيرة على هذا الرمز. اطلب رمزًا جديدًا.';
  }
  if (r.contains('email_code_invalid')) {
    return 'رمز البريد غير صحيح.';
  }
  if (r.contains('phone_or_email_required')) {
    return 'أدخل رقم الهاتف أو البريد الإلكتروني.';
  }
  if (r.contains('account_delete_failed')) {
    return 'تعذّر حذف الحساب. حاول مرة أخرى.';
  }
  if (r.contains('email_already_in_use') || r.contains('email_ambiguous')) {
    return 'هذا البريد مسجّل بحساب آخر.';
  }
  if (r.contains('email_invalid')) {
    return 'أدخل بريدًا إلكترونيًا صحيحًا.';
  }
  // Configuration, not the person's mistake — so it says "try later" rather
  // than anything that reads as "your address is wrong".
  if (r.contains('email_sender_not_configured') ||
      r.contains('email_send_failed')) {
    return 'تعذّر إرسال رمز التأكيد إلى بريدك الآن. حاول لاحقًا.';
  }

  // ── Phone OTP ───────────────────────────────────────────────────────
  // Matched against what OTPService ACTUALLY returns. Five of its six strings
  // used to fall through to "something went wrong", including the commonest
  // one of all: the service says `otp_invalid` and this matched only
  // `invalid_otp`, the same two words the other way round. The mock was even
  // changed to emit the client's spelling, which hid it instead of fixing it.
  if (r.contains('otp_resend_too_soon')) {
    return 'انتظر قليلًا قبل طلب رمز جديد.';
  }
  if (r.contains('otp_rate_limited')) {
    return 'طلبت رموزًا كثيرة خلال ساعة. حاول بعد قليل.';
  }
  if (r.contains('otp_send_failed')) {
    return 'تعذّر إرسال الرمز إلى رقمك الآن. حاول لاحقًا.';
  }
  if (r.contains('otp_locked')) {
    return 'محاولات كثيرة على هذا الرمز. اطلب رمزًا جديدًا.';
  }
  if (r.contains('phone_invalid') ||
      r.contains('invalid phone') ||
      r.contains('invalid_phone')) {
    return 'رقم الهاتف غير صحيح.';
  }
  if (r.contains('otp_invalid') ||
      r.contains('invalid_otp') ||
      r.contains('invalid otp')) {
    return 'رمز التحقق غير صحيح أو منتهي الصلاحية.';
  }
  if (r.contains('otp_expired') || r.contains('expired')) {
    return 'انتهت صلاحية رمز التحقق. اطلب رمزًا جديدًا.';
  }
  // `sid` as a WHOLE word. A bare `contains('sid')` fires inside "consider",
  // "resident" and "inside", and it swallowed a real bug: the validation
  // failure `{"errors":{"sid":["The sid field is required."]}}` — a binder
  // complaint about a parameter the server ignores — was shown to the person
  // as "ask for a new code", which no number of new codes would ever fix.
  if (r.contains('otp_not_found') || RegExp(r'\bsid\b').hasMatch(r)) {
    return 'تعذّر التحقق من الرمز. اطلب رمزًا جديدًا.';
  }

  // ── Subscription gate ───────────────────────────────────────────────
  if (r.contains('subscription is required') ||
      r.contains('subscription required')) {
    return 'هذا القسم متاح للمشتركين. اشترك للوصول إليه.';
  }
  // ── The job board's refusals ────────────────────────────────────────
  //
  // Every one of these is a rule the app also enforces before the request is
  // sent, so reaching one means the state changed underneath — a job closed,
  // a CV removed, a subscription lapsed. They are worth translating anyway:
  // an English sentence in a red toast reads as a crash, not as a rule.
  if (r.contains('this job is closed')) {
    return 'أُغلق التقديم على هذه الوظيفة.';
  }
  if (r.contains('already applied to this job')) {
    return 'سبق أن قدّمت على هذه الوظيفة.';
  }
  if (r.contains('cannot apply to your own job')) {
    return 'لا يمكنك التقديم على وظيفة نشرتها.';
  }
  if (r.contains('company account cannot apply')) {
    return 'حسابات الشركات لا تُقدّم على الوظائف.';
  }
  if (r.contains('attach your cv')) {
    return 'أرفق سيرتك الذاتية قبل التقديم.';
  }
  // The job board's own gate — `JobService.Apply` refuses with this when the
  // caller holds nothing. The app blocks the button and the apply screen long
  // before this, so reaching it means the subscription lapsed between opening
  // the form and sending it; saying so in Arabic beats the server's English.
  if (r.contains('subscribe to apply')) {
    return 'التقديم على الوظائف متاح للمشتركين. اشترك للمتابعة.';
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

  // ── The session itself ──────────────────────────────────────────────
  // `Refresh-Token` answers these when the device, rather than the token, is
  // the problem: this install was signed out from the Devices screen, or its
  // session was ended elsewhere. The app clears the tokens either way, so the
  // copy's job is to say why they are back at the login screen rather than
  // leaving it looking like a bug.
  if (r.contains('device_revoked')) {
    return 'تم تسجيل خروج هذا الجهاز من الحساب. سجّل الدخول مرة أخرى.';
  }
  if (r.contains('session_revoked')) {
    return 'انتهت هذه الجلسة. سجّل الدخول مرة أخرى.';
  }
  // ── The course marketplace's refusals ───────────────────────────────
  //
  // Same reasoning as the job board above: the app enforces most of these
  // before sending, so reaching one usually means the state moved — a course
  // was approved while its author had the editor open, a purchase was handled
  // from another device. An English sentence in a red toast reads as a crash.
  if (r.contains('only an engineer or a company can publish')) {
    return 'نشر الدورات متاح لحسابات المهندسين والشركات فقط.';
  }
  if (r.contains('a course needs a title')) {
    return 'أدخل عنوان الدورة.';
  }
  if (r.contains('a course needs a description')) {
    return 'أضف وصفًا للدورة قبل إرسالها للمراجعة.';
  }
  if (r.contains('a course needs at least one lesson')) {
    return 'أضف درسًا واحدًا على الأقل قبل الإرسال للمراجعة.';
  }
  if (r.contains('every lesson needs its length')) {
    return 'حدّد مدة كل درس بالدقائق.';
  }
  if (r.contains('a price cannot be negative')) {
    return 'السعر لا يمكن أن يكون سالبًا.';
  }
  if (r.contains('an approved course can no longer be edited')) {
    return 'الدورة منشورة ولا يمكن تعديلها.';
  }
  if (r.contains('with the reviewer')) {
    return 'الدورة عند المراجع ولا يمكن تعديلها حتى يصدر القرار.';
  }
  if (r.contains('a lesson needs a title')) {
    return 'أدخل عنوان الدرس.';
  }
  if (r.contains('needs its file uploaded')) {
    return 'ارفع ملف الدرس أولًا.';
  }
  // A submission refused because a lesson's video is still going up. Distinct
  // copy from the one above: nothing is missing and nothing has to be picked
  // again — the author waits, or drops that lesson.
  if (r.contains('a lesson is still uploading')) {
    return 'ما زال رفع ملف أحد الدروس جاريًا. انتظر حتى يكتمل أو احذف الدرس.';
  }
  if (r.contains('article lesson needs its text')) {
    return 'أدخل نص الدرس.';
  }
  if (r.contains('lesson not found')) {
    return 'الدرس غير موجود.';
  }
  if (r.contains('course not found')) {
    return 'الدورة غير موجودة.';
  }
  if (r.contains('only a submitted course can be approved')) {
    return 'لا يمكن الموافقة إلا على دورة مُرسَلة للمراجعة.';
  }
  if (r.contains('only a submitted course can be rejected')) {
    return 'لا يمكن إعادة إلا دورة مُرسَلة للمراجعة.';
  }
  if (r.contains('a rejection needs a reason')) {
    return 'اكتب سبب الإعادة حتى يتمكن الناشر من معالجته.';
  }
  if (r.contains('has to be purchased first')) {
    return 'اشترِ الدورة أولًا لفتح دروسها.';
  }
  if (r.contains('this course is not sold')) {
    return 'هذه الدورة غير معروضة للبيع.';
  }
  if (r.contains('cannot buy your own course')) {
    return 'لا يمكنك شراء دورة نشرتها.';
  }
  if (r.contains('confirmed purchase cannot be cancelled')) {
    return 'لا يمكن إلغاء عملية شراء مؤكدة من هنا.';
  }
  if (r.contains('no longer pending')) {
    return 'لم يعد هذا الطلب قيد الانتظار.';
  }
  if (r.contains('purchase not found')) {
    return 'طلب الشراء غير موجود.';
  }
  // Only `RateAsync` still answers this — progress enrolls the caller itself.
  // Rating without having opened the course stays refused on purpose: an
  // average has to mean "what learners think".
  if (r.contains('enroll in this course first')) {
    return 'افتح الدورة وابدأ بها قبل تقييمها.';
  }

  // ── User lookup / registration ──────────────────────────────────────
  if (r.contains('user_not_found') ||
      r.contains('user not found') ||
      r.contains('phone_not_registered')) {
    return 'لا يوجد حساب بهذا الرقم. أنشئ حسابًا جديدًا أو راجع رقم الهاتف.';
  }
  // Username and phone were one row here, answering "this NUMBER is already
  // registered" to Identity's `User name 'obeida' is already taken.` — which
  // sends someone off to check a phone number that was never the problem.
  // Identity is the only source of the username form, so it is matched first
  // and narrowly.
  if (r.contains('duplicateusername') ||
      r.contains('duplicate user name') ||
      ((r.contains('user name') || r.contains('username')) &&
          (r.contains('already taken') || r.contains('is already')))) {
    return 'معرف المستخدم محجوز. اختر معرفًا آخر.';
  }
  if (r.contains('phone_already_registered') ||
      r.contains('already registered')) {
    return 'هذا الرقم مسجّل مسبقًا. سجّل الدخول أو استخدم رقمًا آخر.';
  }
  // Something is taken and the server did not say what. Deliberately vague
  // rather than guessing a field and pointing at the wrong one.
  if (r.contains('already taken') || r.contains('is already')) {
    return 'هذه البيانات مستخدمة مسبقًا. جرّب قيمة أخرى.';
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
    return 'كلمة المرور قصيرة جدًا. استخدم 8 أحرف على الأقل.';
  }

  // A connection or follow request that no longer exists — answered on
  // another screen or device, or withdrawn by its sender.
  if (r.contains('request not found')) {
    return 'تمت معالجة هذا الطلب مسبقًا.';
  }

  // ── Password reset (forgot-password) ────────────────────────────────
  if (r.contains('passwords_not_matched')) {
    return 'كلمتا المرور غير متطابقتين.';
  }
  // The server's way of saying the caller's token no longer carries
  // `RecoveryVerified` — which happens when it was rotated by a refresh. The
  // proof is gone, so the only way forward is to prove the channel again.
  if (r.contains('current password is required')) {
    return 'انتهت صلاحية التحقق. أعد إرسال الرمز وابدأ من جديد.';
  }

  // ── Device lock ─────────────────────────────────────────────────────
  if (r.contains('device_limit_reached')) {
    // Says where to go, not just what went wrong: the only way out is from a
    // phone that is still signed in, which is not somewhere the person would
    // think to look.
    return 'وصلت إلى الحد الأقصى للأجهزة على هذا الحساب. من جهاز ما زال '
        'مسجّلًا، افتح الإعدادات ثم الأجهزة واحذف جهازًا، ثم حاول مجددًا.';
  }

  // ── Login ──────────────────────────────────────────────────────────
  if (r.contains('invalid credentials') ||
      r.contains('invalid_credentials') ||
      r.contains('invalid login') ||
      r.contains('wrong password')) {
    return 'معرف المستخدم أو كلمة المرور غير صحيحة.';
  }
  // Every place this app can meet the bare string `User Unauthorized` — the
  // OTP and e-mail code redemptions — means LOCKED OUT. Ahead of the generic
  // `unauthorized` rule, which would otherwise tell someone with no session,
  // trying to recover a locked account, that their session had expired.
  // (Login says `invalid_credentials` / `account_locked`, so nothing else is
  // caught here.)
  if (r.contains('user unauthorized')) {
    return 'الحساب مغلق مؤقتًا بسبب محاولات فاشلة. حاول لاحقًا.';
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
  if (RegExp(r'\b(401|unauthorized)\b').hasMatch(r)) {
    return 'انتهت الجلسة. سجّل الدخول من جديد.';
  }
  if (RegExp(r'\b(403|forbidden)\b').hasMatch(r)) {
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
  // `contains('rate')` used to be here and was catching innocent messages by
  // substring — "generate", "generated", "operate", "accurate" and "separate"
  // all contain it, so an unrelated server error was being reported to the user
  // as rate limiting, complete with advice to wait that would never help.
  // Matched on word boundaries now, and on the status code as a whole word.
  //
  // The status code is matched only in the shapes our own plumbing produces —
  // `Request failed (429)` from `_fromStatus`, `Request failed [badResponse ·
  // 429] /path` from `apiException` — never as a bare number. Dart's `\b` is
  // ASCII-based, so it also fires between an Arabic letter and a digit, and a
  // perfectly good server message like "الحد الأقصى 500 حرف" came out as a
  // server outage.
  if (RegExp(r'\b(rate[ _-]?limit(ed|ing)?|too many)\b').hasMatch(r) ||
      _statusIs(r, '429')) {
    return 'محاولات كثيرة. انتظر قليلًا ثم حاول مرة أخرى.';
  }
  // `' 500 '` never matched: `_fromStatus` builds "Request failed (500)",
  // where the code is in brackets with no surrounding spaces. Every server
  // error was therefore reported as a generic unexpected error.
  if (_statusIs(r, '500|502|503|504') ||
      r.contains('badresponse') ||
      r.contains('server error')) {
    return 'مشكلة في الخادم. حاول لاحقًا.';
  }

  // A 404 with NO message of its own is a route the server does not have.
  //
  // This module answers a missing ROW with 400 and a sentence ("Course not
  // found."), which the blocks above already translate — so a bodyless 404 is
  // never "the thing you asked for is gone", it is "this build of the server
  // has never heard of that endpoint". Saying so turns a mystery toast into a
  // deployment check; the generic fallback cost hours of looking in the app
  // for a bug that was in which binary was running.
  if (_statusIs(r, '404')) {
    return 'هذه الميزة غير متوفرة على الخادم الحالي. تأكد من تشغيل أحدث نسخة من الخادم.';
  }

  // If the raw string already contains Arabic characters, trust it —
  // the backend probably localised the message for us (e.g.
  // domain-specific validation messages).
  if (isArabic) return raw;

  return fallback;
}

/// Does [lowered] carry one of [codes] as an HTTP status our own code emitted?
///
/// Only the two shapes this app produces count: `Request failed (500)` from
/// `ErrorInterceptor._fromStatus`, and `Request failed [badResponse · 500]
/// /path` from `apiException`. Matching a bare number instead — which a word
/// boundary amounts to — turns any sentence with a number in it into an
/// outage report.
bool _statusIs(String lowered, String codes) =>
    RegExp('request failed[^)\\]]*[(· ]($codes)\\b').hasMatch(lowered) ||
    RegExp('status(?: code)?[ :=]+($codes)\\b').hasMatch(lowered);

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
