package com.example.backend.chain.repository;

import com.example.backend.chain.entity.Outlet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface OutletRepository extends JpaRepository<Outlet, UUID> {
    List<Outlet> findByBrandId(UUID brandId);
}
