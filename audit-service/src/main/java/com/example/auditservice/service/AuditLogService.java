package com.example.auditservice.service;

import com.example.auditservice.model.AuditLog;
import org.springframework.stereotype.Service;

import java.util.Collection;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class AuditLogService {

    private final Map<String, AuditLog> logStore = new ConcurrentHashMap<>();

    public Collection<AuditLog> getAllLogs() {
        return logStore.values();
    }

    public void saveLog(AuditLog log) {
        if (log.getId() == null) {
            log.setId(String.valueOf(System.currentTimeMillis()));
        }
        logStore.put(log.getId(), log);
    }
}
