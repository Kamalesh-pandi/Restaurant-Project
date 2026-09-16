package com.example.backend.bill.controller;

import com.example.backend.bill.dto.*;
import com.example.backend.bill.entity.Bill;
import com.example.backend.bill.service.BillService;
import com.example.backend.report.entity.DayEndReport;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1")
public class BillController {

    private final BillService billService;
    private final com.example.backend.bill.service.RazorpayService razorpayService;

    public BillController(BillService billService, com.example.backend.bill.service.RazorpayService razorpayService) {
        this.billService = billService;
        this.razorpayService = razorpayService;
    }

    @GetMapping("/bills")
    public ResponseEntity<List<Bill>> getAllBills() {
        return ResponseEntity.ok(billService.getAllBills());
    }

    @GetMapping("/bills/{id}")
    public ResponseEntity<Bill> getBillById(@PathVariable UUID id) {
        return ResponseEntity.ok(billService.getBillById(id));
    }

    @PostMapping("/bills")
    @PreAuthorize("hasAnyRole('CASHIER', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Bill> generateBill(@RequestParam UUID orderId,
                                             @RequestParam(defaultValue = "0") BigDecimal discountAmount,
                                             @RequestParam(required = false) String customerPhone,
                                             @RequestParam(defaultValue = "0") Integer pointsToRedeem,
                                             @RequestParam(required = false) String managerPin) {
        Bill bill = billService.generateBill(orderId, discountAmount, customerPhone, pointsToRedeem, managerPin);
        return ResponseEntity.status(HttpStatus.CREATED).body(bill);
    }

    @PostMapping("/bills/{id}/settle")
    public ResponseEntity<Bill> settleBill(@PathVariable UUID id,
                                           @RequestBody String paymentMethodJson,
                                           @RequestParam(required = false) String customerPhone) {
        return ResponseEntity.ok(billService.settleBill(id, paymentMethodJson, customerPhone));
    }

    @PostMapping("/bills/{id}/settle-split")
    @PreAuthorize("hasAnyRole('CASHIER', 'MANAGER', 'ADMIN')")
    public ResponseEntity<Bill> settleBillSplit(@PathVariable UUID id,
                                                @RequestBody SettleBillRequest request) {
        return ResponseEntity.ok(billService.settleBillSplit(id, request));
    }

    @PostMapping("/bills/split/equal")
    @PreAuthorize("hasAnyRole('CASHIER', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<Bill>> splitBillEqually(@RequestParam UUID orderId,
                                                       @RequestParam int numGuests,
                                                       @RequestParam(required = false) String managerPin) {
        return ResponseEntity.ok(billService.splitBillEqually(orderId, numGuests, managerPin));
    }

    @PostMapping("/bills/split/items")
    @PreAuthorize("hasAnyRole('CASHIER', 'MANAGER', 'ADMIN')")
    public ResponseEntity<List<Bill>> splitBillByItems(@RequestParam UUID orderId,
                                                       @RequestBody SplitBillByItemsRequest request) {
        return ResponseEntity.ok(billService.splitBillByItems(orderId, request.getItemGroups(), request.getManagerPin()));
    }

    @GetMapping("/bills/{id}/receipt")
    @PreAuthorize("hasAnyRole('CASHIER', 'MANAGER', 'ADMIN')")
    public ResponseEntity<String> getReceiptText(@PathVariable UUID id) {
        return ResponseEntity.ok(billService.getReceiptText(id));
    }

    @PostMapping({"/bills/{id}/send-digital", "/bills/{id}/digital-receipt"})
    @PreAuthorize("hasAnyRole('CASHIER', 'MANAGER', 'ADMIN')")
    public ResponseEntity<String> sendDigitalReceipt(@PathVariable UUID id,
                                                     @RequestParam String phoneNumber) {
        return ResponseEntity.ok(billService.sendDigitalReceipt(id, phoneNumber));
    }

    @PostMapping("/bills/{id}/print")
    @PreAuthorize("hasAnyRole('CASHIER', 'MANAGER', 'ADMIN')")
    public ResponseEntity<String> printBill(@PathVariable UUID id) {
        return ResponseEntity.ok(billService.getReceiptText(id));
    }

    @GetMapping("/payments/razorpay/key")
    @PreAuthorize("hasAnyRole('CASHIER', 'MANAGER', 'ADMIN')")
    public ResponseEntity<String> getRazorpayKey() {
        return ResponseEntity.ok(razorpayService.getKeyId());
    }

    @PostMapping("/payments/razorpay/create-order")
    public ResponseEntity<RazorpayOrderResponse> createRazorpayOrder(@RequestParam UUID orderId, @RequestParam BigDecimal amount) {
        return ResponseEntity.ok(razorpayService.createOrder(orderId, amount));
    }

    @PostMapping("/payments/razorpay/verify")
    public ResponseEntity<Bill> verifyRazorpayPayment(@RequestBody RazorpayVerifyRequest request) {
        return ResponseEntity.ok(razorpayService.verifyAndSettle(request));
    }

    @PostMapping("/payments/razorpay")
    public ResponseEntity<String> initiateRazorpayPayment(@RequestParam UUID orderId, @RequestParam BigDecimal amount) {
        return ResponseEntity.ok("Razorpay payment initiated for order " + orderId + " of amount " + amount);
    }

    @PostMapping("/bills/{id}/void")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<Bill> voidBill(@PathVariable UUID id, @RequestParam String managerPin) {
        return ResponseEntity.ok(billService.voidBill(id, managerPin));
    }

    @GetMapping("/reports/z-report")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<DayEndReport> getZReport(@RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
                                                   @RequestParam UUID managerId) {
        return ResponseEntity.ok(billService.generateZReport(date, managerId));
    }

    @GetMapping("/reports/cash-drawer-reconciliation")
    @PreAuthorize("hasAnyRole('MANAGER', 'ADMIN')")
    public ResponseEntity<CashDrawerReconciliation> reconcileCashDrawer(@RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
                                                                        @RequestParam BigDecimal startingCash) {
        return ResponseEntity.ok(billService.reconcileCashDrawer(date, startingCash));
    }
}
