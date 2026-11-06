import 'package:hurghada_winners/core/di/injection_container.dart';
import 'package:hurghada_winners/features/offers/data/offer.dart';
import 'package:hurghada_winners/features/offers/data/offers_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// عروض الإدارة.
final adminOffersProvider = FutureProvider.autoDispose<List<Offer>>(
  (ref) => sl<OffersService>().list(),
);

/// العروض السارية لفرع اللاعب.
final playerOffersProvider = FutureProvider.autoDispose<List<Offer>>(
  (ref) => sl<OffersService>().playerOffers(),
);
