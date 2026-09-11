import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/config/revenuecat_config.dart';
import '../../domain/entities/purchase_option.dart';
import '../../domain/entities/subscription_entitlement.dart';

class RevenueCatService {
  RevenueCatService();

  bool _configured = false;
  String? _loggedInUserId;
  bool _customerInfoListenerAttached = false;
  final Map<String, Package> _packages = {};
  final StreamController<SubscriptionEntitlement> _entitlementController =
      StreamController<SubscriptionEntitlement>.broadcast();

  Stream<SubscriptionEntitlement> get entitlementChanges =>
      _entitlementController.stream;

  bool get isAvailable =>
      RevenueCatConfig.isConfigured && _configured;

  Future<void> configure() async {
    if (_configured || !RevenueCatConfig.isConfigured) return;

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    final configuration = PurchasesConfiguration(
      RevenueCatConfig.apiKey,
    );

    await Purchases.configure(configuration);
    _configured = true;
    _attachCustomerInfoListener();
  }

  Future<SubscriptionEntitlement?> identify(String userId) async {
    await configure();
    if (!_configured) return null;

    if (_loggedInUserId == userId) {
      return currentEntitlement();
    }

    final result = await Purchases.logIn(userId);
    _loggedInUserId = userId;

    final entitlement = _mapCustomerInfo(result.customerInfo);
    _emitEntitlement(entitlement);
    return entitlement;
  }

  Future<void> logOut() async {
    if (!_configured || _loggedInUserId == null) return;

    final info = await Purchases.logOut();
    _loggedInUserId = null;

    // RevenueCat switches back to an anonymous customer after logout.
    // The app-level provider still forces Free while auth is guest, but
    // publishing the returned anonymous state keeps the SDK stream coherent.
    _emitEntitlement(_mapCustomerInfo(info));
  }

  Future<List<PurchaseOption>> getPurchaseOptions() async {
    await configure();
    if (!_configured) return const [];

    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null) return const [];

    _packages.clear();

    return current.availablePackages.map((package) {
      final product = package.storeProduct;
      final key = package.identifier;
      _packages[key] = package;

      return PurchaseOption(
        id: product.identifier,
        title: product.title,
        description: product.description,
        priceText: product.priceString,
        packageIdentifier: key,
      );
    }).toList(growable: false);
  }

  Future<SubscriptionEntitlement> purchase(
    String packageIdentifier,
  ) async {
    await configure();

    final package = _packages[packageIdentifier];
    if (!_configured || package == null) {
      throw StateError('Purchase option is unavailable.');
    }

    try {
      final result = await Purchases.purchasePackage(package);
      final entitlement = _mapCustomerInfo(result.customerInfo);
      _emitEntitlement(entitlement);
      return entitlement;
    } on PlatformException catch (error) {
      final code = PurchasesErrorHelper.getErrorCode(error);

      if (code == PurchasesErrorCode.purchaseCancelledError) {
        throw const PurchaseCancelledException();
      }

      rethrow;
    }
  }

  Future<SubscriptionEntitlement> restore() async {
    await configure();

    if (!_configured) {
      return SubscriptionEntitlement.free;
    }

    final info = await Purchases.restorePurchases();
    final entitlement = _mapCustomerInfo(info);
    _emitEntitlement(entitlement);
    return entitlement;
  }

  Future<SubscriptionEntitlement?> currentEntitlement() async {
    await configure();
    if (!_configured) return null;

    final info = await Purchases.getCustomerInfo();
    final entitlement = _mapCustomerInfo(info);
    _emitEntitlement(entitlement);
    return entitlement;
  }

  void _attachCustomerInfoListener() {
    if (_customerInfoListenerAttached) return;

    Purchases.addCustomerInfoUpdateListener((info) {
      _emitEntitlement(_mapCustomerInfo(info));
    });

    _customerInfoListenerAttached = true;
  }

  void _emitEntitlement(SubscriptionEntitlement entitlement) {
    if (_entitlementController.isClosed) return;
    _entitlementController.add(entitlement);
  }

  SubscriptionEntitlement _mapCustomerInfo(CustomerInfo info) {
    final entitlement = info.entitlements.all[
      RevenueCatConfig.entitlementId
    ];

    if (entitlement == null || !entitlement.isActive) {
      return SubscriptionEntitlement.free;
    }

    return SubscriptionEntitlement(
      plan: SubscriptionPlan.premium,
      isActive: true,
      expiresAt: DateTime.tryParse(
        entitlement.expirationDate ?? '',
      ),
    );
  }
}

class PurchaseCancelledException implements Exception {
  const PurchaseCancelledException();

  @override
  String toString() => 'Purchase cancelled.';
}
