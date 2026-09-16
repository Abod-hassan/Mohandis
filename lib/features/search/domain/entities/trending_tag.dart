import 'package:flutter_mobile_template/core/base/base_entity.dart';

class TrendingTag extends BaseEntity {
  const TrendingTag({required this.tag, required this.postCount});

  @override
  String get id => tag;

  final String tag;
  final int postCount;
}
