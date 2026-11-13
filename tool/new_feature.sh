#!/usr/bin/env bash
# Scaffold a new feature with the same Clean Architecture layout as lib/features/example.
#
# Usage:
#   tool/new_feature.sh <feature_name> [--entity <entity_name>] [--no-wire]
#   make feature NAME=orders [ENTITY=order]
#
#   <feature_name>  lower_snake_case, e.g. orders or order_history
#   --entity        Name of the domain entity (default: the feature name), e.g. order
#   --no-wire       Don't register the feature in injection_container.dart / the router
#
# Creates a compiling, tested vertical slice: entity, model, remote data source, repository,
# use case, bloc (started/refreshed), page, widget, DI registration and a bloc test.
# Then wires DI + a GoRoute, runs codegen and formats the new files.
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }
usage() { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

FEAT="" ENT="" WIRE=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --entity) ENT="${2:-}"; shift 2 ;;
    --no-wire) WIRE=0; shift ;;
    -h|--help) usage 0 ;;
    -*) echo "unknown option: $1" >&2; usage 1 ;;
    *) [[ -z "$FEAT" ]] || usage 1; FEAT="$1"; shift ;;
  esac
done

[[ -n "$FEAT" ]] || usage 1
ENT="${ENT:-$FEAT}"
for n in "$FEAT" "$ENT"; do
  [[ "$n" =~ ^[a-z][a-z0-9]*(_[a-z0-9]+)*$ ]] || die "'$n' must be lower_snake_case, e.g. order_history"
done

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
PKG="$(sed -n 's/^name: *//p' pubspec.yaml | head -1)"
[[ -n "$PKG" ]] || die "could not read package name from pubspec.yaml"
DIR="lib/features/$FEAT"
[[ -e "$DIR" ]] && die "$DIR already exists"

pascal() { perl -pe 's/(^|_)([a-z0-9])/\U$2/g' <<<"$1"; }
camel() { perl -pe 's/_([a-z0-9])/\U$1/g' <<<"$1"; }
export PKG FEAT ENT
export FEAT_P="$(pascal "$FEAT")" FEAT_C="$(camel "$FEAT")"
export ENT_P="$(pascal "$ENT")" ENT_C="$(camel "$ENT")"
# Path segment for the route, e.g. order_history -> /order-history
export FEAT_URL="${FEAT//_/-}"

CREATED=()
# emit <path>  (template on stdin; placeholders replaced)
emit() {
  mkdir -p "$(dirname "$1")"
  perl -pe '
    s/__PKG__/$ENV{PKG}/g;
    s/__feat__/$ENV{FEAT}/g;   s/__Feat__/$ENV{FEAT_P}/g;  s/__featC__/$ENV{FEAT_C}/g;
    s/__ent__/$ENV{ENT}/g;     s/__Ent__/$ENV{ENT_P}/g;    s/__entC__/$ENV{ENT_C}/g;
    s/__url__/$ENV{FEAT_URL}/g;
  ' >"$1"
  CREATED+=("$1")
}

P="package:$PKG/features/$FEAT"

# ---------------------------------------------------------------- domain
emit "$DIR/domain/entities/${ENT}.dart" <<'EOF'
import 'package:freezed_annotation/freezed_annotation.dart';

part '__ent__.freezed.dart';

/// Domain entity. Pure Dart: no Flutter, JSON or framework concerns.
// TODO(__featC__): replace the placeholder fields.
@freezed
abstract class __Ent__ with _$__Ent__ {
  const factory({required int id, required String name}) = ___Ent__;
}
EOF

emit "$DIR/domain/repositories/${FEAT}_repository.dart" <<'EOF'
import 'package:__PKG__/core/utils/typedefs.dart';
import 'package:__PKG__/features/__feat__/domain/entities/__ent__.dart';

/// Contract implemented by the data layer.
abstract interface class __Feat__Repository {
  FutureEither<List<__Ent__>> get__Ent__List();
}
EOF

