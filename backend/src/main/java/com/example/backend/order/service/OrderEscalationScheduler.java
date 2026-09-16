package com.example.backend.order.service;

import com.example.backend.order.entity.Order;
import com.example.backend.order.entity.OrderStatus;
import com.example.backend.order.repository.OrderRepository;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.List;

@Component
public class OrderEscalationScheduler {

    private final OrderRepository orderRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public OrderEscalationScheduler(OrderRepository orderRepository, SimpMessagingTemplate messagingTemplate) {
        this.orderRepository = orderRepository;
        this.messagingTemplate = messagingTemplate;
    }

    @Scheduled(cron = "0 * * * * *") // Run every minute
    public void checkForPendingKitchenEscalations() {
        List<Order> activeOrders = orderRepository.findByStatus(OrderStatus.PREPARING);
        LocalDateTime threshold = LocalDateTime.now().minusMinutes(12);

        for (Order order : activeOrders) {
            if (order.getKotFiredAt() != null && order.getKotFiredAt().isBefore(threshold)) {
                String alertMessage = String.format("ORDER ESCALATION: Order %s has been pending kitchen confirmation for over 12 minutes! Fired at: %s",
                        order.getOrderId(), order.getKotFiredAt());
                
                System.out.println(alertMessage);
                
                try {
                    messagingTemplate.convertAndSend("/topic/alerts", alertMessage);
                } catch (Exception e) {
                    // WebSocket template ignore in test environment
                }
            }
        }
    }
}
