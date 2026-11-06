import 'dart:async';

import 'package:hurghada_winners/core/constants/app_colors.dart';
import 'package:hurghada_winners/features/matches/presentation/providers/matches_providers.dart';
import 'package:hurghada_winners/features/player/presentation/providers/player_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gap/gap.dart';

/// اختيار لاعبين لإضافتهم إلى مباراة: بحث (بتأخير 400ms) على لاعبي الأكاديمية،
/// إضافة فورية (متفائلة) لكل لاعب عند النقر عليه.
class SelectMatchPlayersScreen extends ConsumerStatefulWidget {
  final String matchId;
  final String academyId;
  final List<String> alreadyAdded;

  const SelectMatchPlayersScreen({
    super.key,
    required this.matchId,
    required this.academyId,
    required this.alreadyAdded,
  });

  @override
  ConsumerState<SelectMatchPlayersScreen> createState() => _SelectMatchPlayersScreenState();
}

class _SelectMatchPlayersScreenState extends ConsumerState<SelectMatchPlayersScreen> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  late Set<String> _added;
  final Set<String> _pending = {};
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _added = Set<String>.from(widget.alreadyAdded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(playersProvider.notifier).openForAcademy(widget.academyId);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(playersProvider.notifier).search(query);
    });
  }

  Future<void> _toggle(String playerId) async {
    if (_added.contains(playerId) || _pending.contains(playerId)) return;
    setState(() => _pending.add(playerId));
    final ok =
        await ref.read(matchDetailProvider(widget.matchId).notifier).addPlayers([playerId]);
    if (!mounted) return;
    setState(() {
      _pending.remove(playerId);
      if (ok) {
        _added.add(playerId);
        _changed = true;
      }
    });
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّرت الإضافة. حاول مرة أخرى.'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final playersAsync = ref.watch(playersProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('اختيار اللاعبين')),
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(12.r),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'ابحث باسم اللاعب...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                    borderSide: const BorderSide(color: AppColors.grey200),
                  ),
                ),
              ),
            ),
            Expanded(
              child: playersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const Center(child: Text('تعذّر تحميل اللاعبين')),
                data: (state) {
                  final players = state.players;
                  if (players.isEmpty) {
                    return Center(
                      child: Text('لا يوجد لاعبون',
                          style: TextStyle(color: AppColors.grey500, fontSize: 14.sp)),
                    );
                  }
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 90.h),
                    itemCount: players.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final p = players[index];
                      final isAdded = _added.contains(p.id);
                      final isPending = _pending.contains(p.id);
                      return Material(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        child: InkWell(
                          onTap: isAdded || isPending ? null : () => _toggle(p.id),
                          borderRadius: BorderRadius.circular(12.r),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(color: AppColors.grey200),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(p.fullName,
                                          style: TextStyle(
                                              fontSize: 14.sp, fontWeight: FontWeight.w700)),
                                      Gap(2.h),
                                      Text(p.playerCode,
                                          style: TextStyle(
                                              fontSize: 11.5.sp, color: AppColors.grey500)),
                                    ],
                                  ),
                                ),
                                if (isPending)
                                  SizedBox(
                                    width: 18.r,
                                    height: 18.r,
                                    child: const CircularProgressIndicator(strokeWidth: 2),
                                  )
                                else if (isAdded)
                                  Container(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text('تمت الإضافة ✓',
                                        style: TextStyle(
                                            color: AppColors.success,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w700)),
                                  )
                                else
                                  Icon(Icons.add_circle_outline,
                                      color: AppColors.primary, size: 22.sp),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_changed),
                child: const Text('إنشاء القائمة'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
