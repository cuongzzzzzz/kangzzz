package com.microservices.payment.controller;

import com.microservices.payment.model.Payment;
import com.microservices.payment.service.PaymentService;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Optional;

@RestController
@RequestMapping("/api/payments")
@CrossOrigin(origins = "*")
public class PaymentController {
    
    private static final Logger logger = LoggerFactory.getLogger(PaymentController.class);
    
    @Autowired
    private PaymentService paymentService;
    
    @GetMapping("/health")
    public ResponseEntity<?> healthCheck() {
        try {
            // Check database connection by counting payments
            paymentService.countByStatus("pending");
            
            return ResponseEntity.ok()
                .body(new HealthResponse("healthy", "payment-service", "1.0.0"));
        } catch (Exception e) {
            logger.error("Health check failed", e);
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(new HealthResponse("unhealthy", "payment-service", "1.0.0", e.getMessage()));
        }
    }
    
    @GetMapping
    public ResponseEntity<List<Payment>> getAllPayments() {
        try {
            List<Payment> payments = paymentService.findAll();
            logger.info("Retrieved {} payments", payments.size());
            return ResponseEntity.ok(payments);
        } catch (Exception e) {
            logger.error("Error retrieving payments", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<Payment> getPaymentById(@PathVariable Long id) {
        try {
            Optional<Payment> payment = paymentService.findById(id);
            if (payment.isPresent()) {
                logger.info("Retrieved payment with ID: {}", id);
                return ResponseEntity.ok(payment.get());
            } else {
                logger.warn("Payment not found with ID: {}", id);
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            logger.error("Error retrieving payment with ID: {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    @GetMapping("/user/{userId}")
    public ResponseEntity<List<Payment>> getPaymentsByUserId(@PathVariable Long userId) {
        try {
            List<Payment> payments = paymentService.findByUserId(userId);
            logger.info("Retrieved {} payments for user ID: {}", payments.size(), userId);
            return ResponseEntity.ok(payments);
        } catch (Exception e) {
            logger.error("Error retrieving payments for user ID: {}", userId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    @GetMapping("/order/{orderId}")
    public ResponseEntity<List<Payment>> getPaymentsByOrderId(@PathVariable Long orderId) {
        try {
            List<Payment> payments = paymentService.findByOrderId(orderId);
            logger.info("Retrieved {} payments for order ID: {}", payments.size(), orderId);
            return ResponseEntity.ok(payments);
        } catch (Exception e) {
            logger.error("Error retrieving payments for order ID: {}", orderId, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    @PostMapping
    public ResponseEntity<Payment> createPayment(@Valid @RequestBody Payment payment) {
        try {
            Payment savedPayment = paymentService.save(payment);
            logger.info("Created payment with ID: {}", savedPayment.getId());
            return ResponseEntity.status(HttpStatus.CREATED).body(savedPayment);
        } catch (Exception e) {
            logger.error("Error creating payment", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    @PostMapping("/process")
    public ResponseEntity<Payment> processPayment(@Valid @RequestBody Payment payment) {
        try {
            Payment processedPayment = paymentService.processPayment(payment);
            logger.info("Processed payment with ID: {}", processedPayment.getId());
            return ResponseEntity.ok(processedPayment);
        } catch (Exception e) {
            logger.error("Error processing payment", e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<Payment> updatePayment(@PathVariable Long id, @Valid @RequestBody Payment payment) {
        try {
            Optional<Payment> existingPayment = paymentService.findById(id);
            if (existingPayment.isPresent()) {
                payment.setId(id);
                Payment updatedPayment = paymentService.update(payment);
                logger.info("Updated payment with ID: {}", id);
                return ResponseEntity.ok(updatedPayment);
            } else {
                logger.warn("Payment not found with ID: {}", id);
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            logger.error("Error updating payment with ID: {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePayment(@PathVariable Long id) {
        try {
            Optional<Payment> existingPayment = paymentService.findById(id);
            if (existingPayment.isPresent()) {
                paymentService.deleteById(id);
                logger.info("Deleted payment with ID: {}", id);
                return ResponseEntity.noContent().build();
            } else {
                logger.warn("Payment not found with ID: {}", id);
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            logger.error("Error deleting payment with ID: {}", id, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    @GetMapping("/status/{status}")
    public ResponseEntity<List<Payment>> getPaymentsByStatus(@PathVariable String status) {
        try {
            List<Payment> payments = paymentService.findByStatus(status);
            logger.info("Retrieved {} payments with status: {}", payments.size(), status);
            return ResponseEntity.ok(payments);
        } catch (Exception e) {
            logger.error("Error retrieving payments with status: {}", status, e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    // Health response class
    private static class HealthResponse {
        private String status;
        private String service;
        private String version;
        private String error;
        
        public HealthResponse(String status, String service, String version) {
            this.status = status;
            this.service = service;
            this.version = version;
        }
        
        public HealthResponse(String status, String service, String version, String error) {
            this.status = status;
            this.service = service;
            this.version = version;
            this.error = error;
        }
        
        // Getters and setters
        public String getStatus() { return status; }
        public void setStatus(String status) { this.status = status; }
        
        public String getService() { return service; }
        public void setService(String service) { this.service = service; }
        
        public String getVersion() { return version; }
        public void setVersion(String version) { this.version = version; }
        
        public String getError() { return error; }
        public void setError(String error) { this.error = error; }
    }
}
