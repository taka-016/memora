import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/dtos/dvc/dvc_point_usage_dto.dart';
import 'package:memora/application/queries/dvc/dvc_point_usage_query_service.dart';
import 'package:memora/application/queries/order_by.dart';
import 'package:memora/infrastructure/factories/query_service_factory.dart';
import 'package:memora/application/usecases/dvc/get_dvc_point_usages_usecase.dart';

final getDvcPointUsagesUsecaseProvider = Provider<GetDvcPointUsagesUsecase>((
  ref,
) {
  return GetDvcPointUsagesUsecase(ref.watch(dvcPointUsageQueryServiceProvider));
});
