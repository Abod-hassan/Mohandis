import 'package:mohandis/core/error/app_exception.dart';
import 'package:mohandis/core/error/result.dart';

import '../../domain/entities/job.dart';
import '../../domain/entities/job_application.dart';
import '../../domain/repositories/job_repository.dart';

class JobMockRepository implements JobRepository {
  JobMockRepository({this.latency = const Duration(milliseconds: 240)})
      : _applications = _seedApplications();

  final Duration latency;
  final List<JobApplication> _applications;

  Future<void> _wait() => Future<void>.delayed(latency);

  static DateTime _ago({int days = 0, int hours = 0}) =>
      DateTime.now().subtract(Duration(days: days, hours: hours));

  /// `applied` mirrors the server's `hasApplied`, so the two jobs with a
  /// seeded application carry it — that is what exercises the "applied on a
  /// cold start, before the applications list has loaded" path.
  static final List<Job> _jobs = [
    Job(
      id: 'j1',
      title: 'مصمم منتجات أول',
      company: 'نورثويند',
      location: 'جدة، السعودية',
      workMode: WorkMode.hybrid,
      employmentType: EmploymentType.fullTime,
      salaryLabel: '150,000 – 185,000 USD',
      postedAt: _ago(days: 2),
      applicantCount: 47,
      description:
          'قيادة التصميم الكامل لمنتجات التمويل لدينا بالتعاون مع إدارة المنتج والهندسة، '
          'لتقديم تجربة هادئة وموثوقة يستخدمها الملايين.',
      requirements: [
        'خبرة 6 سنوات فأكثر في تصميم المنتجات',
        'إتقان أنظمة التصميم والنماذج التفاعلية',
        'خبرة في التقنية المالية أو القطاعات المنظّمة',
        'مهارات تواصل كتابي قوية',
      ],
    ),
    Job(
      id: 'j2',
      title: 'عالم بيانات رئيسي',
      company: 'هيلكس بايو',
      location: 'الخبر، السعودية',
      workMode: WorkMode.onsite,
      employmentType: EmploymentType.fullTime,
      salaryLabel: '190,000 – 230,000 USD',
      postedAt: _ago(hours: 5),
      applicantCount: 12,
      applied: true,
      description:
          'بناء نماذج تحوّل بيانات الجينوم إلى رؤى سريرية. ستملك المشكلة من التأطير حتى الإنتاج.',
      requirements: [
        'دكتوراه أو خبرة معادلة',
        'تعلّم آلة في بيئة إنتاج واسعة',
        'القدرة على التعامل مع مشكلات غامضة وعالية المخاطر',
      ],
    ),
    Job(
      id: 'j3',
      title: 'مهندس واجهات أمامية',
      company: 'لوب ورك',
      location: 'عن بُعد',
      workMode: WorkMode.remote,
      employmentType: EmploymentType.fullTime,
      salaryLabel: '130,000 – 165,000 USD',
      postedAt: _ago(days: 1),
      applicantCount: 88,
      description:
          'بناء الواجهات التي يُحكم على منتجنا من خلالها. فريق صغير، مسؤولية عالية، وحرفية حقيقية.',
      requirements: [
        'خبرة 4 سنوات فأكثر في رياكت وتايب سكريبت',
        'اهتمام بإمكانية الوصول والأداء',
        'القدرة على امتلاك الميزة من البداية للنهاية',
      ],
    ),
    Job(
      id: 'j4',
      title: 'ممارس تمريض — أمراض القلب',
      company: 'مستشفى الرحمة',
      location: 'الدمام، السعودية',
      workMode: WorkMode.onsite,
      employmentType: EmploymentType.fullTime,
      salaryLabel: '120,000 – 140,000 USD',
      postedAt: _ago(days: 3),
      applicantCount: 9,
      description:
          'تقديم رعاية قلبية قائمة على الأدلة في عيادة خارجية تعاونية عالية الحركة.',
      requirements: [
        'رخصة ممارس تمريض سارية',
        'يفضّل خبرة سنتين في أمراض القلب',
        'مهارات تعامل ممتازة مع المرضى',
      ],
    ),
    // No workplace mode and no salary: the posting form leaves both optional,
    // so the cards have to render without them.
    Job(
      id: 'j5',
      title: 'مهندس مدني (النقل)',
      company: 'ميريديان للبنية التحتية',
      location: 'القاهرة، مصر',
      employmentType: EmploymentType.contract,
      postedAt: _ago(days: 6),
      applicantCount: 23,
      description:
          'تصميم ومراجعة البنية التحتية لشبكات النقل في منطقة حضرية متنامية.',
      requirements: [
        'رخصة هندسية مطلوبة',
        'خبرة في النقل أو السكك',
        'أوتوكاد سيفل ثري دي',
      ],
    ),
    Job(
      id: 'j6',
      title: 'قائد تسويق العلامة التجارية',
      company: 'سِدر وشركاه',
      location: 'الكويت',
      workMode: WorkMode.hybrid,
      employmentType: EmploymentType.fullTime,
      salaryLabel: '135,000 – 160,000 USD',
      postedAt: _ago(days: 4),
      applicantCount: 61,
      applied: true,
      description:
          'امتلاك استراتيجية العلامة التجارية والحملات لشركة استهلاكية سريعة النمو.',
      requirements: [
        'خبرة 8 سنوات فأكثر في تسويق العلامات',
        'سجل حافل في إطلاق الحملات',
        'يفضّل خبرة في القطاع الاستهلاكي',
      ],
    ),
  ];

