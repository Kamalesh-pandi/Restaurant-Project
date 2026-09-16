package com.example.backend.order.dto;

import java.util.List;
import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class KdsSyncRequest {
    private List<UUID> bumpedItemIds;
}
