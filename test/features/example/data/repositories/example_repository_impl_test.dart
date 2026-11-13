import 'package:app_core/core/error/exceptions.dart';
import 'package:app_core/core/error/failure.dart';
import 'package:app_core/features/example/data/repositories/example_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockExampleRemoteDataSource remote;
  late MockExampleLocalDataSource local;
  late MockNetworkInfo networkInfo;
  late ExampleRepositoryImpl repository;

  setUp(() {
    remote = MockExampleRemoteDataSource();
    local = MockExampleLocalDataSource();
    networkInfo = MockNetworkInfo();
    repository = ExampleRepositoryImpl(
      remoteDataSource: remote,
      localDataSource: local,
      networkInfo: networkInfo,
    );
    when(() => local.cacheItems(any())).thenAnswer((_) async {});
  });

  DioException dioError(DioExceptionType type, {int? status}) {
    final options = RequestOptions(path: '/posts');
    return DioException(
      requestOptions: options,
      type: type,
      response: status == null
          ? null
          : Response<void>(requestOptions: options, statusCode: status),
    );
  }

  group('online', () {
    setUp(() {
      when(() => networkInfo.isConnected).thenAnswer((_) async => true);
    });

    test('returns entities and caches the models', () async {
      when(remote.fetchItems).thenAnswer((_) async => [exampleItemModel]);

      final result = await repository.getItems();

      expect(result.getRight().toNullable(), [exampleItem]);
      verify(() => local.cacheItems([exampleItemModel])).called(1);
    });

    test('maps a connection error to NetworkFailure', () async {
      when(remote.fetchItems)
          .thenThrow(dioError(DioExceptionType.connectionError));

      final result = await repository.getItems();

      expect(result.getLeft().toNullable(), isA<NetworkFailure>());
      verifyNever(() => local.cacheItems(any()));
    });

    test('maps a 500 response to ServerFailure', () async {
      when(remote.fetchItems)
          .thenThrow(dioError(DioExceptionType.badResponse, status: 500));

      final result = await repository.getItems();

      expect(
        result.getLeft().toNullable(),
        isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 500),
      );
    });

    test('maps a parsing error to ParsingFailure', () async {
      when(remote.fetchItems).thenThrow(const ParsingException());

      final result = await repository.getItems();

      expect(result.getLeft().toNullable(), isA<ParsingFailure>());
    });

    test('maps an unknown error to UnexpectedFailure', () async {
      when(remote.fetchItems).thenThrow(Exception('boom'));

      final result = await repository.getItems();

      expect(result.getLeft().toNullable(), isA<UnexpectedFailure>());
    });
  });

  group('offline', () {
    setUp(() {
      when(() => networkInfo.isConnected).thenAnswer((_) async => false);
    });

    test('returns cached entities without calling the API', () async {
      when(local.getCachedItems).thenAnswer((_) async => [exampleItemModel]);

      final result = await repository.getItems();

      expect(result.getRight().toNullable(), [exampleItem]);
      verifyNever(remote.fetchItems);
    });

    test('returns NetworkFailure when nothing is cached', () async {
      when(local.getCachedItems).thenThrow(const CacheException());

      final result = await repository.getItems();

      expect(result, const Left<Failure, Never>(Failure.network()));
    });
  });
}
