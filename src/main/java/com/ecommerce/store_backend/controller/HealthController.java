package com.ecommerce.store_backend.controller;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/api/public")
public class HealthController {

    private static final Logger logger = LoggerFactory.getLogger(HealthController.class);

    @GetMapping("/health")
    public Map<String, Object> health() {
        logger.debug("Health endpoint accessed at {}", LocalDateTime.now());
        logger.info("Returning health status");

        return Map.of(
                "status", "UP",
                "timestamp", LocalDateTime.now(),
                "message", "E-commerce Store Backend is running"
        );
    }
}