emit "$DIR/domain/usecases/get_${ENT}_list_use_case.dart" <<'EOF'
import 'package:__PKG__/core/usecase/usecase.dart';
import 'package:__PKG__/core/utils/typedefs.dart';
import 'package:__PKG__/features/__feat__/domain/entities/__ent__.dart';
import 'package:__PKG__/features/__feat__/domain/repositories/__feat___repository.dart';

class Get__Ent__ListUseCase implements UseCase<List<__Ent__>, NoParams> {
  const new(this._repository);

  final __Feat__Repository _repository;

  @override
  FutureEither<List<__Ent__>> call(NoParams params) =>
      _repository.get__Ent__List();
}
EOF

# ---------------------------------------------------------------- data
emit "$DIR/data/models/${ENT}_model.dart" <<'EOF'
import 'package:__PKG__/features/__feat__/domain/entities/__ent__.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part '__ent___model.freezed.dart';
part '__ent___model.g.dart';

/// API model. `build.yaml` sets `field_rename: snake` by default.
@freezed
abstract class __Ent__Model with _$__Ent__Model {
  const factory({required int id, required String name}) = ___Ent__Model;

  const new _();

  factory fromJson(Map<String, dynamic> json) => _$__Ent__ModelFromJson(json);

  __Ent__ toEntity() => __Ent__(id: id, name: name);
}
EOF

emit "$DIR/data/datasources/${FEAT}_remote_data_source.dart" <<'EOF'
import 'package:__PKG__/core/error/exceptions.dart';
import 'package:__PKG__/core/utils/typedefs.dart';
import 'package:__PKG__/features/__feat__/data/models/__ent___model.dart';
import 'package:dio/dio.dart';

abstract interface class __Feat__RemoteDataSource {
  /// Throws a [DioException] or [ParsingException] on failure.
  Future<List<__Ent__Model>> fetch__Ent__List();
}

class __Feat__RemoteDataSourceImpl implements __Feat__RemoteDataSource {
  const new(this._dio);

  final Dio _dio;

  // TODO(__featC__): set the real endpoint.
  static const String _path = '/__url__';

  @override
  Future<List<__Ent__Model>> fetch__Ent__List() async {
    final response = await _dio.get<List<dynamic>>(_path);
    final data = response.data;
    if (data == null) throw const ParsingException('Empty response body');
    return data
        .cast<JsonMap>()
        .map(__Ent__Model.fromJson)
        .toList(growable: false);
  }
}
EOF

emit "$DIR/data/repositories/${FEAT}_repository_impl.dart" <<'EOF'
import 'package:__PKG__/core/error/error_mapper.dart';
import 'package:__PKG__/core/error/failure.dart';
import 'package:__PKG__/core/network/network_info.dart';
import 'package:__PKG__/core/utils/typedefs.dart';
import 'package:__PKG__/features/__feat__/data/datasources/__feat___remote_data_source.dart';
import 'package:__PKG__/features/__feat__/domain/entities/__ent__.dart';
import 'package:__PKG__/features/__feat__/domain/repositories/__feat___repository.dart';
import 'package:fpdart/fpdart.dart' show Left, Right;

/// Every exception is mapped to a typed [Failure] here.
class __Feat__RepositoryImpl implements __Feat__Repository {
  const new({
    required __Feat__RemoteDataSource remoteDataSource,
    required this._networkInfo,
  }) : _remote = remoteDataSource;

  final __Feat__RemoteDataSource _remote;
  final NetworkInfo _networkInfo;

  @override
  FutureEither<List<__Ent__>> get__Ent__List() async {
    try {
      if (!await _networkInfo.isConnected) return const Left(Failure.network());
      final models = await _remote.fetch__Ent__List();
      return Right(models.map((m) => m.toEntity()).toList());
    } on Object catch (e) {
      return Left(ErrorMapper.toFailure(e));
    }
  }
}
EOF

