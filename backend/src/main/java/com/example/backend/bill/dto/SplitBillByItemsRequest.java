package com.example.backend.bill.dto;

import java.util.List;
import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class SplitBillByItemsRequest {
    private List<List<UUID>> itemGroups;
    private String managerPin;
}
