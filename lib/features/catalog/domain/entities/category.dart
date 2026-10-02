import 'package:equatable/equatable.dart';
import 'package:joyjoy/features/catalog/domain/entities/gender.dart';

class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.gender,
  });

  final String id;
  final String name;
  final String slug;
  final Gender gender;

  @override
  List<Object?> get props => [id, name, slug, gender];
}
