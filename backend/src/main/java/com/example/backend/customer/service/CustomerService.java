package com.example.backend.customer.service;

import com.example.backend.customer.dto.*;
import com.example.backend.customer.entity.*;
import com.example.backend.customer.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import com.example.backend.security.JwtUtil;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class CustomerService {

    private final CustomerRepository customerRepository;
    private final CustomerVisitRepository customerVisitRepository;
    private final SmsService smsService;
    private final JwtUtil jwtUtil;
    private final CustomerAddressService customerAddressService;

    public CustomerService(CustomerRepository customerRepository,
                           CustomerVisitRepository customerVisitRepository,
                           SmsService smsService,
                           JwtUtil jwtUtil,
                           CustomerAddressService customerAddressService) {
        this.customerRepository = customerRepository;
        this.customerVisitRepository = customerVisitRepository;
        this.smsService = smsService;
        this.jwtUtil = jwtUtil;
        this.customerAddressService = customerAddressService;
    }

    public List<CustomerResponse> getAllCustomers() {
        return customerRepository.findAll().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public CustomerResponse getCustomerById(UUID id) {
        Customer customer = customerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Customer not found"));
        return mapToResponse(customer);
    }

    @Transactional
    public CustomerResponse createCustomer(CustomerRequest request) {
        if (customerRepository.findByPhone(request.getPhone()).isPresent()) {
            throw new RuntimeException("Customer with this phone number already exists");
        }
        Customer customer = Customer.builder()
                .phone(request.getPhone())
                .name(request.getName() != null && !request.getName().isBlank() ? request.getName() : "Customer " + request.getPhone())
                .email(request.getEmail())
                .birthday(request.getBirthday())
                .loyaltyPoints(0)
                .totalVisits(0)
                .totalSpend(BigDecimal.ZERO)
                .isVip(false)
                .otpVerified(true)
                .build();
        return mapToResponse(customerRepository.save(customer));
    }



    @Transactional
    public CustomerResponse updateCustomer(UUID id, CustomerRequest request) {
        Customer customer = customerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Customer not found"));
        customer.setName(request.getName());
        customer.setPhone(request.getPhone());
        customer.setEmail(request.getEmail());
        customer.setBirthday(request.getBirthday());
        return mapToResponse(customerRepository.save(customer));
    }

    @Transactional
    public void deleteCustomer(UUID id) {
        customerRepository.deleteById(id);
    }

    @Transactional
    public CustomerVisit logVisit(UUID customerId, UUID orderId, String tableNumber, String itemsOrdered, BigDecimal spend) {
        CustomerVisit visit = CustomerVisit.builder()
                .customerId(customerId)
                .orderId(orderId)
                .visitDate(LocalDateTime.now())
                .tableNumber(tableNumber)
                .itemsOrdered(itemsOrdered)
                .spend(spend)
                .build();

        CustomerVisit savedVisit = customerVisitRepository.save(visit);

        Customer customer = customerRepository.findById(customerId).orElse(null);
        if (customer != null) {
            System.out.println(String.format("[FEEDBACK SMS] Sent post-visit rating link http://deluxediner.com/feedback/%s to %s (+91%s).",
                    savedVisit.getId(), customer.getName(), customer.getPhone()));
        }

        return savedVisit;
    }

    @Transactional
    public CustomerVisit submitFeedback(CustomerFeedbackRequest request) {
        CustomerVisit visit = customerVisitRepository.findById(request.getVisitId())
                .orElseThrow(() -> new RuntimeException("Visit record not found"));

        visit.setRating(request.getRating());
        visit.setFeedbackComment(request.getComment());
        return customerVisitRepository.save(visit);
    }

    @Transactional
    public CustomerResponse toggleVipTag(UUID id, boolean isVip) {
        Customer customer = customerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Customer not found"));
        customer.setIsVip(isVip);
        return mapToResponse(customerRepository.save(customer));
    }

    public CustomerAnalyticsResponse getCustomerAnalytics(UUID id) {
        Customer customer = customerRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Customer not found"));

        BigDecimal aov = BigDecimal.ZERO;
        if (customer.getTotalVisits() > 0) {
            aov = customer.getTotalSpend().divide(BigDecimal.valueOf(customer.getTotalVisits()), 2, RoundingMode.HALF_UP);
        }

        double redemptionRate = 0.0;
        if (customer.getPointsEarned() > 0) {
            redemptionRate = ((double) customer.getPointsRedeemed() / customer.getPointsEarned()) * 100.0;
        }

        return CustomerAnalyticsResponse.builder()
                .customerId(customer.getCustomerId())
                .name(customer.getName())
                .totalVisits(customer.getTotalVisits())
                .totalSpend(customer.getTotalSpend())
                .averageOrderValue(aov)
                .loyaltyRedemptionRate(redemptionRate)
                .build();
    }

    public String getCustomerSegment(Customer customer) {
        LocalDateTime now = LocalDateTime.now();
        
        if (customer.getLastVisitAt() != null && customer.getLastVisitAt().isBefore(now.minusDays(30))) {
            return "LAPSED";
        }

        List<CustomerVisit> visits = customerVisitRepository.findByCustomerId(customer.getCustomerId());
        long recentVisits = visits.stream()
                .filter(v -> v.getVisitDate().isAfter(now.minusDays(30)))
                .count();

        if (recentVisits > 5 || customer.getTotalVisits() > 5) {
            return "HIGH_VALUE";
        }

        if (customer.getTotalVisits() <= 1) {
            return "NEW";
        }

        return "STANDARD";
    }

    public void sendTargetedCampaign(String segment, String messageText) {
        List<Customer> allCustomers = customerRepository.findAll();
        for (Customer customer : allCustomers) {
            String customerSegment = getCustomerSegment(customer);
            if (customerSegment.equalsIgnoreCase(segment)) {
                System.out.println(String.format("[CAMPAIGN SMS] Sent to %s customer %s (+91%s): \"%s\"",
                        segment.toUpperCase(), customer.getName(), customer.getPhone(), messageText));
            }
        }
    }

    public void runBirthdayCampaign() {
        LocalDate today = LocalDate.now();
        LocalDate targetDate = today.plusDays(3);

        List<Customer> all = customerRepository.findAll();
        for (Customer c : all) {
            if (c.getBirthday() != null 
                    && c.getBirthday().getMonth() == targetDate.getMonth() 
                    && c.getBirthday().getDayOfMonth() == targetDate.getDayOfMonth()) {
                
                System.out.println(String.format("[BIRTHDAY SMS] Sent to %s (+91%s): \"Happy early Birthday! Show voucher BDAY-DESSERT-%s to claim a complimentary dessert on your next visit!\"",
                        c.getName(), c.getPhone(), c.getCustomerId().toString().substring(0, 5).toUpperCase()));
            }
        }
    }

    private CustomerResponse mapToResponse(Customer customer) {
        return CustomerResponse.builder()
                .customerId(customer.getCustomerId())
                .phone(customer.getPhone())
                .name(customer.getName())
                .email(customer.getEmail())
                .birthday(customer.getBirthday())
                .loyaltyPoints(customer.getLoyaltyPoints())
                .totalVisits(customer.getTotalVisits())
                .totalSpend(customer.getTotalSpend())
                .isVip(customer.getIsVip())
                .otpVerified(customer.getOtpVerified())
                .lastVisitAt(customer.getLastVisitAt())
                .token(customer.getPhone() != null ? jwtUtil.generateToken(customer.getPhone()) : "jwt_cust_session")
                .addresses(customer.getCustomerId() != null ? customerAddressService.getAddressesForCustomer(customer.getCustomerId()) : java.util.Collections.emptyList())
                .build();
    }
}
