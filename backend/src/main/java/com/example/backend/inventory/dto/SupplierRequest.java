package com.example.backend.inventory.dto;

import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SupplierRequest {
    private String name;
    private String contact;
    private String itemsSupplied;
    private String priceHistory;
}
