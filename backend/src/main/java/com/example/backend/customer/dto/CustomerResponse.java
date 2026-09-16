package com.example.backend.customer.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerResponse {
    private UUID customerId;
    private String phone;
    private String name;
    private String email;
    private LocalDate birthday;
    private Integer loyaltyPoints;
    private Integer totalVisits;
    private BigDecimal totalSpend;
    private Boolean isVip;
    private Boolean otpVerified;
    private LocalDateTime lastVisitAt;
    private String token;
    private String otpCode;
    private List<CustomerAddressResponse> addresses;
}
