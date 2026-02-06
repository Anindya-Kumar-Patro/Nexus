// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$myVenturesHash() => r'02508b17f8cc81acb7f92d96824e816bfca40fa4';

/// See also [myVentures].
@ProviderFor(myVentures)
final myVenturesProvider = AutoDisposeFutureProvider<List<Venture>>.internal(
  myVentures,
  name: r'myVenturesProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$myVenturesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MyVenturesRef = AutoDisposeFutureProviderRef<List<Venture>>;
String _$feedControllerHash() => r'a94056f64c1f5279d6e680d942883d4b3b2bad83';

/// See also [FeedController].
@ProviderFor(FeedController)
final feedControllerProvider =
    AutoDisposeAsyncNotifierProvider<FeedController, List<Venture>>.internal(
  FeedController.new,
  name: r'feedControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$feedControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$FeedController = AutoDisposeAsyncNotifier<List<Venture>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
