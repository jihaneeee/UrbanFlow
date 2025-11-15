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
public class PaymentCompletedEvent {

    private Long paymentId;
    private Long ticketId;
    private String userId;
    private BigDecimal amount;
    private String paymentMethod;
    private String transactionId;
    private String status; // SUCCESS, FAILED
    private String eventType = "PAYMENT_COMPLETED";
    private LocalDateTime eventTimestamp;
}
