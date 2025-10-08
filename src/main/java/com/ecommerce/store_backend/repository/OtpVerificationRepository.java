package com.ecommerce.store_backend.repository;

import com.ecommerce.store_backend.entity.OtpVerification;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface OtpVerificationRepository extends JpaRepository<OtpVerification, UUID> {
    Optional<OtpVerification> findTopByPhoneAndPurposeOrderByCreatedAtDesc(String phone, String purpose);
}