# ---------------------------------------------------------------- presentation
emit "$DIR/presentation/bloc/${FEAT}_bloc.dart" <<'EOF'
import 'package:__PKG__/core/error/failure.dart';
import 'package:__PKG__/core/usecase/usecase.dart';
import 'package:__PKG__/features/__feat__/domain/entities/__ent__.dart';
import 'package:__PKG__/features/__feat__/domain/usecases/get___ent___list_use_case.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part '__feat___bloc.freezed.dart';
part '__feat___event.dart';
part '__feat___state.dart';

/// Depends on use cases only — never on repositories or data sources.
class __Feat__Bloc extends Bloc<__Feat__Event, __Feat__State> {
  new({required this._get__Ent__List})
    : super(const __Feat__State.initial()) {
    on<__Feat__Started>(_onStarted, transformer: droppable());
    on<__Feat__Refreshed>(_onRefreshed, transformer: restartable());
  }

  final Get__Ent__ListUseCase _get__Ent__List;

  Future<void> _onStarted(
    __Feat__Started event,
    Emitter<__Feat__State> emit,
  ) async {
    emit(const __Feat__State.loading());
    await _load(emit);
  }

  /// Keeps the current content on screen while refreshing (no `loading`).
  Future<void> _onRefreshed(
    __Feat__Refreshed event,
    Emitter<__Feat__State> emit,
  ) => _load(emit);

  Future<void> _load(Emitter<__Feat__State> emit) async {
    final result = await _get__Ent__List(const NoParams());
    emit(result.match(__Feat__State.failure, __Feat__State.loaded));
  }
}
EOF

emit "$DIR/presentation/bloc/${FEAT}_event.dart" <<'EOF'
part of '__feat___bloc.dart';

@freezed
sealed class __Feat__Event with _$__Feat__Event {
  /// Initial load and retry. Handled with `droppable()`.
  const factory started() = __Feat__Started;

  /// Pull-to-refresh. Handled with `restartable()`.
  const factory refreshed() = __Feat__Refreshed;
}
EOF

emit "$DIR/presentation/bloc/${FEAT}_state.dart" <<'EOF'
part of '__feat___bloc.dart';

/// An empty list in [__Feat__Loaded] is the empty state.
@freezed
sealed class __Feat__State with _$__Feat__State {
  const factory initial() = __Feat__Initial;
  const factory loading() = __Feat__Loading;
  const factory loaded(List<__Ent__> items) = __Feat__Loaded;
  const factory failure(Failure failure) = __Feat__Failure;
}
EOF

emit "$DIR/presentation/widgets/${ENT}_tile.dart" <<'EOF'
import 'package:__PKG__/features/__feat__/domain/entities/__ent__.dart';
import 'package:flutter/material.dart';

class __Ent__Tile extends StatelessWidget {
  const new({required this.item, super.key});

  final __Ent__ item;

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(item.name));
  }
}
EOF

emit "$DIR/presentation/pages/${FEAT}_page.dart" <<'EOF'
import 'package:__PKG__/core/extensions/context_extensions.dart';
import 'package:__PKG__/features/__feat__/presentation/bloc/__feat___bloc.dart';
import 'package:__PKG__/features/__feat__/presentation/widgets/__ent___tile.dart';
import 'package:__PKG__/shared/widgets/app_loader.dart';
import 'package:__PKG__/shared/widgets/empty_view.dart';
import 'package:__PKG__/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Expects a [__Feat__Bloc] above it (provided by the route builder).
class __Feat__Page extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // TODO(__featC__): move user-facing strings to the l10n ARB files.
      appBar: AppBar(title: const Text('__Feat__')),
      body: BlocBuilder<__Feat__Bloc, __Feat__State>(
        builder: (context, state) => switch (state) {
          __Feat__Initial() ||
          __Feat__Loading() => AppLoader(semanticsLabel: context.l10n.loading),
          __Feat__Failure(:final failure) => ErrorView(
            message: failure.message,
            onRetry: () => context.read<__Feat__Bloc>().add(
              const __Feat__Event.started(),
            ),
          ),
          __Feat__Loaded(:final items) when items.isEmpty => const EmptyView(
            message: 'Nothing here yet',
          ),
          __Feat__Loaded(:final items) => RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => __Ent__Tile(item: items[i]),
            ),
          ),
        },
      ),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<__Feat__Bloc>()
      ..add(const __Feat__Event.refreshed());
    await bloc.stream.first;
  }
}
EOF

