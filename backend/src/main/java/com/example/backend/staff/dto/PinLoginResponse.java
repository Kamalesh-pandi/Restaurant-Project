package com.example.backend.staff.dto;

import com.example.backend.staff.entity.StaffRole;
import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class PinLoginResponse {
    private String token;
    private UUID staffId;
    private String name;
    private StaffRole role;
    @Builder.Default
    private Integer autoExpireMinutes = 30;
}
