import 'package:freezed_annotation/freezed_annotation.dart';

part 'paginated.freezed.dart';
part 'paginated.g.dart';

@Freezed(genericArgumentFactories: true)
class Paginated<T> with _$Paginated<T> {
  const factory Paginated({
    required List<T> items,
    required int total,
    required int limit,
    required int offset,
    @JsonKey(name: 'has_more') required bool hasMore,
  }) = _Paginated<T>;

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$PaginatedFromJson(json, fromJsonT);
}
