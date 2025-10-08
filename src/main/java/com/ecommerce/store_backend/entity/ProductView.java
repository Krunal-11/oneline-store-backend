package com.ecommerce.store_backend.entity;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.util.UUID;

@Entity
@Table(name = "product_views")
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@IdClass(ProductViewId.class)
public class ProductView {

    @Id
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "product_id")
    @ToString.Exclude
    @EqualsAndHashCode.Exclude
    private Product product;

    @Id
    @Column(name = "viewed_at")
    private LocalDate viewedAt;

    @Column(name = "view_count")
    private Integer viewCount = 1;
}
