package com.example.backend.common.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);

    @Autowired(required = false)
    private JavaMailSender mailSender;

    @org.springframework.beans.factory.annotation.Value("${spring.mail.username:}")
    private String mailFrom;

    /**
     * Send welcome email containing staff member PIN code and credentials.
     */
    public void sendStaffPinEmail(String recipientEmail, String staffName, String rawPin, String role) {
        if (recipientEmail == null || recipientEmail.trim().isEmpty()) {
            log.warn("Cannot send staff PIN email: recipient email is blank for staff {}", staffName);
            return;
        }

        String subject = "Welcome to Spice Haven POS - Your Staff Account Credentials & PIN Code";
        String messageBody = String.format(
            "Hello %s,\n\n" +
            "Welcome to Spice Haven POS! Your staff account has been created with role '%s'.\n\n" +
            "Here are your login credentials:\n" +
            "--------------------------------------------------\n" +
            "Staff Name: %s\n" +
            "Email: %s\n" +
            "Role: %s\n" +
            "Terminal Secret PIN Code: %s\n" +
            "--------------------------------------------------\n\n" +
            "Please use this 4-digit PIN code to log in at POS terminals, access assigned workstations, and clock in for shifts.\n\n" +
            "Best regards,\n" +
            "Spice Haven System Administrator",
            staffName, role, staffName, recipientEmail, role, rawPin
        );

        boolean emailSent = false;
        if (mailSender != null) {
            try {
                SimpleMailMessage message = new SimpleMailMessage();
                if (mailFrom != null && !mailFrom.trim().isEmpty()) {
                    message.setFrom(mailFrom);
                }
                message.setTo(recipientEmail);
                message.setSubject(subject);
                message.setText(messageBody);
                mailSender.send(message);
                emailSent = true;
                log.info("Successfully sent staff PIN email via SMTP to {}", recipientEmail);
            } catch (Exception e) {
                log.error("Failed to send email via SMTP to {}: {}. Falling back to console dispatch log.", recipientEmail, e.getMessage());
            }
        }

        if (!emailSent) {
            // Simulation / Log output for local mail dispatch when SMTP is disabled or unavailable
            log.info("\n========================== EMAIL DISPATCH ==========================\n" +
                     "TO: {}\n" +
                     "SUBJECT: {}\n" +
                     "BODY:\n{}\n" +
                     "====================================================================",
                     recipientEmail, subject, messageBody);
        }
    }
}

