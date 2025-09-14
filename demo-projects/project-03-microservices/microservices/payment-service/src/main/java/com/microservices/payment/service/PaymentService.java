package com.microservices.payment.service;

import com.microservices.payment.model.Payment;
import com.microservices.payment.repository.PaymentRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class PaymentService {
    
    private static final Logger logger = LoggerFactory.getLogger(PaymentService.class);
    
    @Autowired
    private PaymentRepository paymentRepository;
    
    @Autowired
    private RedisTemplate<String, Object> redisTemplate;
    
    @Cacheable(value = "payments", key = "#id")
    public Optional<Payment> findById(Long id) {
        logger.info("Retrieving payment with ID: {}", id);
        return paymentRepository.findById(id);
    }
    
    @Cacheable(value = "payments", key = "'all'")
    public List<Payment> findAll() {
        logger.info("Retrieving all payments");
        return paymentRepository.findAll();
    }
    
    @Cacheable(value = "payments", key = "'user:' + #userId")
    public List<Payment> findByUserId(Long userId) {
        logger.info("Retrieving payments for user ID: {}", userId);
        return paymentRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }
    
    @Cacheable(value = "payments", key = "'order:' + #orderId")
    public List<Payment> findByOrderId(Long orderId) {
        logger.info("Retrieving payments for order ID: {}", orderId);
        return paymentRepository.findByOrderId(orderId);
    }
    
    public Optional<Payment> findByTransactionId(String transactionId) {
        logger.info("Retrieving payment with transaction ID: {}", transactionId);
        return paymentRepository.findByTransactionId(transactionId);
    }
    
    @CacheEvict(value = "payments", allEntries = true)
    public Payment save(Payment payment) {
        logger.info("Saving payment for order ID: {}", payment.getOrderId());
        
        // Generate transaction ID if not provided
        if (payment.getTransactionId() == null || payment.getTransactionId().isEmpty()) {
            payment.setTransactionId(UUID.randomUUID().toString());
        }
        
        // Set default currency if not provided
        if (payment.getCurrency() == null || payment.getCurrency().isEmpty()) {
            payment.setCurrency("USD");
        }
        
        // Set default status if not provided
        if (payment.getStatus() == null || payment.getStatus().isEmpty()) {
            payment.setStatus("pending");
        }
        
        return paymentRepository.save(payment);
    }
    
    @CacheEvict(value = "payments", allEntries = true)
    public Payment update(Payment payment) {
        logger.info("Updating payment with ID: {}", payment.getId());
        return paymentRepository.save(payment);
    }
    
    @CacheEvict(value = "payments", allEntries = true)
    public void deleteById(Long id) {
        logger.info("Deleting payment with ID: {}", id);
        paymentRepository.deleteById(id);
    }
    
    public List<Payment> findByStatus(String status) {
        logger.info("Retrieving payments with status: {}", status);
        return paymentRepository.findByStatus(status);
    }
    
    public Long countByStatus(String status) {
        logger.info("Counting payments with status: {}", status);
        return paymentRepository.countByStatus(status);
    }
    
    public Payment processPayment(Payment payment) {
        logger.info("Processing payment for order ID: {}", payment.getOrderId());
        
        try {
            // Simulate payment processing
            Thread.sleep(1000); // Simulate processing time
            
            // Simulate success/failure based on amount
            if (payment.getAmount() > 1000) {
                payment.setStatus("failed");
                payment.setDescription("Payment failed: Amount too high");
            } else {
                payment.setStatus("completed");
                payment.setDescription("Payment processed successfully");
            }
            
            return save(payment);
            
        } catch (InterruptedException e) {
            logger.error("Payment processing interrupted", e);
            payment.setStatus("failed");
            payment.setDescription("Payment processing interrupted");
            return save(payment);
        } catch (Exception e) {
            logger.error("Payment processing failed", e);
            payment.setStatus("failed");
            payment.setDescription("Payment processing failed: " + e.getMessage());
            return save(payment);
        }
    }
}
