package com.ecommerce.store_backend.entity;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "products")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Product {
    @Id
    @GeneratedValue
    @Column(columnDefinition = "UUID")
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_group_id")
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private ProductGroup productGroup;

    @Column(unique = true, length = 100)
    private String sku;

    @Column(name = "variant_name", length = 100)
    private String variantName;

    @Column(name = "mrp")
    private BigDecimal mrp;

    @Column(name = "selling_price")
    private BigDecimal sellingPrice;

    @Column(columnDefinition = "jsonb")
    private String attributes; // Store JSON as String, or use Map<String, Object> with converter

    @Column(name = "status")
    private String status = "ACTIVE";

    @Column(name = "stock_quantity")
    private Integer stockQuantity = 0;

    @Column(name = "is_default_variant")
    private Boolean isDefaultVariant = false;

    @Column(name = "meta_title", length = 200)
    private String metaTitle;

    @Column(name = "meta_description", columnDefinition = "TEXT")
    private String metaDescription;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;
}
