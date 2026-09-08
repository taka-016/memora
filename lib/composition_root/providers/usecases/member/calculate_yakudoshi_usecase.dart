import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/member/calculate_yakudoshi_usecase.dart';

final calculateYakudoshiUsecaseProvider = Provider<CalculateYakudoshiUsecase>((
  ref,
) {
  return CalculateYakudoshiUsecase();
});
