package com.example.backend.customer.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CustomerAddressRequest {

    @NotBlank(message = "Address label is required (e.g. Home, Work)")
    private String label;

    private String houseNo;
    private String street;
    private String landmark;
    private String city;
    private String state;
    private String pincode;
    private Double latitude;
    private Double longitude;
    private String fullAddress;
    private Boolean isDefault;
}
