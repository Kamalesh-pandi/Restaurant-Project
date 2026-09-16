package com.example.backend.delivery.repository;

import com.example.backend.delivery.entity.AssignmentStatus;
import com.example.backend.delivery.entity.DeliveryAssignment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface DeliveryAssignmentRepository extends JpaRepository<DeliveryAssignment, UUID> {
    List<DeliveryAssignment> findByPartnerId(UUID partnerId);
    List<DeliveryAssignment> findByPartnerIdAndStatusIn(UUID partnerId, List<AssignmentStatus> statuses);
    Optional<DeliveryAssignment> findByOrderId(UUID orderId);
    Optional<DeliveryAssignment> findByOrderIdAndStatusIn(UUID orderId, List<AssignmentStatus> statuses);
}
