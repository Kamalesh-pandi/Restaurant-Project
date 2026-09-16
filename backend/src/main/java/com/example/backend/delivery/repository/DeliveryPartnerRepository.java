package com.example.backend.delivery.repository;

import com.example.backend.delivery.entity.DeliveryPartner;
import com.example.backend.delivery.entity.DeliveryPartnerStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DeliveryPartnerRepository extends JpaRepository<DeliveryPartner, UUID> {
    Optional<DeliveryPartner> findByPhone(String phone);
    Optional<DeliveryPartner> findByPhoneAndPinCode(String phone, String pinCode);
    List<DeliveryPartner> findByStatus(DeliveryPartnerStatus status);
    List<DeliveryPartner> findByStatusAndOutletId(DeliveryPartnerStatus status, UUID outletId);
}
