package com.example.ticket_service.messaging.event;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class TicketUsedEvent {

    private Long ticketId;
    private String userId;
    private Long routeId;
    private String seatNumber;
    private LocalDateTime usedAt;
    private String scanLocation;
    private String eventType = "TICKET_USED";
    private LocalDateTime eventTimestamp;
}
