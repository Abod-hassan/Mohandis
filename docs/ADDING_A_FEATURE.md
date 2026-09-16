# Adding a feature

Every feature ships as **seven artefacts**. Never just the UI. See ARCHITECTURE.md §14 for the shorter version; this document walks through a concrete example.

## Worked example — a `Product` list feature

We'll build a screen that lists products from `GET /api/products` and lets the user tap into a detail view at `GET /api/products/{id}`.

### 1. Domain entity

`lib/features/products/domain/entities/product.dart`

```dart
import 'package:flutter_mobile_template/core/base/base_entity.dart';

/// Pure domain — no Flutter, no JSON, no Dio.
class Product extends BaseEntity {
  const Product({
    required this.id,
    required this.name,
    required this.priceCents,
  });

  @override
  final String id;

  final String name;
  final int priceCents;
}
```

### 2. Repository interface

`lib/features/products/domain/repositories/product_repository.dart`

```dart
import 'package:flutter_mobile_template/core/base/base_repository.dart';

import '../entities/product.dart';

/// Extends BaseRepository<Product> to get standard CRUD for free.
/// Add feature-specific methods here if the standard CRUD doesn't fit.
abstract class ProductRepository extends BaseRepository<Product> {}
```

### 3. DTO

`lib/features/products/data/dtos/product_dto.dart`

```dart
import 'package:flutter_mobile_template/core/base/base_dto.dart';

import '../../domain/entities/product.dart';

class ProductDto implements BaseDto<Product> {
  const ProductDto({
    required this.id,
    required this.name,
    required this.priceCents,
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) => ProductDto(
        id: json['id'] as String,
        name: json['name'] as String,
        priceCents: (json['priceCents'] as num).toInt(),
      );

  final String id;
  final String name;
  final int priceCents;

  @override
  Product toDomain() =>
      Product(id: id, name: name, priceCents: priceCents);

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'priceCents': priceCents,
      };
}
```

### 4. Repository impl + provider

`lib/features/products/data/repositories/product_repository_impl.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/api/endpoints.dart';
import 'package:flutter_mobile_template/core/base/base_repository.dart';
import 'package:flutter_mobile_template/core/base/rest_repository.dart';
import 'package:flutter_mobile_template/core/providers.dart';

import '../../domain/entities/product.dart';
import '../dtos/product_dto.dart';

final productRepositoryProvider = Provider<BaseRepository<Product>>((ref) {
  return RestRepository<Product, ProductDto>(
    apiClient: ref.watch(apiClientProvider),
    basePath: EndPoints.products,
    fromJson: ProductDto.fromJson,
  );
});
```

### 5. Notifier

`lib/features/products/presentation/notifiers/products_notifier.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/base/base_list_notifier.dart';
import 'package:flutter_mobile_template/core/base/base_repository.dart';

import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';

class ProductsNotifier extends BaseListNotifier<Product> {
  @override
  BaseRepository<Product> get repository =>
      ref.read(productRepositoryProvider);
}

final productsNotifierProvider =
    AsyncNotifierProvider<ProductsNotifier, List<Product>>(
  ProductsNotifier.new,
);
```

### 6. Screen

`lib/features/products/presentation/screens/products_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_mobile_template/core/widgets/error_view.dart';
import 'package:flutter_mobile_template/core/widgets/loading_view.dart';

import '../notifiers/products_notifier.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(productsNotifierProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: state.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () =>
              ref.read(productsNotifierProvider.notifier).refresh(),
        ),
        data: (items) => ListView.builder(
          itemCount: items.length,
          itemBuilder: (_, i) => ListTile(
            title: Text(items[i].name),
            subtitle: Text('${items[i].priceCents / 100}'),
          ),
        ),
      ),
    );
  }
}
```

### 7. Endpoint constant

`lib/core/api/endpoints.dart` — add the constant with a full doc-comment (verb / request / response / failure):

```dart
/// `GET /api/products` — paginated product list.
///
/// **Request:** query params `page` (default 1), `pageSize` (default 20).
/// **Response:** `List<ProductDto>` — flat array; no envelope.
/// **Failure:** `401` if the access token is expired (interceptor handles);
/// `500` otherwise.
static const String products = '/api/products';
```

### 8. Register the route (if navigable)

If the screen is reachable from anywhere except the home screen, add it to [`lib/core/router/app_router.dart`](../lib/core/router/app_router.dart):

```dart
GoRoute(
  path: '/products',
  builder: (_, __) => const ProductsScreen(),
),
```

### 9. Tests

Minimum coverage per ARCHITECTURE.md §15:

- **Repository test** (`test/features/products/product_repository_test.dart`) — success + `401` + `5xx` + timeout, using `dio_test_adapter` or `mocktail`.
- **Notifier test** (`test/features/products/products_notifier_test.dart`) — initial load + refresh + one failure branch.
- **Screen widget test** — loading state + error state + data state.

## Done

Ship.
