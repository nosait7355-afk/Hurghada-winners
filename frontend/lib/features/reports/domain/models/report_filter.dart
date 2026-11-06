class ReportFilter {
  final String? academyId;
  final String? academyName;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? subscriptionStatus; // 'active' | 'expired' | null (all)
  final String currencyLabel; // Arabic currency label for the academy
  final String? sport; // null = all sports
  final bool isMultiSport; // whether the academy has more than one sport
  final String? groupId; // null = all groups (independent of sport)
  final String? groupName; // display name for the selected group

  const ReportFilter({
    this.academyId,
    this.academyName,
    this.startDate,
    this.endDate,
    this.subscriptionStatus,
    this.currencyLabel = 'جنيه',
    this.sport,
    this.isMultiSport = false,
    this.groupId,
    this.groupName,
  });

  /// Title scope suffix: ' - كرة القدم' for a specific sport, ' - جميع
  /// الرياضات' for a multi-sport academy with no sport selected, or '' for
  /// single-sport academies (keeps the original titles unchanged).
  String get scopeSuffix {
    final parts = <String>[];
    if (sport != null && sport!.isNotEmpty) {
      parts.add(sport!);
    } else if (isMultiSport) {
      parts.add('جميع الرياضات');
    }
    if (groupName != null && groupName!.isNotEmpty) {
      parts.add('مجموعة ${groupName!}');
    }
    return parts.isEmpty ? '' : ' - ${parts.join(' / ')}';
  }

  ReportFilter copyWith({
    Object? academyId = _sentinel,
    Object? academyName = _sentinel,
    Object? startDate = _sentinel,
    Object? endDate = _sentinel,
    Object? subscriptionStatus = _sentinel,
    String? currencyLabel,
    Object? sport = _sentinel,
    bool? isMultiSport,
    Object? groupId = _sentinel,
    Object? groupName = _sentinel,
  }) {
    return ReportFilter(
      academyId:
          academyId == _sentinel ? this.academyId : academyId as String?,
      academyName:
          academyName == _sentinel ? this.academyName : academyName as String?,
      startDate:
          startDate == _sentinel ? this.startDate : startDate as DateTime?,
      endDate: endDate == _sentinel ? this.endDate : endDate as DateTime?,
      subscriptionStatus: subscriptionStatus == _sentinel
          ? this.subscriptionStatus
          : subscriptionStatus as String?,
      currencyLabel: currencyLabel ?? this.currencyLabel,
      sport: sport == _sentinel ? this.sport : sport as String?,
      isMultiSport: isMultiSport ?? this.isMultiSport,
      groupId: groupId == _sentinel ? this.groupId : groupId as String?,
      groupName:
          groupName == _sentinel ? this.groupName : groupName as String?,
    );
  }
}

const _sentinel = Object();
