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
public class RouteCancelledEvent {

    private Long routeId;
    private String routeName;
    private LocalDateTime departureTime;
    private String cancellationReason;
    private String eventType = "ROUTE_CANCELLED";
    private LocalDateTime eventTimestamp;
}
