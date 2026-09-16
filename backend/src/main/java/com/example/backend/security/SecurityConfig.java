package com.example.backend.security;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
            .cors(cors -> cors.configurationSource(corsConfigurationSource()))
            .csrf(csrf -> csrf.disable())
            .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/auth/**", "/api/customers/register", "/api/customers/register-otp", "/api/customers/verify-otp", "/api/v1/reservations/online", "/api/staff/login-pin", "/api/staff/clock-in", "/api/staff/clock-out", "/ws/**", "/error").permitAll()
                .requestMatchers("/api/v1/admin", "/api/v1/admin/**").hasAnyRole("ADMIN", "MANAGER")
                .requestMatchers("/api/staff", "/api/staff/**").hasAnyRole("ADMIN", "MANAGER", "CASHIER", "CAPTAIN", "KITCHEN", "DELIVERY_PARTNER")
                .requestMatchers("/api/customers", "/api/customers/**").hasAnyRole("CASHIER", "MANAGER", "CAPTAIN", "ADMIN")
                .requestMatchers("/api/v1/orders", "/api/v1/orders/**").hasAnyRole("CASHIER", "MANAGER", "CAPTAIN", "KITCHEN", "ADMIN", "DELIVERY_PARTNER")
                .requestMatchers("/api/v1/tables", "/api/v1/tables/**").hasAnyRole("CASHIER", "MANAGER", "CAPTAIN", "ADMIN")
                .requestMatchers("/api/v1/waitlist", "/api/v1/waitlist/**").hasAnyRole("CASHIER", "MANAGER", "CAPTAIN", "ADMIN")
                .requestMatchers("/api/v1/reservations", "/api/v1/reservations/**").hasAnyRole("MANAGER", "ADMIN", "CASHIER", "CAPTAIN")
                .requestMatchers("/api/v1/bills/*/settle", "/api/v1/bills/*/settle-split").permitAll()
                .requestMatchers("/api/v1/bills", "/api/v1/bills/**").hasAnyRole("CASHIER", "MANAGER", "ADMIN")
                .requestMatchers("/api/v1/payments/razorpay/key").hasAnyRole("CASHIER", "MANAGER", "ADMIN")
                .requestMatchers("/api/v1/payments/razorpay/create-order", "/api/v1/payments/razorpay/verify", "/api/v1/payments/razorpay").permitAll()
                .requestMatchers("/api/v1/reports/z-report").hasAnyRole("MANAGER", "ADMIN")
                .requestMatchers("/api/v1/inventory", "/api/v1/inventory/**").hasAnyRole("MANAGER", "ADMIN")
                .requestMatchers("/api/v1/analytics", "/api/v1/analytics/**").hasAnyRole("MANAGER", "ADMIN")
                .requestMatchers("/api/v1/kds", "/api/v1/kds/**").hasAnyRole("KITCHEN", "MANAGER", "ADMIN")
                .requestMatchers("/api/v1/kitchen-stations", "/api/v1/kitchen-stations/**").hasAnyRole("CASHIER", "MANAGER", "CAPTAIN", "KITCHEN", "ADMIN")
                .requestMatchers("/api/v1/customer-app/**").permitAll()
                .requestMatchers("/api/v1/menu", "/api/v1/menu/**").hasAnyRole("ADMIN", "MANAGER", "CASHIER", "CAPTAIN", "KITCHEN")
                .requestMatchers("/api/v1/chain", "/api/v1/chain/**").hasAnyRole("ADMIN", "MANAGER")
                .requestMatchers("/api/v1/discounts", "/api/v1/discounts/**", "/api/v1/promotions", "/api/v1/promotions/**").hasAnyRole("ADMIN", "MANAGER", "CASHIER")
                .requestMatchers("/api/v1/delivery-partner/login-pin", "/api/v1/delivery-partner/register").permitAll()
                .requestMatchers("/api/v1/delivery-partner", "/api/v1/delivery-partner/**").hasAnyRole("DELIVERY_PARTNER", "MANAGER", "ADMIN")
                .requestMatchers("/api/v1/delivery-management", "/api/v1/delivery-management/**").hasAnyRole("CASHIER", "MANAGER", "CAPTAIN", "ADMIN", "KITCHEN")
                .anyRequest().authenticated()
            )
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOriginPatterns(List.of("*"));
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration authenticationConfiguration) throws Exception {
        return authenticationConfiguration.getAuthenticationManager();
    }
}
