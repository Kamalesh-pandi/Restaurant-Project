package com.example.backend.order.entity;

public enum OrderStatus {
    DRAFT,
    NEW,
    PREPARING,
    READY,
    ASSIGNED,
    OUT_FOR_DELIVERY,
    DELIVERED,
    SERVED,
    BILLED,
    PAID,
    CANCELLED
}