  /// Filled in enough to exercise the poster's view: a headline, a note and a
  /// résumé on one row, and a bare row beside it for the empty states.
  static List<JobApplication> _seedApplications() => [
        JobApplication(
          id: 'a1',
          jobId: 'j6',
          status: ApplicationStatus.inReview,
          submittedAt: _ago(days: 3),
          applicantId: 'p2',
          applicantName: 'أمل الحسن',
          applicantHeadline: 'مهندسة برمجيات · هندسة البرمجيات',
          coverLetter:
              'خبرة أربع سنوات في تطوير الواجهات، وعملت على تطبيقين '
              'بمليون مستخدم. أرفقت سيرتي الذاتية وسأسعد بالحديث عن '
              'التفاصيل في مقابلة.',
          resumeUrl: 'cv/mock-applicant.pdf',
        ),
        JobApplication(
          id: 'a2',
          jobId: 'j2',
          status: ApplicationStatus.submitted,
          submittedAt: _ago(days: 1),
          applicantId: 'p3',
          applicantName: 'مروان العبيدي',
        ),
      ];

  @override
  Future<Result<List<Job>, AppException>> getAll({
    Map<String, dynamic>? query,
  }) async {
    await _wait();
    return Result.success(List.unmodifiable(_jobs));
  }

  /// Kept in memory, so the fixture backend can demonstrate the list without
  /// pretending to persist anything past a restart.
  final Set<String> _saved = <String>{};

  @override
  Future<Result<List<Job>, AppException>> saved() async {
    await _wait();
    return Result.success(
      _jobs.where((j) => _saved.contains(j.id)).toList(growable: false),
    );
  }

  @override
  Future<Result<Job, AppException>> toggleSave(String jobId) async {
    await _wait();
    if (!_saved.remove(jobId)) _saved.add(jobId);
    final job = _jobs.where((j) => j.id == jobId);
    if (job.isEmpty) {
      return const Result.failure(NotFoundException('Job not found'));
    }
    return Result.success(job.first.copyWith(saved: _saved.contains(jobId)));
  }

  @override
  Future<Result<List<Job>, AppException>> search(JobFilters filters) async {
    await _wait();
    final q = filters.query.trim().toLowerCase();
    return Result.success(
      _jobs.where((j) {
        final matchesQuery = q.isEmpty ||
            j.title.toLowerCase().contains(q) ||
            j.company.toLowerCase().contains(q) ||
            j.location.toLowerCase().contains(q);
        final matchesMode =
            filters.workMode == null || j.workMode == filters.workMode;
        // Mirrors the real filter's `openOnly: true` — browsing hides closed
        // postings even though they still resolve by id.
        return j.isOpen && matchesQuery && matchesMode;
      }).toList(growable: false),
    );
  }

