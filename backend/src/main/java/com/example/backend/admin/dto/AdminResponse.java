package com.example.backend.admin.dto;

import java.util.UUID;

public class AdminResponse {
    private UUID adminId;
    private String username;
    private String name;
    private String email;
    private String phoneNumber;
    private boolean isActive;
    private String adminAccessLevel;

    public AdminResponse() {}

    public AdminResponse(UUID adminId, String username, String name, String email, String phoneNumber, boolean isActive, String adminAccessLevel) {
        this.adminId = adminId;
        this.username = username;
        this.name = name;
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.isActive = isActive;
        this.adminAccessLevel = adminAccessLevel;
    }

    public UUID getAdminId() { return adminId; }
    public void setAdminId(UUID adminId) { this.adminId = adminId; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }

    public boolean isActive() { return isActive; }
    public void setActive(boolean active) { this.isActive = active; }

    public String getAdminAccessLevel() { return adminAccessLevel; }
    public void setAdminAccessLevel(String adminAccessLevel) { this.adminAccessLevel = adminAccessLevel; }

    public static AdminResponseBuilder builder() {
        return new AdminResponseBuilder();
    }

    public static class AdminResponseBuilder {
        private UUID adminId;
        private String username;
        private String name;
        private String email;
        private String phoneNumber;
        private boolean isActive;
        private String adminAccessLevel;

        public AdminResponseBuilder adminId(UUID adminId) { this.adminId = adminId; return this; }
        public AdminResponseBuilder username(String username) { this.username = username; return this; }
        public AdminResponseBuilder name(String name) { this.name = name; return this; }
        public AdminResponseBuilder email(String email) { this.email = email; return this; }
        public AdminResponseBuilder phoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; return this; }
        public AdminResponseBuilder isActive(boolean isActive) { this.isActive = isActive; return this; }
        public AdminResponseBuilder adminAccessLevel(String adminAccessLevel) { this.adminAccessLevel = adminAccessLevel; return this; }

        public AdminResponse build() {
            return new AdminResponse(adminId, username, name, email, phoneNumber, isActive, adminAccessLevel);
        }
    }
}