emit "$DIR/${FEAT}_injection.dart" <<'EOF'
import 'package:__PKG__/features/__feat__/data/datasources/__feat___remote_data_source.dart';
import 'package:__PKG__/features/__feat__/data/repositories/__feat___repository_impl.dart';
import 'package:__PKG__/features/__feat__/domain/repositories/__feat___repository.dart';
import 'package:__PKG__/features/__feat__/domain/usecases/get___ent___list_use_case.dart';
import 'package:__PKG__/features/__feat__/presentation/bloc/__feat___bloc.dart';
import 'package:get_it/get_it.dart';

/// Registers everything the __feat__ feature needs.
/// Called from `initDependencies()`.
void register__Feat__Dependencies(GetIt sl) {
  sl
    // Data sources
    ..registerLazySingleton<__Feat__RemoteDataSource>(
      () => __Feat__RemoteDataSourceImpl(sl()),
    )
    // Repositories (always registered against the abstract type)
    ..registerLazySingleton<__Feat__Repository>(
      () => __Feat__RepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
    )
    // Use cases
    ..registerLazySingleton<Get__Ent__ListUseCase>(
      () => Get__Ent__ListUseCase(sl()),
    )
    // Blocs — ALWAYS factory
    ..registerFactory<__Feat__Bloc>(() => __Feat__Bloc(get__Ent__List: sl()));
}
EOF

# ---------------------------------------------------------------- tests
emit "test/features/$FEAT/presentation/bloc/${FEAT}_bloc_test.dart" <<'EOF'
import 'package:__PKG__/core/error/failure.dart';
import 'package:__PKG__/core/usecase/usecase.dart';
import 'package:__PKG__/features/__feat__/domain/entities/__ent__.dart';
import 'package:__PKG__/features/__feat__/domain/usecases/get___ent___list_use_case.dart';
import 'package:__PKG__/features/__feat__/presentation/bloc/__feat___bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' show Either, Left, Right;
import 'package:mocktail/mocktail.dart';

class _MockGet__Ent__ListUseCase extends Mock
    implements Get__Ent__ListUseCase;

void main() {
  late _MockGet__Ent__ListUseCase get__Ent__List;

  const failure = Failure.network();
  const items = [__Ent__(id: 1, name: 'First')];

  setUpAll(() => registerFallbackValue(const NoParams()));

  setUp(() => get__Ent__List = _MockGet__Ent__ListUseCase());

  __Feat__Bloc build() => __Feat__Bloc(get__Ent__List: get__Ent__List);

  void stub(Either<Failure, List<__Ent__>> result) =>
      when(() => get__Ent__List(any())).thenAnswer((_) async => result);

  test('initial state is __Feat__State.initial', () {
    expect(build().state, const __Feat__State.initial());
  });

  group('__Feat__Started', () {
    blocTest<__Feat__Bloc, __Feat__State>(
      'emits [loading, loaded] on success',
      setUp: () => stub(const Right(items)),
      build: build,
      act: (bloc) => bloc.add(const __Feat__Event.started()),
      expect: () => const [
        __Feat__State.loading(),
        __Feat__State.loaded(items),
      ],
    );

    blocTest<__Feat__Bloc, __Feat__State>(
      'emits [loading, failure] on failure',
      setUp: () => stub(const Left(failure)),
      build: build,
      act: (bloc) => bloc.add(const __Feat__Event.started()),
      expect: () => const [
        __Feat__State.loading(),
        __Feat__State.failure(failure),
      ],
    );
  });

  group('__Feat__Refreshed', () {
    blocTest<__Feat__Bloc, __Feat__State>(
      'emits [loaded] without a loading state',
      setUp: () => stub(const Right(items)),
      build: build,
      seed: () => const __Feat__State.loaded([]),
      act: (bloc) => bloc.add(const __Feat__Event.refreshed()),
      expect: () => const [__Feat__State.loaded(items)],
    );
  });
}
EOF

