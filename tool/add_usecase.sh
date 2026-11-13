#!/usr/bin/env bash
# Add a use case to an existing feature, through every layer.
#
# Usage:
#   tool/add_usecase.sh <feature> <use_case_name> [--returns <DartType>] [--no-params]
#   make usecase FEATURE=orders NAME=create_order [RETURNS=Order] [NO_PARAMS=1]
#
#   <feature>        Existing folder under lib/features/, e.g. orders
#   <use_case_name>  lower_snake_case verb phrase, e.g. create_order -> CreateOrderUseCase
#   --returns        Success type, e.g. Order or List<Order> (default: Unit, i.e. no value)
#   --no-params      Use NoParams instead of generating a <Name>Params class
#
# Touches: domain/usecases (new), domain/repositories, data/repositories, data/datasources (remote),
# <feature>_injection.dart, and creates a use case test. Nothing is written if a file isn't in the
# expected shape.
set -euo pipefail

die() { echo "error: $*" >&2; exit 1; }
usage() { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit "${1:-0}"; }

FEAT="" NAME="" RETURNS="" PARAMS=1
while [[ $# -gt 0 ]]; do
  case "$1" in
    --returns) RETURNS="${2:-}"; shift 2 ;;
    --no-params) PARAMS=0; shift ;;
    -h|--help) usage 0 ;;
    -*) echo "unknown option: $1" >&2; usage 1 ;;
    *) if [[ -z "$FEAT" ]]; then FEAT="$1"; elif [[ -z "$NAME" ]]; then NAME="$1"; else usage 1; fi; shift ;;
  esac
done
[[ -n "$FEAT" && -n "$NAME" ]] || usage 1
NAME="${NAME%_use_case}"
for n in "$FEAT" "$NAME"; do
  [[ "$n" =~ ^[a-z][a-z0-9]*(_[a-z0-9]+)*$ ]] || die "'$n' must be lower_snake_case, e.g. create_order"
done
TYPE_RE='^[A-Za-z_][A-Za-z0-9_<>, ?]*$'
[[ -z "$RETURNS" || "$RETURNS" =~ $TYPE_RE ]] || die "--returns must be a Dart type, e.g. List<Order>"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
PKG="$(sed -n 's/^name: *//p' pubspec.yaml | head -1)"
DIR="lib/features/$FEAT"
[[ -d "$DIR" ]] || die "$DIR does not exist (create it with 'make feature NAME=$FEAT')"

pascal() { perl -pe 's/(^|_)([a-z0-9])/\U$2/g' <<<"$1"; }
camel() { perl -pe 's/_([a-z0-9])/\U$1/g' <<<"$1"; }
FEAT_P="$(pascal "$FEAT")"
UC_P="$(pascal "$NAME")"
UC_C="$(camel "$NAME")"
UC_CLASS="${UC_P}UseCase"
RET="${RETURNS:-Unit}"
if [[ $PARAMS -eq 1 ]]; then PTYPE="${UC_P}Params"; else PTYPE="NoParams"; fi

UC_FILE="$DIR/domain/usecases/${NAME}_use_case.dart"
REPO="$DIR/domain/repositories/${FEAT}_repository.dart"
REPO_IMPL="$DIR/data/repositories/${FEAT}_repository_impl.dart"
DS="$DIR/data/datasources/${FEAT}_remote_data_source.dart"
DI="$DIR/${FEAT}_injection.dart"
TEST="test/features/$FEAT/domain/usecases/${NAME}_use_case_test.dart"
P="package:$PKG/features/$FEAT"

