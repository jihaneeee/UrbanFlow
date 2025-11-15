package com.example.ticket_service.dto;

import com.example.ticket_service.domain.TicketStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TicketResponse {

    private Long id;
    private String userId;
    private Long routeId;
    private String origin;
    private String destination;
    private LocalDateTime departureTime;
    private LocalDateTime arrivalTime;
    private BigDecimal price;
    private TicketStatus status;
    private String seatNumber;
    private LocalDateTime purchaseDate;
    private LocalDateTime validUntil;
    private String qrCode;
}
