package com.example.backend.order.repository;

import com.example.backend.order.entity.OrderTimelineEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface OrderTimelineRepository extends JpaRepository<OrderTimelineEvent, UUID> {
    List<OrderTimelineEvent> findByOrderIdOrderByTimestampAsc(UUID orderId);
}
