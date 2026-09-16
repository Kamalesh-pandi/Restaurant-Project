package com.example.backend.order.repository;

import com.example.backend.order.entity.Order;
import com.example.backend.order.entity.OrderStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface OrderRepository extends JpaRepository<Order, UUID> {
    List<Order> findByTableId(UUID tableId);
    List<Order> findByStatus(OrderStatus status);
    List<Order> findByStatusAndTableId(OrderStatus status, UUID tableId);
    List<Order> findByStatusAndTokenNumber(OrderStatus status, String tokenNumber);
    List<Order> findByCustomerPhone(String customerPhone);
}
