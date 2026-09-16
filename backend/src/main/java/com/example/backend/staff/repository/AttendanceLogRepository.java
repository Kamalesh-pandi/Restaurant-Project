package com.example.backend.staff.repository;

import com.example.backend.staff.entity.AttendanceLog;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface AttendanceLogRepository extends JpaRepository<AttendanceLog, UUID> {
    List<AttendanceLog> findByStaffId(UUID staffId);
    Optional<AttendanceLog> findFirstByStaffIdAndClockOutIsNullOrderByClockInDesc(UUID staffId);
}
