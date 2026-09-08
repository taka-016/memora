import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/usecases/member/calculate_school_grade_usecase.dart';

final calculateSchoolGradeUsecaseProvider =
    Provider<CalculateSchoolGradeUsecase>((ref) {
      return CalculateSchoolGradeUsecase();
    });
