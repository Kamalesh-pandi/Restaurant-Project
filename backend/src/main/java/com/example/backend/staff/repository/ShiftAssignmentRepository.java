package com.example.backend.staff.repository;

import com.example.backend.staff.entity.ShiftAssignment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Repository
public interface ShiftAssignmentRepository extends JpaRepository<ShiftAssignment, UUID> {
    List<ShiftAssignment> findByStaffIdAndAssignmentDate(UUID staffId, LocalDate date);
    List<ShiftAssignment> findByStaffId(UUID staffId);
}
