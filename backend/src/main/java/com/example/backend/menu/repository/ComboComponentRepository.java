package com.example.backend.menu.repository;

import com.example.backend.menu.entity.ComboComponent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.UUID;

@Repository
public interface ComboComponentRepository extends JpaRepository<ComboComponent, UUID> {
    List<ComboComponent> findByComboItemId(UUID comboItemId);
}
