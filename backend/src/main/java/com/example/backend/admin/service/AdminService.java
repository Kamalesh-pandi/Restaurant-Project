package com.example.backend.admin.service;

import com.example.backend.admin.dto.AdminRequest;
import com.example.backend.admin.dto.AdminResponse;
import com.example.backend.admin.entity.Admin;
import com.example.backend.admin.repository.AdminRepository;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class AdminService {

    private final AdminRepository adminRepository;
    private final PasswordEncoder passwordEncoder;

    public AdminService(AdminRepository adminRepository, PasswordEncoder passwordEncoder) {
        this.adminRepository = adminRepository;
        this.passwordEncoder = passwordEncoder;
    }

    public List<AdminResponse> getAllAdmins() {
        return adminRepository.findAll().stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public AdminResponse getAdminById(UUID id) {
        Admin admin = adminRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Admin not found"));
        return mapToResponse(admin);
    }

    @Transactional
    public AdminResponse createAdmin(AdminRequest request) {
        if (adminRepository.findByUsername(request.getUsername()).isPresent()) {
            throw new RuntimeException("Username is already taken");
        }
        Admin admin = Admin.builder()
                .username(request.getUsername())
                .password(passwordEncoder.encode(request.getPassword()))
                .name(request.getName())
                .email(request.getEmail())
                .phoneNumber(request.getPhoneNumber())
                .isActive(true)
                .adminAccessLevel(request.getAdminAccessLevel())
                .build();
        return mapToResponse(adminRepository.save(admin));
    }

    @Transactional
    public AdminResponse updateAdmin(UUID id, AdminRequest request) {
        Admin admin = adminRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Admin not found"));
        admin.setName(request.getName());
        admin.setEmail(request.getEmail());
        if (request.getPhoneNumber() != null) admin.setPhoneNumber(request.getPhoneNumber());
        admin.setPassword(passwordEncoder.encode(request.getPassword()));
        admin.setAdminAccessLevel(request.getAdminAccessLevel());
        return mapToResponse(adminRepository.save(admin));
    }

    @Transactional
    public void deleteAdmin(UUID id) {
        adminRepository.deleteById(id);
    }

    @Transactional
    public AdminResponse toggleAdminActive(UUID id) {
        Admin admin = adminRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Admin not found"));
        admin.setActive(!admin.isActive());
        return mapToResponse(adminRepository.save(admin));
    }

    private AdminResponse mapToResponse(Admin admin) {
        return AdminResponse.builder()
                .adminId(admin.getAdminId())
                .username(admin.getUsername())
                .name(admin.getName())
                .email(admin.getEmail())
                .phoneNumber(admin.getPhoneNumber())
                .isActive(admin.isActive())
                .adminAccessLevel(admin.getAdminAccessLevel())
                .build();
    }
}
