package com.example.ticket_service.messaging.event;

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
public class TicketCancelledEvent {

    private Long ticketId;
    private String userId;
    private Long routeId;
    private BigDecimal refundAmount;
    private String seatNumber;
    private LocalDateTime departureTime;
    private String cancellationReason;
    private String eventType = "TICKET_CANCELLED";
    private LocalDateTime eventTimestamp;
}
