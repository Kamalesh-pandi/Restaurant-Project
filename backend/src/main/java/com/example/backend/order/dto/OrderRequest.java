package com.example.backend.order.dto;

import com.example.backend.order.entity.Order;
import com.example.backend.order.entity.OrderItem;
import java.util.List;

public class OrderRequest {
    private Order order;
    private List<OrderItem> items;

    public OrderRequest() {}

    public OrderRequest(Order order, List<OrderItem> items) {
        this.order = order;
        this.items = items;
    }

    public Order getOrder() { return order; }
    public void setOrder(Order order) { this.order = order; }

    public List<OrderItem> getItems() { return items; }
    public void setItems(List<OrderItem> items) { this.items = items; }
}
