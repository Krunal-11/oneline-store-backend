package com.ecommerce.store_backend.repository;

import com.ecommerce.store_backend.entity.ProductGroup;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ProductGroupRepository extends JpaRepository<ProductGroup, UUID> {
    List<ProductGroup> findByCategoryId(UUID categoryId);
    List<ProductGroup> findByBrandId(UUID brandId);
    ProductGroup findBySlug(String slug);
}
