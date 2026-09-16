package com.example.backend.admin.dto;

import jakarta.validation.constraints.NotBlank;

public class AdminRequest {
    @NotBlank(message = "Username is required")
    private String username;

    @NotBlank(message = "Password is required")
    private String password;

    @NotBlank(message = "Name is required")
    private String name;

    private String email;

    private String phoneNumber;

    private String adminAccessLevel;

    public AdminRequest() {}

    public AdminRequest(String username, String password, String name, String email, String phoneNumber, String adminAccessLevel) {
        this.username = username;
        this.password = password;
        this.name = name;
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.adminAccessLevel = adminAccessLevel;
    }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }

    public String getAdminAccessLevel() { return adminAccessLevel; }
    public void setAdminAccessLevel(String adminAccessLevel) { this.adminAccessLevel = adminAccessLevel; }
}
