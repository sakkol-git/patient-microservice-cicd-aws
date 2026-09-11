package com.example.patientservice.controller;

import com.example.patientservice.model.Patient;
import com.example.patientservice.service.AuditService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Collection;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@RestController
@RequestMapping("/patients")
public class PatientController {

    private final Map<String, Patient> patientStore = new ConcurrentHashMap<>();
    private final AuditService auditService;

    public PatientController(AuditService auditService) {
        this.auditService = auditService;
    }

    @GetMapping
    public Collection<Patient> getAllPatients() {
        return patientStore.values();
    }

    @PostMapping
    public ResponseEntity<Patient> createPatient(@RequestBody Patient patient) {
        if (patient.getId() == null || patient.getId().isEmpty()) {
            patient.setId(String.valueOf(System.currentTimeMillis()));
        }
        patientStore.put(patient.getId(), patient);

        // Async fire-and-forget — does NOT block the HTTP response
        auditService.logEvent("Created patient: " + patient.getName());

        return ResponseEntity.status(201).body(patient);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Patient> getPatientById(@PathVariable String id) {
        Patient patient = patientStore.get(id);
        if (patient == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(patient);
    }

    @PutMapping("/{id}")
    public ResponseEntity<Patient> updatePatient(@PathVariable String id, @RequestBody Patient updated) {
        Patient existing = patientStore.get(id);
        if (existing == null) {
            return ResponseEntity.notFound().build();
        }
        existing.setName(updated.getName());
        existing.setDiagnosis(updated.getDiagnosis());
        patientStore.put(id, existing);

        auditService.logEvent("Updated patient: " + existing.getName() + " (ID: " + id + ")");
        return ResponseEntity.ok(existing);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePatient(@PathVariable String id) {
        Patient removed = patientStore.remove(id);
        if (removed == null) {
            return ResponseEntity.notFound().build();
        }

        auditService.logEvent("Deleted patient: " + removed.getName() + " (ID: " + id + ")");
        return ResponseEntity.noContent().build();
    }
}

