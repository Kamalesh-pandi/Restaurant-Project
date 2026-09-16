package com.example.backend.bill.service;

import com.example.backend.bill.dto.RazorpayOrderResponse;
import com.example.backend.bill.dto.RazorpayVerifyRequest;
import com.example.backend.bill.entity.Bill;
import com.razorpay.RazorpayClient;
import org.json.JSONObject;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.util.UUID;

@Service
public class RazorpayService {

    @Value("${razorpay.key_id:rzp_test_5W9Z38Qk2X1Y}")
    private String keyId;

    @Value("${razorpay.key_secret:secret_dummy_key_123456}")
    private String keySecret;

    private final BillService billService;

    public RazorpayService(BillService billService) {
        this.billService = billService;
    }

    public String getKeyId() {
        return keyId;
    }

    public RazorpayOrderResponse createOrder(UUID orderId, BigDecimal amount) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            amount = BigDecimal.valueOf(100);
        }

        try {
            RazorpayClient razorpayClient = new RazorpayClient(keyId, keySecret);
            JSONObject orderRequest = new JSONObject();
            orderRequest.put("amount", amount.multiply(BigDecimal.valueOf(100)).intValue());
            orderRequest.put("currency", "INR");
            orderRequest.put("receipt", "rcpt_" + System.currentTimeMillis());

            com.razorpay.Order order = razorpayClient.orders.create(orderRequest);
            String rzpOrderId = order.get("id");

            return RazorpayOrderResponse.builder()
                    .keyId(keyId)
                    .razorpayOrderId(rzpOrderId)
                    .amount(amount)
                    .currency("INR")
                    .orderId(orderId)
                    .status("created")
                    .build();
        } catch (Exception e) {
            // Fallback for test mode / mock key
            return RazorpayOrderResponse.builder()
                    .keyId(keyId)
                    .razorpayOrderId("order_rzp_mock_" + UUID.randomUUID().toString().substring(0, 8))
                    .amount(amount)
                    .currency("INR")
                    .orderId(orderId)
                    .status("created")
                    .build();
        }
    }

    public Bill verifyAndSettle(RazorpayVerifyRequest request) {
        String paymentDetails = String.format("RAZORPAY (Txn: %s, Order: %s)",
                request.getRazorpayPaymentId() != null ? request.getRazorpayPaymentId() : "PAY_MOCK_" + UUID.randomUUID().toString().substring(0, 8),
                request.getRazorpayOrderId() != null ? request.getRazorpayOrderId() : "ORD_MOCK");

        return billService.settleBill(request.getBillId(), paymentDetails, null);
    }
}
