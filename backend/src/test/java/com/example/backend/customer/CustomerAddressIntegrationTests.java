package com.example.backend.customer;

import com.example.backend.customer.controller.CustomerAppController;
import com.example.backend.customer.dto.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.ResponseEntity;

import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
public class CustomerAddressIntegrationTests {

    @Autowired
    private CustomerAppController customerAppController;

    private String testPhone;

    @BeforeEach
    void setUp() {
        testPhone = "+91 9123456789";
    }

    @Test
    void testCustomerMultipleAddressesWorkflow() {
        // 1. Add first address (Home) -> should automatically become default
        CustomerAddressRequest homeReq = CustomerAddressRequest.builder()
                .label("Home")
                .houseNo("Flat 301, Sunshine Apartments")
                .street("10th Main Road, Koramangala")
                .city("Bangalore")
                .state("Karnataka")
                .pincode("560034")
                .latitude(12.9352)
                .longitude(77.6245)
                .build();

        ResponseEntity<CustomerAddressResponse> homeRes = customerAppController.addCustomerAddress(testPhone, null, homeReq);
        assertNotNull(homeRes.getBody());
        CustomerAddressResponse homeAddr = homeRes.getBody();
        assertEquals("Home", homeAddr.getLabel());
        assertTrue(homeAddr.getIsDefault());
        assertNotNull(homeAddr.getAddressId());
        assertTrue(homeAddr.getFullAddress().contains("Flat 301"));

        // 2. Add second address (Work) -> non-default by default
        CustomerAddressRequest workReq = CustomerAddressRequest.builder()
                .label("Work")
                .houseNo("Tech Park Tower B, 5th Floor")
                .street("Outer Ring Road, Marathahalli")
                .city("Bangalore")
                .state("Karnataka")
                .pincode("560103")
                .latitude(12.9370)
                .longitude(77.6950)
                .isDefault(false)
                .build();

        ResponseEntity<CustomerAddressResponse> workRes = customerAppController.addCustomerAddress(testPhone, null, workReq);
        assertNotNull(workRes.getBody());
        CustomerAddressResponse workAddr = workRes.getBody();
        assertEquals("Work", workAddr.getLabel());
        assertFalse(workAddr.getIsDefault());

        // 3. Get customer addresses list -> expect 2 addresses
        ResponseEntity<List<CustomerAddressResponse>> listRes = customerAppController.getCustomerAddresses(testPhone, null);
        assertNotNull(listRes.getBody());
        assertEquals(2, listRes.getBody().size());

        // 4. Set Work address as default
        ResponseEntity<CustomerAddressResponse> newDefaultRes = customerAppController.setDefaultCustomerAddress(workAddr.getAddressId(), testPhone, null);
        assertNotNull(newDefaultRes.getBody());
        assertTrue(newDefaultRes.getBody().getIsDefault());

        // Verify Home address is no longer default
        CustomerAddressResponse homeRefreshed = customerAppController.getAddressById(homeAddr.getAddressId()).getBody();
        assertNotNull(homeRefreshed);
        assertFalse(homeRefreshed.getIsDefault());

        // 5. Profile API includes addresses
        ResponseEntity<CustomerResponse> profileRes = customerAppController.getCustomerProfile(testPhone, null);
        assertNotNull(profileRes.getBody());
        assertNotNull(profileRes.getBody().getAddresses());
        assertEquals(2, profileRes.getBody().getAddresses().size());

        // 6. Place direct order referencing saved addressId
        DirectOrderRequest orderReq = new DirectOrderRequest();
        orderReq.setCustomerName("Test Customer");
        orderReq.setCustomerPhone(testPhone);
        orderReq.setAddressId(workAddr.getAddressId());
        orderReq.setPaymentMethod("COD");

        ResponseEntity<CustomerOrderTrackingResponse> orderRes = customerAppController.placeDirectOrder(orderReq);
        assertNotNull(orderRes.getBody());
        assertTrue(orderRes.getBody().getDeliveryAddress().contains("Tech Park Tower B"));

        // 7. Update address
        CustomerAddressRequest updateReq = CustomerAddressRequest.builder()
                .label("Home Sweet Home")
                .houseNo("Villa 12, Palm Meadows")
                .build();
        ResponseEntity<CustomerAddressResponse> updatedRes = customerAppController.updateCustomerAddress(homeAddr.getAddressId(), updateReq);
        assertNotNull(updatedRes.getBody());
        assertEquals("Home Sweet Home", updatedRes.getBody().getLabel());
        assertTrue(updatedRes.getBody().getFullAddress().contains("Villa 12"));

        // 8. Delete address
        ResponseEntity<Map<String, Object>> deleteRes = customerAppController.deleteCustomerAddress(homeAddr.getAddressId(), testPhone, null);
        assertNotNull(deleteRes.getBody());
        assertEquals("Address deleted successfully", deleteRes.getBody().get("message"));

        // Verify list size is now 1
        ResponseEntity<List<CustomerAddressResponse>> remainingRes = customerAppController.getCustomerAddresses(testPhone, null);
        assertNotNull(remainingRes.getBody());
        assertEquals(1, remainingRes.getBody().size());
        assertEquals("Work", remainingRes.getBody().get(0).getLabel());
    }
}
