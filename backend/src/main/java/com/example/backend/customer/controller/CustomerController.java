package com.example.backend.customer.controller;

import com.example.backend.customer.dto.*;
import com.example.backend.customer.entity.CustomerVisit;
import com.example.backend.customer.service.CustomerService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/customers")
public class CustomerController {

    private final CustomerService customerService;

    public CustomerController(CustomerService customerService) {
        this.customerService = customerService;
    }

    @GetMapping
    public ResponseEntity<List<CustomerResponse>> getAllCustomers() {
        return ResponseEntity.ok(customerService.getAllCustomers());
    }

    @GetMapping("/{id}")
    public ResponseEntity<CustomerResponse> getCustomerById(@PathVariable UUID id) {
        return ResponseEntity.ok(customerService.getCustomerById(id));
    }

    @PostMapping
    public ResponseEntity<CustomerResponse> createCustomer(@Valid @RequestBody CustomerRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(customerService.createCustomer(request));
    }

    @PostMapping("/register")
    public ResponseEntity<CustomerResponse> registerCustomer(@Valid @RequestBody CustomerRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(customerService.createCustomer(request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<CustomerResponse> updateCustomer(@PathVariable UUID id, @Valid @RequestBody CustomerRequest request) {
        return ResponseEntity.ok(customerService.updateCustomer(id, request));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCustomer(@PathVariable UUID id) {
        customerService.deleteCustomer(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/feedback")
    public ResponseEntity<CustomerVisit> submitFeedback(@RequestBody CustomerFeedbackRequest request) {
        return ResponseEntity.ok(customerService.submitFeedback(request));
    }

    @PutMapping("/{id}/vip")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<CustomerResponse> toggleVipTag(@PathVariable UUID id, @RequestParam boolean isVip) {
        return ResponseEntity.ok(customerService.toggleVipTag(id, isVip));
    }

    @GetMapping("/{id}/analytics")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<CustomerAnalyticsResponse> getCustomerAnalytics(@PathVariable UUID id) {
        return ResponseEntity.ok(customerService.getCustomerAnalytics(id));
    }

    @PostMapping("/campaign")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<String> sendTargetedCampaign(@RequestParam String segment, @RequestParam String messageText) {
        customerService.sendTargetedCampaign(segment, messageText);
        return ResponseEntity.ok("Targeted SMS campaign dispatched to segment " + segment);
    }

    @PostMapping("/birthday-campaign")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<String> runBirthdayCampaign() {
        customerService.runBirthdayCampaign();
        return ResponseEntity.ok("Birthday campaign scan and dispatch complete");
    }
}
