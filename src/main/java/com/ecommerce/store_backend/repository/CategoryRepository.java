package com.ecommerce.store_backend.repository;

import com.ecommerce.store_backend.entity.Category;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface CategoryRepository extends JpaRepository<Category, UUID> {
    // Add custom queries if needed, e.g. findBySlug
    Category findBySlug(String slug);
}
