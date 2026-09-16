package com.example.backend.report.repository;

import com.example.backend.report.entity.DayEndReport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;
import java.time.LocalDate;

@Repository
public interface DayEndReportRepository extends JpaRepository<DayEndReport, UUID> {
    Optional<DayEndReport> findByReportDate(LocalDate reportDate);
}
