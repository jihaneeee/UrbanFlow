package com.example.ticket_service.messaging.consumer;

import com.example.ticket_service.config.RabbitMQConfig;
import com.example.ticket_service.domain.Ticket;
import com.example.ticket_service.domain.TicketStatus;
import com.example.ticket_service.messaging.event.PaymentCompletedEvent;
import com.example.ticket_service.messaging.event.RouteCancelledEvent;
import com.example.ticket_service.messaging.event.TicketCancelledEvent;
import com.example.ticket_service.messaging.publisher.TicketEventPublisher;
import com.example.ticket_service.repository.TicketRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.annotation.RabbitListener;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class TicketEventConsumer {

    private final TicketRepository ticketRepository;
    private final TicketEventPublisher ticketEventPublisher;

    /**
     * Listens for payment completion events from Payment Service
     * Updates ticket status when payment is successful
     */
    @RabbitListener(queues = RabbitMQConfig.TICKET_PAYMENT_QUEUE)
    @Transactional
    public void handlePaymentCompleted(PaymentCompletedEvent event) {
        try {
            log.info("Received payment completed event for ticket ID: {}, status: {}", 
                    event.getTicketId(), event.getStatus());

            Ticket ticket = ticketRepository.findById(event.getTicketId())
                    .orElseThrow(() -> new RuntimeException("Ticket not found: " + event.getTicketId()));

            if ("SUCCESS".equals(event.getStatus())) {
                ticket.setStatus(TicketStatus.ACTIVE);
                ticketRepository.save(ticket);
                log.info("Ticket {} activated after successful payment", event.getTicketId());
            } else {
                ticket.setStatus(TicketStatus.CANCELLED);
                ticketRepository.save(ticket);
                log.warn("Ticket {} cancelled due to payment failure", event.getTicketId());
            }

        } catch (Exception e) {
            log.error("Error processing payment completed event for ticket: {}", event.getTicketId(), e);
            throw e; // Trigger retry mechanism
        }
    }

    /**
     * Listens for route cancellation events from Route Service
     * Auto-cancels all tickets for the cancelled route
     */
    @RabbitListener(queues = RabbitMQConfig.TICKET_ROUTE_QUEUE)
    @Transactional
    public void handleRouteCancelled(RouteCancelledEvent event) {
        try {
            log.info("Received route cancelled event for route ID: {}, reason: {}", 
                    event.getRouteId(), event.getCancellationReason());

            // Find all active tickets for this route
            List<Ticket> activeTickets = ticketRepository.findByRouteId(event.getRouteId())
                    .stream()
                    .filter(ticket -> ticket.getStatus() == TicketStatus.ACTIVE)
                    .toList();

            log.info("Found {} active tickets to cancel for route {}", activeTickets.size(), event.getRouteId());

            // Cancel each ticket and publish cancellation event
            for (Ticket ticket : activeTickets) {
                ticket.setStatus(TicketStatus.CANCELLED);
                ticketRepository.save(ticket);

                // Publish cancellation event for refund processing
                TicketCancelledEvent cancelledEvent = TicketCancelledEvent.builder()
                        .ticketId(ticket.getId())
                        .userId(ticket.getUserId())
                        .routeId(ticket.getRouteId())
                        .refundAmount(ticket.getPrice())
                        .seatNumber(ticket.getSeatNumber())
                        .departureTime(ticket.getDepartureTime())
                        .cancellationReason("Route cancelled: " + event.getCancellationReason())
                        .eventTimestamp(LocalDateTime.now())
                        .build();

                ticketEventPublisher.publishTicketCancelled(cancelledEvent);
            }

            log.info("Successfully cancelled {} tickets for route {}", activeTickets.size(), event.getRouteId());

        } catch (Exception e) {
            log.error("Error processing route cancelled event for route: {}", event.getRouteId(), e);
            throw e; // Trigger retry mechanism
        }
    }
}
