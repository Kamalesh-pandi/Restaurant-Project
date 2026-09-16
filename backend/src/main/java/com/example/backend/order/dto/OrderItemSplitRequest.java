package com.example.backend.order.dto;

import java.util.UUID;

public class OrderItemSplitRequest {
    private UUID orderItemId;
    private Integer quantity;

    public OrderItemSplitRequest() {}

    public OrderItemSplitRequest(UUID orderItemId, Integer quantity) {
        this.orderItemId = orderItemId;
        this.quantity = quantity;
    }

    public UUID getOrderItemId() { return orderItemId; }
    public void setOrderItemId(UUID orderItemId) { this.orderItemId = orderItemId; }

    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
}
