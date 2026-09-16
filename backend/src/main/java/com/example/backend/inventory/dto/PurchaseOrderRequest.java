package com.example.backend.inventory.dto;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PurchaseOrderRequest {
    private UUID supplierId;
    private LocalDate expectedDelivery;
    private List<PurchaseOrderItemRequest> items;
}
