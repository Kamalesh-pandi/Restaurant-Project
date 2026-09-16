package com.example.backend.security;

import com.example.backend.admin.entity.Admin;
import com.example.backend.admin.repository.AdminRepository;
import com.example.backend.staff.entity.Staff;
import com.example.backend.staff.repository.StaffRepository;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class CustomUserDetailService implements UserDetailsService {

    private final AdminRepository adminRepository;
    private final StaffRepository staffRepository;
    private final com.example.backend.delivery.repository.DeliveryPartnerRepository deliveryPartnerRepository;

    public CustomUserDetailService(AdminRepository adminRepository,
                                  StaffRepository staffRepository,
                                  com.example.backend.delivery.repository.DeliveryPartnerRepository deliveryPartnerRepository) {
        this.adminRepository = adminRepository;
        this.staffRepository = staffRepository;
        this.deliveryPartnerRepository = deliveryPartnerRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        // 1. Check if the username belongs to an Admin (by username or email)
        Optional<Admin> adminOpt = adminRepository.findByUsername(username);
        if (adminOpt.isEmpty()) {
            adminOpt = adminRepository.findByEmail(username);
        }
        if (adminOpt.isPresent()) {
            Admin admin = adminOpt.get();
            if (!admin.isActive()) {
                throw new RuntimeException("Admin account is inactive");
            }
            return new org.springframework.security.core.userdetails.User(
                    admin.getUsername(),
                    admin.getPassword(),
                    List.of(new SimpleGrantedAuthority("ROLE_ADMIN"))
            );
        }

        // 2. Check if the username corresponds to a Staff name or email
        Optional<Staff> staffOpt = staffRepository.findByName(username);
        if (staffOpt.isEmpty()) {
            staffOpt = staffRepository.findByEmail(username);
        }
        if (staffOpt.isEmpty()) {
            staffOpt = staffRepository.findAll().stream()
                    .filter(s -> s.getName().equalsIgnoreCase(username) || (s.getEmail() != null && s.getEmail().equalsIgnoreCase(username)))
                    .findFirst();
        }
        if (staffOpt.isPresent()) {
            Staff staff = staffOpt.get();
            if (!staff.isActive()) {
                throw new RuntimeException("Staff account is inactive");
            }
            return new org.springframework.security.core.userdetails.User(
                    staff.getName(),
                    staff.getPinHash() != null ? staff.getPinHash() : "",
                    List.of(new SimpleGrantedAuthority("ROLE_" + staff.getRole().name()))
            );
        }

        // 3. Check if the username corresponds to a DeliveryPartner phone or name
        Optional<com.example.backend.delivery.entity.DeliveryPartner> partnerOpt = deliveryPartnerRepository.findByPhone(username);
        if (partnerOpt.isPresent()) {
            com.example.backend.delivery.entity.DeliveryPartner partner = partnerOpt.get();
            if (!partner.getIsActive()) {
                throw new RuntimeException("Delivery Partner account is inactive");
            }
            return new org.springframework.security.core.userdetails.User(
                    partner.getPhone(),
                    partner.getPinCode() != null ? partner.getPinCode() : "",
                    List.of(new SimpleGrantedAuthority("ROLE_DELIVERY_PARTNER"))
            );
        }

        throw new UsernameNotFoundException("User not found with username/phone: " + username);
    }
}
