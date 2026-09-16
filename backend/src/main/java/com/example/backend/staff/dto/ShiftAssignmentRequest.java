package com.example.backend.staff.dto;

import java.time.LocalDate;
import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ShiftAssignmentRequest {
    private UUID shiftId;
    private UUID staffId;
    private LocalDate assignmentDate;
}
