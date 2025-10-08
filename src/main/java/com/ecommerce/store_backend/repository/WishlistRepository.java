package com.ecommerce.store_backend.repository;

import com.ecommerce.store_backend.entity.Wishlist;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface WishlistRepository extends JpaRepository<Wishlist, UUID> {
    List<Wishlist> findByUserId(UUID userId);
    List<Wishlist> findBySessionId(String sessionId);
}
