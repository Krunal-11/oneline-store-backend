package com.ecommerce.store_backend.repository;


import com.ecommerce.store_backend.entity.Brand;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface BrandRepository extends JpaRepository<Brand, UUID> {
    Brand findBySlug(String slug);
}
