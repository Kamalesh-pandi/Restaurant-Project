package com.example.backend.customer.dto;

import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class WishlistToggleRequest {
    private String phone;
    private UUID menuItemId;
    private UUID itemId;
}