  @override
  Future<Result<Job, AppException>> getById(String id) async {
    await _wait();
    final match = _jobs.where((j) => j.id == id);
    if (match.isEmpty) {
      return Result.failure(NotFoundException('لا توجد وظيفة بالمعرف $id'));
    }
    return Result.success(match.first);
  }

  @override
  Future<Result<List<JobApplication>, AppException>> applications() async {
    await _wait();
    return Result.success(List.unmodifiable(_applications));
  }

  @override
  Future<Result<JobApplication, AppException>> apply({
    required String jobId,
    String? resumeUrl,
    String coverLetter = '',
  }) async {
    await _wait();
    if (_applications.any((a) => a.jobId == jobId)) {
      return const Result.failure(
        ValidationException('لقد قدّمت على هذه الوظيفة بالفعل'),
      );
    }
    final application = JobApplication(
      id: 'local-a${_applications.length + 1}',
      jobId: jobId,
      status: ApplicationStatus.submitted,
      submittedAt: DateTime.now(),
      resumeUrl: resumeUrl ?? '',
      coverLetter: coverLetter,
    );
    _applications.insert(0, application);
    return Result.success(application);
  }

  // ── The poster's side ────────────────────────────────────────────────────

  /// The seed data has no poster identity, so "my postings" is the whole list
  /// in mock mode. It keeps the company screens renderable for design work
  /// without inventing a second set of fixtures.
  @override
  Future<Result<List<Job>, AppException>> postedBy(String profileId) async {
    await _wait();
    return Result.success(List<Job>.unmodifiable(_jobs));
  }

  @override
  Future<Result<List<JobApplication>, AppException>> applicants(
    String jobId,
  ) async {
    await _wait();
    return Result.success(
      _applications.where((a) => a.jobId == jobId).toList(growable: false),
    );
  }

  @override
  Future<Result<bool, AppException>> setApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
  }) async {
    await _wait();
    final index = _applications.indexWhere((a) => a.id == applicationId);
    if (index == -1) {
      return const Result.failure(NotFoundException('لم يتم العثور على الطلب'));
    }
    _applications[index] = _applications[index].copyWith(status: status);
    return const Result.success(true);
  }

  @override
  Future<Result<Job, AppException>> publish({
    required String title,
    required String company,
    String? location,
    EmploymentType? employmentType,
    WorkMode? workMode,
    String description = '',
    String? requirements,
    num? salaryMin,
    num? salaryMax,
    String? currency,
  }) async {
    await _wait();
    final job = Job(
      id: 'local-j${_jobs.length + 1}',
      title: title.trim(),
      company: company.trim(),
      location: location?.trim() ?? '',
      postedAt: DateTime.now(),
      applicantCount: 0,
      workMode: workMode,
      employmentType: employmentType,
      description: description.trim(),
      requirements: requirements == null || requirements.trim().isEmpty
          ? const []
          : requirements
                .split('\n')
                .map((line) => line.trim())
                .where((line) => line.isNotEmpty)
                .toList(growable: false),
    );
    _jobs.insert(0, job);
    return Result.success(job);
  }

  // ── Unsupported writes ───────────────────────────────────────────────────

  @override
  Future<Result<Job, AppException>> create(Map<String, dynamic> body) async =>
      const Result.failure(ForbiddenException('غير مدعوم في وضع البيانات التجريبية'));

  @override
  Future<Result<Job, AppException>> update(
    String id,
    Map<String, dynamic> body,
  ) async =>
      const Result.failure(ForbiddenException('غير مدعوم في وضع البيانات التجريبية'));

  @override
  Future<Result<void, AppException>> delete(String id) async =>
      const Result.failure(ForbiddenException('غير مدعوم في وضع البيانات التجريبية'));
}
