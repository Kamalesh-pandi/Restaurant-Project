package com.example.backend.staff.dto;

import com.example.backend.staff.entity.StaffRole;
import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StaffResponse {
    private UUID staffId;
    private UUID outletId;
    private String name;
    private String email;
    private String phoneNumber;
    private StaffRole role;
    private String section;
    private boolean isActive;
    private String employmentType;
}
