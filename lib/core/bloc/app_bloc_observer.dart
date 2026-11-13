import 'package:app_core/core/logging/app_logger.dart';
import 'package:bloc/bloc.dart';

/// Logs Bloc transitions (dev/qa only) and errors (all flavors).
class AppBlocObserver extends BlocObserver {
  new({required this._logger, required this._logTransitions});

  final AppLogger _logger;
  final bool _logTransitions;

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    if (_logTransitions) _logger.verbose('onCreate ${bloc.runtimeType}');
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    if (_logTransitions) _logger.debug('${bloc.runtimeType} $transition');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    // Blocs are logged in onTransition; only log Cubits here.
    if (_logTransitions && bloc is! Bloc) {
      _logger.debug('${bloc.runtimeType} $change');
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _logger.error(
      'Unhandled error in ${bloc.runtimeType}',
      error: error,
      stackTrace: stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    if (_logTransitions) _logger.verbose('onClose ${bloc.runtimeType}');
    super.onClose(bloc);
  }
}