# ---------------------------------------------------------------- preflight
PROBLEMS=()
[[ -e "$UC_FILE" ]] && PROBLEMS+=("$UC_FILE already exists")
[[ -e "$TEST" ]] && PROBLEMS+=("$TEST already exists")
check() { # check <file> <perl-regex> <description>
  if [[ ! -f "$1" ]]; then PROBLEMS+=("missing $1"); return; fi
  perl -0ne "exit(/$2/s ? 0 : 1)" "$1" || PROBLEMS+=("$1: $3")
}
check "$REPO" "abstract interface class ${FEAT_P}Repository \\{.*\\n\\}\\s*\\z" "expected ${FEAT_P}Repository as the last class"
check "$REPO_IMPL" "class ${FEAT_P}RepositoryImpl implements ${FEAT_P}Repository \\{.*\\n\\}\\s*\\z" "expected ${FEAT_P}RepositoryImpl as the last class"
check "$REPO_IMPL" "final ${FEAT_P}RemoteDataSource _remote;" "expected a '_remote' ${FEAT_P}RemoteDataSource field"
check "$REPO_IMPL" "import 'package:fpdart\\/fpdart.dart'" "expected an fpdart import"
check "$DS" "abstract interface class ${FEAT_P}RemoteDataSource \\{.*?\\n\\}" "expected the ${FEAT_P}RemoteDataSource interface"
check "$DS" "class ${FEAT_P}RemoteDataSourceImpl implements ${FEAT_P}RemoteDataSource \\{.*\\n\\}\\s*\\z" "expected ${FEAT_P}RemoteDataSourceImpl as the last class"
check "$DI" "\\n    \\/\\/ Blocs" "expected a '// Blocs' section"
if [[ ${#PROBLEMS[@]} -gt 0 ]]; then
  echo "error: can't add the use case, nothing was changed:" >&2
  printf '  - %s\n' "${PROBLEMS[@]}" >&2
  exit 1
fi

# Imports for entity types named in --returns (e.g. List<Order> -> domain/entities/order.dart).
ENTITY_IMPORTS=""
for t in $(grep -oE '[A-Z][A-Za-z0-9_]*' <<<"$RET" | sort -u); do
  snake="$(perl -pe 's/(?<!^)([A-Z])/_\l$1/g; $_ = lc' <<<"$t")"
  for d in domain/entities data/models; do
    [[ -f "$DIR/$d/$snake.dart" ]] && ENTITY_IMPORTS+="import '$P/$d/$snake.dart';"$'\n'
  done
done
FPDART_IMPORT=""
[[ "$RET" == *Unit* ]] && FPDART_IMPORT="import 'package:fpdart/fpdart.dart' show Unit;"$'\n'

if [[ $PARAMS -eq 1 ]]; then ARG="$PTYPE params"; CALL_ARG="params"; else ARG=""; CALL_ARG=""; fi

# Add `import` lines and keep the leading import block sorted (dart: first, then package:).
add_imports() { # add_imports <file> <lines>
  IMPORTS="$2" perl -0pi -e '
    my %seen; my @new = grep { length && !$seen{$_}++ } split /\n/, $ENV{IMPORTS};
    s{\A((?:import [^\n]*;\n)+)}{
      my @l = map { s/\n\z//r } split /(?<=\n)/, $1;
      my %have = map { $_ => 1 } @l;
      push @l, grep { !$have{$_} } @new;
      join "", map { "$_\n" } (sort grep { /^import .dart:/ } @l), (sort grep { !/^import .dart:/ } @l)
    }e;
  ' "$1"
}
# Insert text before the closing brace of the LAST class in a file.
append_to_last_class() { # <file> <text>
  BODY="$2" perl -0pi -e 's/\n\}\s*\z/\n\n$ENV{BODY}}\n/' "$1"
}
# Make sure an fpdart `show` list (if any) contains the given names.
fpdart_show() { # <file> <names...>
  local f="$1"; shift
  NAMES="$*" perl -0pi -e '
    s{(import .package:fpdart/fpdart\.dart.) show ([^;]+);}{
      my %n = map { $_ => 1 } (split(/,\s*/, $2), split(/ /, $ENV{NAMES}));
      "$1 show " . join(", ", sort keys %n) . ";"
    }e;
  ' "$f"
}

TOUCHED=()

# ---------------------------------------------------------------- use case
mkdir -p "$(dirname "$UC_FILE")"
{
  echo "import 'package:$PKG/core/usecase/usecase.dart';"
  echo "import 'package:$PKG/core/utils/typedefs.dart';"
  echo "import '$P/domain/repositories/${FEAT}_repository.dart';"
  [[ $PARAMS -eq 1 ]] && echo "import 'package:equatable/equatable.dart';"
  printf '%s%s' "$ENTITY_IMPORTS" "$FPDART_IMPORT"
} | sort -u >"$UC_FILE"
cat >>"$UC_FILE" <<EOF

class $UC_CLASS implements UseCase<$RET, $PTYPE> {
  const new(this._repository);

  final ${FEAT_P}Repository _repository;

  @override
  FutureEither<$RET> call($PTYPE params) =>
      _repository.$UC_C($CALL_ARG);
}
EOF
if [[ $PARAMS -eq 1 ]]; then
  cat >>"$UC_FILE" <<EOF

// TODO($(camel "$FEAT")): add the inputs this use case needs.
final class $PTYPE extends Equatable {
  const new();

  @override
  List<Object?> get props => const [];
}
EOF
fi
TOUCHED+=("$UC_FILE")

# ---------------------------------------------------------------- repository contract
append_to_last_class "$REPO" "  FutureEither<$RET> $UC_C($ARG);
"
add_imports "$REPO" "$ENTITY_IMPORTS$FPDART_IMPORT$( [[ $PARAMS -eq 1 ]] && echo "import '$P/domain/usecases/${NAME}_use_case.dart';" )
import 'package:$PKG/core/utils/typedefs.dart';"
TOUCHED+=("$REPO")

# ---------------------------------------------------------------- data source
DS_RET="$RET"; [[ "$RET" == "Unit" ]] && DS_RET="void"
DS_SIG="Future<$DS_RET> $UC_C($ARG)"
BODY="$DS_SIG" perl -0pi -e '
  s/(abstract interface class \w+RemoteDataSource \{.*?)\n\}/$1\n\n  $ENV{BODY};\n}/s
' "$DS"
append_to_last_class "$DS" "  @override
  $DS_SIG {
    // TODO($(camel "$FEAT")): call the API, e.g. _dio.post<JsonMap>('/path', data: ...).
    throw UnimplementedError('$UC_C');
  }
"
add_imports "$DS" "$ENTITY_IMPORTS$( [[ $PARAMS -eq 1 ]] && echo "import '$P/domain/usecases/${NAME}_use_case.dart';" )"
TOUCHED+=("$DS")

# ---------------------------------------------------------------- repository impl
if [[ "$RET" == "Unit" ]]; then
  IMPL_TRY="      await _remote.$UC_C($CALL_ARG);
      return const Right(unit);"
  fpdart_show "$REPO_IMPL" Left Right Unit unit
else
  IMPL_TRY="      return Right(await _remote.$UC_C($CALL_ARG));"
  fpdart_show "$REPO_IMPL" Left Right
fi
append_to_last_class "$REPO_IMPL" "  @override
  FutureEither<$RET> $UC_C($ARG) async {
    try {
$IMPL_TRY
    } on Object catch (e) {
      return Left(ErrorMapper.toFailure(e));
    }
  }
"
add_imports "$REPO_IMPL" "$ENTITY_IMPORTS$( [[ $PARAMS -eq 1 ]] && echo "import '$P/domain/usecases/${NAME}_use_case.dart';" )
import 'package:$PKG/core/error/error_mapper.dart';
import 'package:$PKG/core/utils/typedefs.dart';"
TOUCHED+=("$REPO_IMPL")

# ---------------------------------------------------------------- DI
LINE="    ..registerLazySingleton<$UC_CLASS>(() => $UC_CLASS(sl()))" perl -0pi -e '
  s/(\n    \/\/ Blocs)/\n$ENV{LINE}$1/
' "$DI"
add_imports "$DI" "import '$P/domain/usecases/${NAME}_use_case.dart';"
TOUCHED+=("$DI")

# ---------------------------------------------------------------- test
mkdir -p "$(dirname "$TEST")"
{
  echo "import 'package:$PKG/core/error/failure.dart';"
  [[ $PARAMS -eq 0 ]] && echo "import 'package:$PKG/core/usecase/usecase.dart';"
  echo "import '$P/domain/repositories/${FEAT}_repository.dart';"
  echo "import '$P/domain/usecases/${NAME}_use_case.dart';"
  echo "import 'package:flutter_test/flutter_test.dart';"
  if [[ "$RET" == "Unit" ]]; then echo "import 'package:fpdart/fpdart.dart' show Left, Right, Unit, unit;"
  else echo "import 'package:fpdart/fpdart.dart' show Left;"; fi
  echo "import 'package:mocktail/mocktail.dart';"
  printf '%s' "$ENTITY_IMPORTS"
} | sort -u >"$TEST"
cat >>"$TEST" <<EOF

class _Mock${FEAT_P}Repository extends Mock implements ${FEAT_P}Repository;

void main() {
  late _Mock${FEAT_P}Repository repository;
  late $UC_CLASS useCase;

  const params = $PTYPE();

  setUp(() {
    repository = _Mock${FEAT_P}Repository();
    useCase = $UC_CLASS(repository);
  });

  test('returns the failure from the repository', () async {
    const failure = Failure.network();
    when(
      () => repository.$UC_C($CALL_ARG),
    ).thenAnswer((_) async => const Left(failure));

    expect(await useCase(params), const Left<Failure, $RET>(failure));
    verify(() => repository.$UC_C($CALL_ARG)).called(1);
  });
EOF
if [[ "$RET" == "Unit" ]]; then
  cat >>"$TEST" <<EOF

  test('returns unit on success', () async {
    when(
      () => repository.$UC_C($CALL_ARG),
    ).thenAnswer((_) async => const Right(unit));

    expect(await useCase(params), const Right<Failure, Unit>(unit));
  });
EOF
fi
echo "}" >>"$TEST"
TOUCHED+=("$TEST")

# ---------------------------------------------------------------- tidy
# Re-sort the import blocks of the two new files too.
add_imports "$UC_FILE" ""
add_imports "$TEST" ""
if command -v fvm >/dev/null 2>&1; then DART="fvm dart"; else DART="dart"; fi
$DART format "${TOUCHED[@]}" >/dev/null

echo "Added $UC_CLASS to '$FEAT':"
printf '  %s\n' "${TOUCHED[@]}"
echo
echo "Next: fill in the TODOs (params and the API call in ${FEAT_P}RemoteDataSourceImpl.$UC_C), then 'make check'."
