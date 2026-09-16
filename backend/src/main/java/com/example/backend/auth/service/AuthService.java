package com.example.backend.auth.service;

import com.example.backend.auth.dto.LoginRequest;
import com.example.backend.auth.dto.LoginResponse;
import com.example.backend.security.JwtUtil;
import com.example.backend.admin.dto.AdminRequest;
import com.example.backend.admin.dto.AdminResponse;
import com.example.backend.admin.entity.Admin;
import com.example.backend.admin.repository.AdminRepository;
import com.example.backend.customer.entity.Customer;
import com.example.backend.customer.repository.CustomerRepository;
import com.example.backend.staff.entity.Staff;
import com.example.backend.staff.repository.StaffRepository;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final AdminRepository adminRepository;
    private final StaffRepository staffRepository;
    private final CustomerRepository customerRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public AuthService(AuthenticationManager authenticationManager,
                       AdminRepository adminRepository,
                       StaffRepository staffRepository,
                       CustomerRepository customerRepository,
                       PasswordEncoder passwordEncoder,
                       JwtUtil jwtUtil) {
        this.authenticationManager = authenticationManager;
        this.adminRepository = adminRepository;
        this.staffRepository = staffRepository;
        this.customerRepository = customerRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtUtil = jwtUtil;
    }

    public LoginResponse login(LoginRequest loginRequest) {
        String identifier = loginRequest.getUsername();
        if (identifier == null || identifier.isBlank()) {
            identifier = loginRequest.getEmail();
        }

        // Try customer fallback first if user exists in Customer repository
        if (identifier != null && !identifier.isBlank()) {
            Optional<Customer> custOpt = customerRepository.findByEmail(identifier);
            if (custOpt.isEmpty()) {
                custOpt = customerRepository.findByPhone(identifier);
            }
            if (custOpt.isPresent()) {
                Customer cust = custOpt.get();
                String token = jwtUtil.generateToken(cust.getPhone());
                return LoginResponse.builder()
                        .token(token)
                        .username(cust.getPhone())
                        .name(cust.getName())
                        .role("CUSTOMER")
                        .build();
            }
        }

        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(identifier, loginRequest.getPassword())
        );

        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        String token = jwtUtil.generateToken(userDetails.getUsername());

        String name = "";
        String role = "";

        Optional<Admin> adminOpt = adminRepository.findByUsername(userDetails.getUsername());
        if (adminOpt.isEmpty()) {
            adminOpt = adminRepository.findByEmail(userDetails.getUsername());
        }
        if (adminOpt.isPresent()) {
            name = adminOpt.get().getName();
            role = "ADMIN";
        } else {
            Optional<Staff> staffOpt = staffRepository.findByName(userDetails.getUsername());
            if (staffOpt.isPresent()) {
                name = staffOpt.get().getName();
                role = staffOpt.get().getRole().name();
            } else {
                name = userDetails.getUsername();
                role = "CUSTOMER";
            }
        }

        return LoginResponse.builder()
                .token(token)
                .username(userDetails.getUsername())
                .name(name)
                .role(role)
                .build();
    }

    @Transactional
    public AdminResponse register(AdminRequest adminRequest) {
        if (adminRepository.findByUsername(adminRequest.getUsername()).isPresent()) {
            throw new RuntimeException("Username is already taken");
        }

        Admin admin = Admin.builder()
                .username(adminRequest.getUsername())
                .password(passwordEncoder.encode(adminRequest.getPassword()))
                .name(adminRequest.getName())
                .email(adminRequest.getEmail())
                .isActive(true)
                .adminAccessLevel(adminRequest.getAdminAccessLevel() != null ? adminRequest.getAdminAccessLevel() : "STANDARD_ADMIN")
                .build();

        Admin savedAdmin = adminRepository.save(admin);

        AdminResponse response = new AdminResponse();
        response.setAdminId(savedAdmin.getAdminId());
        response.setUsername(savedAdmin.getUsername());
        response.setName(savedAdmin.getName());
        response.setEmail(savedAdmin.getEmail());
        response.setActive(savedAdmin.isActive());
        response.setAdminAccessLevel(savedAdmin.getAdminAccessLevel());

        return response;
    }
}
