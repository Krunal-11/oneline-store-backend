package com.ecommerce.store_backend.entity;

import lombok.*;
import java.io.Serializable;
import java.time.LocalDate;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProductViewId implements Serializable {
    private UUID product;
    private LocalDate viewedAt;
}
