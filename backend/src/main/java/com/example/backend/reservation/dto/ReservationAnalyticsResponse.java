package com.example.backend.reservation.dto;

import java.util.List;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReservationAnalyticsResponse {
    private long totalBookings;
    private long completedBookings;
    private long noShowCount;
    private long cancelledCount;
    private double bookingConversionRate;
    private double noShowRate;
    private List<String> peakBookingTimes;
}
