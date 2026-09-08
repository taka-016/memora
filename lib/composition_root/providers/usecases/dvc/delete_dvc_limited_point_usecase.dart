import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/infrastructure/factories/repository_factory.dart';
import 'package:memora/application/usecases/dvc/delete_dvc_limited_point_usecase.dart';

final deleteDvcLimitedPointUsecaseProvider =
    Provider<DeleteDvcLimitedPointUsecase>((ref) {
      return DeleteDvcLimitedPointUsecase(
        ref.watch(dvcLimitedPointRepositoryProvider),
      );
    });
