import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/config/theme.dart';
import 'package:delivery_partner_app/models/delivery_partner.dart';
import 'package:delivery_partner_app/models/delivery_assignment.dart';

void main() {
  test('DeliveryPartner model serialization test', () {
    final json = {
      'partnerId': '550e8400-e29b-41d4-a716-446655440000',
      'name': 'Alex Rider',
      'phone': '+919876543210',
      'vehicleNumber': 'KA-01-AB-1234',
      'vehicleType': 'BIKE',
      'status': 'OFFLINE',
      'rating': 4.9,
      'totalDeliveries': 120,
    };

    final partner = DeliveryPartner.fromJson(json);
    expect(partner.name, 'Alex Rider');
    expect(partner.phone, '+919876543210');
    expect(partner.rating, 4.9);
    expect(partner.totalDeliveries, 120);
    expect(partner.isOffline, true);
    expect(partner.isOnline, false);
  });

  test('DeliveryAssignment model serialization test', () {
    final json = {
      'assignmentId': '11111111-1111-1111-1111-111111111111',
      'orderId': '22222222-2222-2222-2222-222222222222',
      'partnerId': '550e8400-e29b-41d4-a716-446655440000',
      'status': 'ASSIGNED',
      'deliveryAddress': '123 Green Avenue, Block B, Flat 402',
      'customerPhone': '+919876543210',
      'deliveryFee': 40.0,
      'tipAmount': 20.0,
      'otpCode': '4829',
      'deliveryNotes': 'Leave at front desk with security guard',
    };

    final assignment = DeliveryAssignment.fromJson(json);
    expect(assignment.status, 'ASSIGNED');
    expect(assignment.deliveryFee, 40.0);
    expect(assignment.tipAmount, 20.0);
    expect(assignment.totalEarning, 60.0);
    expect(assignment.otpCode, '4829');
    expect(assignment.isAssigned, true);
    expect(assignment.isActive, true);
  });

  test('AppTheme luxury culinary gold and espresso palette verification', () {
    // 1. Primary Brand & Gold Colors
    expect(AppTheme.primaryGold.value, 0xFFC59B27);
    expect(AppTheme.goldAccent.value, 0xFFD4AF37);
    expect(AppTheme.goldLight.value, 0xFFFFDF7D);
    expect(AppTheme.primaryDark.value, 0xFF8C581E);
    expect(AppTheme.primaryLight.value, 0xFFFFF7E6);

    // 2. Deep Espresso & Dark Accents
    expect(AppTheme.espressoDeep.value, 0xFF261208);
    expect(AppTheme.espressoMid.value, 0xFF3F1D0D);
    expect(AppTheme.espressoDark.value, 0xFF1C0C05);
    expect(AppTheme.darkSurface.value, 0xFF2A150A);

    // 3. Backgrounds & Neutrals
    expect(AppTheme.appBackground.value, 0xFFF4F6F9);
    expect(AppTheme.linenNeutral.value, 0xFFFBF8F3);
    expect(AppTheme.cardSurface.value, 0xFFFFFFFF);
    expect(AppTheme.stepperNeutral.value, 0xFFF1F5F9);
    expect(AppTheme.borderNeutral.value, 0xFFE5DDD0);

    // 4. Typography Colors
    expect(AppTheme.titleHeading.value, 0xFF2A1508);
    expect(AppTheme.bodySecondary.value, 0xFF6E5F55);
    expect(AppTheme.hintPlaceholder.value, 0xFF9E9E9E);
    expect(AppTheme.lightOnDarkTitle.value, 0xFFFFF7ED);
    expect(AppTheme.lightOnDarkSub.value, 0xFFFFD199);

    // 5. Status & Badges
    expect(AppTheme.vegMark.value, 0xFF2E7D32);
    expect(AppTheme.nonVegMark.value, 0xFFC62828);
    expect(AppTheme.statusSuccess.value, 0xFF2ECC71);
    expect(AppTheme.statusWarning.value, 0xFFF39C12);
    expect(AppTheme.ratingStar.value, 0xFFFFC107);
    expect(AppTheme.statusError.value, 0xFFD32F2F);

    // 6. Signature Gradients
    expect(AppTheme.luxuryHeaderGradient.colors.length, 3);
    expect(AppTheme.imperialActionGradient.colors.length, 2);
    expect(AppTheme.goldRingGradient.colors.length, 3);
  });
}
