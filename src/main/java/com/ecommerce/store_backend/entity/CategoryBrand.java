package com.ecommerce.store_backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Table(name = "category_brands")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@IdClass(CategoryBrandId.class)
public class CategoryBrand {

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private Category category;

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "brand_id")
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private Brand brand;

    @Column(name = "product_count")
    private Integer productCount;

    @Column(name = "last_updated")
    private LocalDateTime lastUpdated;
}
