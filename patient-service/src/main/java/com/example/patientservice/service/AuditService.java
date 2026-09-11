package com.example.patientservice.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.Map;

/**
 * Fire-and-forget audit publisher using RabbitMQ.
 */
@Service
public class AuditService {

    private static final Logger log = LoggerFactory.getLogger(AuditService.class);
    
    private final RabbitTemplate rabbitTemplate;

    @Value("${rabbitmq.exchange.audit}")
    private String exchange;

    @Value("${rabbitmq.routingkey.audit}")
    private String routingKey;
    
    public AuditService(RabbitTemplate rabbitTemplate) {
        this.rabbitTemplate = rabbitTemplate;
    }

    public void logEvent(String action) {
        try {
            Map<String, String> payload = Map.of("action", action);
            rabbitTemplate.convertAndSend(exchange, routingKey, payload);
            log.info("Audit event sent to RabbitMQ: {}", action);
        } catch (Exception e) {
            // Fail-safe: audit service being down must never break the patient API
            log.warn("Failed to send audit event to RabbitMQ: {}", e.getMessage());
        }
    }
}
