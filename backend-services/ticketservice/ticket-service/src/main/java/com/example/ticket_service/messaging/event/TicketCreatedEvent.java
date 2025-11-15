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
public class TicketCreatedEvent {

    private Long ticketId;
    private String userId;
    private Long routeId;
    private String origin;
    private String destination;
    private LocalDateTime departureTime;
    private LocalDateTime arrivalTime;
    private BigDecimal price;
    private String seatNumber;
    private LocalDateTime purchaseDate;
    private String eventType = "TICKET_CREATED";
    private LocalDateTime eventTimestamp;
}
