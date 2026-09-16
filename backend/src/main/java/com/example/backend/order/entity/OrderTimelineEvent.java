package com.example.backend.order.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.util.UUID;
import lombok.*;

@Entity
@Table(name = "order_timeline_events")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderTimelineEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "order_id", nullable = false)
    private UUID orderId;

    @Column(name = "event_type", nullable = false)
    private String eventType; // e.g. CREATED, KOT_FIRED, STATUS_CHANGED, ITEM_MODIFIED, DISCOUNT_APPLIED, COMPLIMENTARY, SPLIT, BILLED, PAID

    @Column(columnDefinition = "text")
    private String description;

    @Column(name = "actor_name")
    private String actorName;

    @Column(name = "timestamp", nullable = false)
    private LocalDateTime timestamp;
}
