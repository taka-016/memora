import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memora/application/models/app_mode.dart';

final appModeProvider = Provider<AppMode>((ref) => AppMode.online);
