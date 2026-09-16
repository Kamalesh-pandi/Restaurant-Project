package com.example.backend.staff.dto;

import com.example.backend.staff.entity.StaffRole;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class StaffRequest {
    @NotBlank(message = "Name is required")
    private String name;

    private String email;

    private String phoneNumber;

    @NotBlank(message = "PIN is required")
    private String pin;

    @NotNull(message = "Role is required")
    private StaffRole role;

    private String section;

    private UUID outletId;

    private String employmentType;
}
