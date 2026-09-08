import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/dvc/get_dvc_point_usages_usecase.dart';

final getDvcPointUsagesUsecaseProvider = Provider<GetDvcPointUsagesUsecase>((
  ref,
) {
  return GetDvcPointUsagesUsecase(ref.watch(dvcPointUsageQueryServiceProvider));
});
