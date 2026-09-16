package com.example.backend.customer.service;

import com.example.backend.customer.dto.CustomerAddressRequest;
import com.example.backend.customer.dto.CustomerAddressResponse;
import com.example.backend.customer.entity.CustomerAddress;
import com.example.backend.customer.repository.CustomerAddressRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class CustomerAddressService {

    private final CustomerAddressRepository addressRepository;

    public CustomerAddressService(CustomerAddressRepository addressRepository) {
        this.addressRepository = addressRepository;
    }

    public List<CustomerAddressResponse> getAddressesForCustomer(UUID customerId) {
        return addressRepository.findByCustomerIdOrderByIsDefaultDescCreatedAtDesc(customerId).stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public CustomerAddressResponse getAddressById(UUID addressId) {
        CustomerAddress address = addressRepository.findById(addressId)
                .orElseThrow(() -> new RuntimeException("Address not found with id: " + addressId));
        return mapToResponse(address);
    }

    @Transactional
    public CustomerAddressResponse addAddress(UUID customerId, CustomerAddressRequest request) {
        List<CustomerAddress> existing = addressRepository.findByCustomerIdOrderByIsDefaultDescCreatedAtDesc(customerId);
        boolean isFirst = existing.isEmpty();
        boolean shouldBeDefault = isFirst || Boolean.TRUE.equals(request.getIsDefault());

        if (shouldBeDefault && !existing.isEmpty()) {
            clearDefaultAddressForCustomer(customerId);
        }

        String formattedFull = buildFullAddressString(request);

        CustomerAddress address = CustomerAddress.builder()
                .customerId(customerId)
                .label(request.getLabel() != null && !request.getLabel().isBlank() ? request.getLabel() : "Home")
                .houseNo(request.getHouseNo())
                .street(request.getStreet())
                .landmark(request.getLandmark())
                .city(request.getCity())
                .state(request.getState())
                .pincode(request.getPincode())
                .latitude(request.getLatitude())
                .longitude(request.getLongitude())
                .fullAddress(formattedFull)
                .isDefault(shouldBeDefault)
                .build();

        return mapToResponse(addressRepository.save(address));
    }

    @Transactional
    public CustomerAddressResponse updateAddress(UUID addressId, CustomerAddressRequest request) {
        CustomerAddress address = addressRepository.findById(addressId)
                .orElseThrow(() -> new RuntimeException("Address not found with id: " + addressId));

        if (Boolean.TRUE.equals(request.getIsDefault()) && !Boolean.TRUE.equals(address.getIsDefault())) {
            clearDefaultAddressForCustomer(address.getCustomerId());
            address.setIsDefault(true);
        }

        if (request.getLabel() != null) address.setLabel(request.getLabel());
        if (request.getHouseNo() != null) address.setHouseNo(request.getHouseNo());
        if (request.getStreet() != null) address.setStreet(request.getStreet());
        if (request.getLandmark() != null) address.setLandmark(request.getLandmark());
        if (request.getCity() != null) address.setCity(request.getCity());
        if (request.getState() != null) address.setState(request.getState());
        if (request.getPincode() != null) address.setPincode(request.getPincode());
        if (request.getLatitude() != null) address.setLatitude(request.getLatitude());
        if (request.getLongitude() != null) address.setLongitude(request.getLongitude());

        String formattedFull = buildFullAddressString(request);
        if (formattedFull != null && !formattedFull.isBlank()) {
            address.setFullAddress(formattedFull);
        }

        return mapToResponse(addressRepository.save(address));
    }

    @Transactional
    public void deleteAddress(UUID customerId, UUID addressId) {
        CustomerAddress address = addressRepository.findById(addressId)
                .orElseThrow(() -> new RuntimeException("Address not found with id: " + addressId));

        boolean wasDefault = Boolean.TRUE.equals(address.getIsDefault());
        addressRepository.delete(address);

        if (wasDefault) {
            List<CustomerAddress> remaining = addressRepository.findByCustomerIdOrderByIsDefaultDescCreatedAtDesc(customerId);
            if (!remaining.isEmpty()) {
                CustomerAddress newDefault = remaining.get(0);
                newDefault.setIsDefault(true);
                addressRepository.save(newDefault);
            }
        }
    }

    @Transactional
    public CustomerAddressResponse setDefaultAddress(UUID customerId, UUID addressId) {
        CustomerAddress target = addressRepository.findById(addressId)
                .orElseThrow(() -> new RuntimeException("Address not found with id: " + addressId));

        if (!target.getCustomerId().equals(customerId)) {
            throw new RuntimeException("Address does not belong to customer");
        }

        clearDefaultAddressForCustomer(customerId);
        target.setIsDefault(true);
        return mapToResponse(addressRepository.save(target));
    }

    private void clearDefaultAddressForCustomer(UUID customerId) {
        List<CustomerAddress> addresses = addressRepository.findByCustomerIdOrderByIsDefaultDescCreatedAtDesc(customerId);
        for (CustomerAddress addr : addresses) {
            if (Boolean.TRUE.equals(addr.getIsDefault())) {
                addr.setIsDefault(false);
                addressRepository.save(addr);
            }
        }
    }

    private String buildFullAddressString(CustomerAddressRequest req) {
        if (req.getFullAddress() != null && !req.getFullAddress().isBlank()) {
            return req.getFullAddress();
        }
        StringBuilder sb = new StringBuilder();
        if (req.getHouseNo() != null && !req.getHouseNo().isBlank()) sb.append(req.getHouseNo()).append(", ");
        if (req.getStreet() != null && !req.getStreet().isBlank()) sb.append(req.getStreet()).append(", ");
        if (req.getLandmark() != null && !req.getLandmark().isBlank()) sb.append("Near ").append(req.getLandmark()).append(", ");
        if (req.getCity() != null && !req.getCity().isBlank()) sb.append(req.getCity()).append(", ");
        if (req.getState() != null && !req.getState().isBlank()) sb.append(req.getState()).append(" ");
        if (req.getPincode() != null && !req.getPincode().isBlank()) sb.append(req.getPincode());

        String res = sb.toString().trim();
        if (res.endsWith(",")) res = res.substring(0, res.length() - 1);
        return res;
    }

    public CustomerAddressResponse mapToResponse(CustomerAddress address) {
        return CustomerAddressResponse.builder()
                .addressId(address.getAddressId())
                .customerId(address.getCustomerId())
                .label(address.getLabel())
                .houseNo(address.getHouseNo())
                .street(address.getStreet())
                .landmark(address.getLandmark())
                .city(address.getCity())
                .state(address.getState())
                .pincode(address.getPincode())
                .latitude(address.getLatitude())
                .longitude(address.getLongitude())
                .fullAddress(address.getFullAddress())
                .isDefault(address.getIsDefault())
                .createdAt(address.getCreatedAt())
                .updatedAt(address.getUpdatedAt())
                .build();
    }
}
