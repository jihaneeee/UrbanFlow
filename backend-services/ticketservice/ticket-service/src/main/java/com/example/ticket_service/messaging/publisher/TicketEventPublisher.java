package com.example.ticket_service.messaging.publisher;

import com.example.ticket_service.config.RabbitMQConfig;
import com.example.ticket_service.messaging.event.TicketCancelledEvent;
import com.example.ticket_service.messaging.event.TicketCreatedEvent;
import com.example.ticket_service.messaging.event.TicketUsedEvent;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
@Slf4j
public class TicketEventPublisher {

    private final RabbitTemplate rabbitTemplate;

    public void publishTicketCreated(TicketCreatedEvent event) {
        try {
            log.info("Publishing ticket created event for ticket ID: {}", event.getTicketId());
            rabbitTemplate.convertAndSend(
                    RabbitMQConfig.TICKET_EXCHANGE,
                    RabbitMQConfig.TICKET_CREATED_KEY,
                    event
            );
            log.info("Successfully published ticket created event for ticket ID: {}", event.getTicketId());
        } catch (Exception e) {
            log.error("Failed to publish ticket created event for ticket ID: {}", event.getTicketId(), e);
            throw new RuntimeException("Failed to publish ticket created event", e);
        }
    }

    public void publishTicketCancelled(TicketCancelledEvent event) {
        try {
            log.info("Publishing ticket cancelled event for ticket ID: {}", event.getTicketId());
            rabbitTemplate.convertAndSend(
                    RabbitMQConfig.TICKET_EXCHANGE,
                    RabbitMQConfig.TICKET_CANCELLED_KEY,
                    event
            );
            log.info("Successfully published ticket cancelled event for ticket ID: {}", event.getTicketId());
        } catch (Exception e) {
            log.error("Failed to publish ticket cancelled event for ticket ID: {}", event.getTicketId(), e);
            throw new RuntimeException("Failed to publish ticket cancelled event", e);
        }
    }

    public void publishTicketUsed(TicketUsedEvent event) {
        try {
            log.info("Publishing ticket used event for ticket ID: {}", event.getTicketId());
            rabbitTemplate.convertAndSend(
                    RabbitMQConfig.TICKET_EXCHANGE,
                    RabbitMQConfig.TICKET_USED_KEY,
                    event
            );
            log.info("Successfully published ticket used event for ticket ID: {}", event.getTicketId());
        } catch (Exception e) {
            log.error("Failed to publish ticket used event for ticket ID: {}", event.getTicketId(), e);
            throw new RuntimeException("Failed to publish ticket used event", e);
        }
    }
}
