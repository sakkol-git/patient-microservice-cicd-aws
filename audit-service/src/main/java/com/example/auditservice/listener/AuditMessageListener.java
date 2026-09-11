package com.example.auditservice.listener;

import com.example.auditservice.model.AuditLog;
import com.example.auditservice.service.AuditLogService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
public class AuditMessageListener {

    private static final Logger log = LoggerFactory.getLogger(AuditMessageListener.class);
    private final AuditLogService auditLogService;

    public AuditMessageListener(AuditLogService auditLogService) {
        this.auditLogService = auditLogService;
    }

    @RabbitListener(queues = "${rabbitmq.queue.audit}")
    public void receiveAuditMessage(AuditLog auditLog) {
        if (auditLog.getTimestamp() == null) {
            auditLog.setTimestamp(LocalDateTime.now().toString());
        }
        auditLogService.saveLog(auditLog);
        log.info("Received and saved audit log from RabbitMQ: action={}", auditLog.getAction());
    }
}
