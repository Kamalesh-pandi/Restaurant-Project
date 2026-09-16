package com.example.backend.customer.dto;

import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerFeedbackRequest {
    private UUID visitId;
    private int rating;
    private String comment;
}