# ---------------------------------------------------------------- wiring
WIRED=()
if [[ $WIRE -eq 1 ]]; then
  DI=lib/app/di/injection_container.dart
  ROUTER=lib/app/router/app_router.dart
  NAMES=lib/app/router/route_names.dart

  # DI: import + call before `await sl.allReady();`
  perl -0pi -e '
    s/^(import )/import '\''package:$ENV{PKG}\/features\/$ENV{FEAT}\/$ENV{FEAT}_injection.dart'\'';\n$1/m;
    s/(\n  await sl\.allReady\(\);)/  register$ENV{FEAT_P}Dependencies(sl);\n$1/ or die "anchor not found in DI\n";
  ' "$DI"

  # Route names + paths: append to each class.
  perl -0pi -e '
    s/(abstract final class RouteNames \{.*?)\n\}/$1\n  static const String $ENV{FEAT_C} = '\''$ENV{FEAT_C}'\'';\n}/s or die "RouteNames not found\n";
    s/(abstract final class RoutePaths \{.*?)\n\}/$1\n  static const String $ENV{FEAT_C} = '\''\/$ENV{FEAT_URL}'\'';\n}/s or die "RoutePaths not found\n";
  ' "$NAMES"

  # Router: imports + GoRoute appended to the top-level routes list.
  perl -0pi -e '
    my $p = "package:$ENV{PKG}/features/$ENV{FEAT}/presentation";
    s/^(import )/import '\''$p\/bloc\/$ENV{FEAT}_bloc.dart'\'';\nimport '\''$p\/pages\/$ENV{FEAT}_page.dart'\'';\n$1/m;
    my $route = <<"R";
      GoRoute(
        name: RouteNames.$ENV{FEAT_C},
        path: RoutePaths.$ENV{FEAT_C},
        builder: (context, state) => BlocProvider<$ENV{FEAT_P}Bloc>(
          create: (_) =>
              sl<$ENV{FEAT_P}Bloc>()..add(const $ENV{FEAT_P}Event.started()),
          child: const $ENV{FEAT_P}Page(),
        ),
      ),
R
    s/(\n    \],\n  \);\n\}\s*)$/\n$route    ],\n  );\n}\n/ or die "routes list end not found in router\n";
  ' "$ROUTER"
  WIRED=("$DI" "$NAMES" "$ROUTER")
fi

# ---------------------------------------------------------------- codegen + tidy
if command -v fvm >/dev/null 2>&1; then DART="fvm dart"; else DART="dart"; fi
echo "==> Running build_runner"
$DART run build_runner build --delete-conflicting-outputs >/dev/null
# Keep the leading import block sorted (directives_ordering): dart: first, then package:.
for f in "${WIRED[@]}"; do
  perl -0pi -e '
    s{\A((?:import [^\n]*;\n)+)}{
      my @l = split /(?<=\n)/, $1;
      join "", (sort grep { /^import .dart:/ } @l), (sort grep { !/^import .dart:/ } @l)
    }e;
  ' "$f"
done
$DART format "${CREATED[@]}" "${WIRED[@]}" >/dev/null

echo
echo "Created feature '$FEAT':"
printf '  %s\n' "${CREATED[@]}"
if [[ ${#WIRED[@]} -gt 0 ]]; then
  echo "Wired into:"
  printf '  %s\n' "${WIRED[@]}"
  echo "Open it with: context.pushNamed(RouteNames.$FEAT_C)   (path /$FEAT_URL)"
fi
echo
echo "Next: replace the placeholder fields (TODO($FEAT_C)), set the API path, then 'make check'."
