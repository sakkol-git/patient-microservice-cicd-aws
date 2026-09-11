package com.example.auditservice.model;

import java.time.LocalDateTime;

public class AuditLog {
    private String id;
    private String action;
    private String timestamp;

    public AuditLog() {}

    public AuditLog(String action) {
        this.id = String.valueOf(System.currentTimeMillis());
        this.action = action;
        this.timestamp = LocalDateTime.now().toString();
    }

    // Getters and Setters
    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getAction() { return action; }
    public void setAction(String action) { this.action = action; }

    public String getTimestamp() { return timestamp; }
    public void setTimestamp(String timestamp) { this.timestamp = timestamp; }
}
