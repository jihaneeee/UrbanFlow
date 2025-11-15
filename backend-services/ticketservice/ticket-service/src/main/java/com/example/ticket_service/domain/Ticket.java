package com.example.ticket_service.domain;

import jakarta.persistence.*;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "tickets")
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class Ticket {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @NotBlank(message = "User ID is required")
    @Column(nullable = false)
    private String userId;

    @NotNull(message = "Route ID is required")
    @Column(nullable = false)
    private Long routeId;

    @NotBlank(message = "Origin is required")
    @Column(nullable = false)
    private String origin;

    @NotBlank(message = "Destination is required")
    @Column(nullable = false)
    private String destination;

    @NotNull(message = "Departure time is required")
    @Column(nullable = false)
    private LocalDateTime departureTime;

    @Column
    private LocalDateTime arrivalTime;

    @NotNull(message = "Price is required")
    @Positive(message = "Price must be positive")
    @Column(nullable = false, precision = 10, scale = 2)
    private BigDecimal price;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private TicketStatus status = TicketStatus.ACTIVE;

    @NotBlank(message = "Seat number is required")
    @Column(nullable = false)
    private String seatNumber;

    @Column(nullable = false, updatable = false)
    private LocalDateTime purchaseDate;

    @Column
    private LocalDateTime validUntil;

    @Column(length = 500)
    private String qrCode;

    @PrePersist
    protected void onCreate() {
        purchaseDate = LocalDateTime.now();
        if (validUntil == null && departureTime != null) {
            validUntil = departureTime.plusHours(1);
        }
    }
}
