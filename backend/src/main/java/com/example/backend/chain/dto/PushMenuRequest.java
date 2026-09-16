package com.example.backend.chain.dto;

import java.util.List;
import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PushMenuRequest {
    private List<UUID> targetOutletIds;
    private List<UUID> menuItemIds;
}
