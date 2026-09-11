package com.example.auditservice.controller;

import com.example.auditservice.model.AuditLog;
import com.example.auditservice.service.AuditLogService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.Collection;

@RestController
@RequestMapping("/logs")
public class AuditController {

    private final AuditLogService auditLogService;

    public AuditController(AuditLogService auditLogService) {
        this.auditLogService = auditLogService;
    }

    @GetMapping
    public Collection<AuditLog> getAllLogs() {
        return auditLogService.getAllLogs();
    }

    @PostMapping
    public ResponseEntity<AuditLog> createLog(@RequestBody AuditLog log) {
        auditLogService.saveLog(log);
        return ResponseEntity.status(201).body(log);
    }
}
