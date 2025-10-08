package com.ecommerce.store_backend.entity;

import lombok.*;
import java.io.Serializable;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CategoryBrandId implements Serializable {
    private UUID category;
    private UUID brand;
}
