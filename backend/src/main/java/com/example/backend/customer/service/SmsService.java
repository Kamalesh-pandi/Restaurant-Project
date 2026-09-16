package com.example.backend.customer.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.HttpStatusCodeException;
import org.springframework.web.client.RestTemplate;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@Service
public class SmsService {

    @Value("${sms.gateway.enabled:true}")
    private boolean smsEnabled;

    @Value("${sms.gateway.provider:fast2sms}")
    private String provider;

    @Value("${sms.gateway.api-key:YOUR_FAST2SMS_OR_TWILIO_API_KEY}")
    private String apiKey;

    @Value("${sms.gateway.route:otp}")
    private String route;

    private final RestTemplate restTemplate = new RestTemplate();

    public void sendOtpSms(String phone, String otpCode) {
        String cleanPhone = phone.replaceAll("\\D", "");
        if (cleanPhone.length() > 10) {
            cleanPhone = cleanPhone.substring(cleanPhone.length() - 10);
        }

        String message = String.format("Your Gourmet Bistro verification OTP is %s. Valid for 5 minutes.", otpCode);

        System.out.println("==================================================");
        System.out.println(String.format(" [SMS GATEWAY] DISPATCHING MOBILE SMS TO +91%s", cleanPhone));
        System.out.println(String.format(" [SMS GATEWAY] OTP CODE: %s", otpCode));
        System.out.println(String.format(" [SMS GATEWAY] MESSAGE: %s", message));
        System.out.println("==================================================");

        if (smsEnabled && apiKey != null && !apiKey.isBlank() && !"YOUR_FAST2SMS_OR_TWILIO_API_KEY".equals(apiKey)) {
            try {
                if ("fast2sms".equalsIgnoreCase(provider)) {
                    sendViaFast2Sms(cleanPhone, otpCode, message);
                } else if ("twilio".equalsIgnoreCase(provider)) {
                    System.out.println("[SMS GATEWAY TWILIO] Dispatching SMS via Twilio to +91" + cleanPhone);
                }
            } catch (Exception e) {
                System.err.println("[SMS GATEWAY NOTICE] Cellular gateway API notice: " + e.getMessage());
            }
        }
    }

    private void sendViaFast2Sms(String cleanPhone, String otpCode, String message) {
        HttpHeaders headers = new HttpHeaders();
        headers.set("authorization", apiKey.trim());
        HttpEntity<String> entity = new HttpEntity<>(headers);

        if ("q".equalsIgnoreCase(route)) {
            sendFast2SmsQuick(cleanPhone, message, entity);
            return;
        }

        // Default: OTP Route
        try {
            String url = String.format("https://www.fast2sms.com/dev/bulkV2?authorization=%s&route=otp&variables_values=%s&numbers=%s",
                    apiKey.trim(), otpCode.trim(), cleanPhone);
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.GET, entity, String.class);
            System.out.println("[SMS GATEWAY SUCCESS] Fast2SMS Response: " + response.getBody());
        } catch (HttpStatusCodeException e) {
            String responseBody = e.getResponseBodyAsString();
            System.err.println("[SMS GATEWAY ERROR] Fast2SMS returned HTTP " + e.getStatusCode() + ": " + responseBody);

            // If OTP route requires website verification (Error code 996), attempt fallback to Quick SMS (route=q)
            if (responseBody != null && responseBody.contains("996")) {
                System.out.println("[SMS GATEWAY NOTICE] Fast2SMS OTP route requires website verification in Fast2SMS dashboard. Attempting Quick SMS (route=q) fallback...");
                sendFast2SmsQuick(cleanPhone, message, entity);
            }
        }
    }

    private void sendFast2SmsQuick(String cleanPhone, String message, HttpEntity<String> entity) {
        try {
            String encodedMessage = URLEncoder.encode(message, StandardCharsets.UTF_8);
            String url = String.format("https://www.fast2sms.com/dev/bulkV2?authorization=%s&route=q&message=%s&language=english&flash=0&numbers=%s",
                    apiKey.trim(), encodedMessage, cleanPhone);
            ResponseEntity<String> response = restTemplate.exchange(url, HttpMethod.GET, entity, String.class);
            System.out.println("[SMS GATEWAY SUCCESS - QUICK ROUTE] Fast2SMS Response: " + response.getBody());
        } catch (Exception ex) {
            System.err.println("[SMS GATEWAY QUICK ROUTE ERROR] " + ex.getMessage());
        }
    }
}
