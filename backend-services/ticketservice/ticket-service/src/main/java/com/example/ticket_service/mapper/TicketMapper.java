package com.example.ticket_service.mapper;

import com.example.ticket_service.domain.Ticket;
import com.example.ticket_service.dto.TicketRequest;
import com.example.ticket_service.dto.TicketResponse;
import org.springframework.stereotype.Component;

@Component
public class TicketMapper {

    public Ticket toEntity(TicketRequest request) {
        return Ticket.builder()
                .userId(request.getUserId())
                .routeId(request.getRouteId())
                .origin(request.getOrigin())
                .destination(request.getDestination())
                .departureTime(request.getDepartureTime())
                .arrivalTime(request.getArrivalTime())
                .price(request.getPrice())
                .seatNumber(request.getSeatNumber())
                .build();
    }

    public TicketResponse toResponse(Ticket ticket) {
        return TicketResponse.builder()
                .id(ticket.getId())
                .userId(ticket.getUserId())
                .routeId(ticket.getRouteId())
                .origin(ticket.getOrigin())
                .destination(ticket.getDestination())
                .departureTime(ticket.getDepartureTime())
                .arrivalTime(ticket.getArrivalTime())
                .price(ticket.getPrice())
                .status(ticket.getStatus())
                .seatNumber(ticket.getSeatNumber())
                .purchaseDate(ticket.getPurchaseDate())
                .validUntil(ticket.getValidUntil())
                .qrCode(ticket.getQrCode())
                .build();
    }
}
