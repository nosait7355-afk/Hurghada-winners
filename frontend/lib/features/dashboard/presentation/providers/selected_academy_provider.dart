import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// The academyId a super_admin is currently "acting as" (null = all academies).
final selectedAcademyIdProvider = StateProvider<String?>((ref) => null);

/// Resolves the academyId a super_admin is currently acting on, or the
/// user's own academyId for academy_admin/other roles.
final effectiveAcademyIdProvider = Provider<String?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull?.user;
  if (user == null) return null;
  if (user.isSuperAdmin) return ref.watch(selectedAcademyIdProvider);
  return user.academyId;
});
