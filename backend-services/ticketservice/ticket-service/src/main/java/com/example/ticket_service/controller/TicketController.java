package com.example.ticket_service.controller;

import com.example.ticket_service.dto.TicketRequest;
import com.example.ticket_service.dto.TicketResponse;
import com.example.ticket_service.service.TicketService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/tickets")
@RequiredArgsConstructor
@Slf4j
public class TicketController {

    private final TicketService ticketService;

    @PostMapping
    public ResponseEntity<TicketResponse> createTicket(@Valid @RequestBody TicketRequest request) {
        log.info("POST /api/tickets - Creating new ticket");
        TicketResponse response = ticketService.createTicket(request);
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @GetMapping("/{id}")
    public ResponseEntity<TicketResponse> getTicketById(@PathVariable Long id) {
        log.info("GET /api/tickets/{} - Fetching ticket", id);
        TicketResponse response = ticketService.getTicketById(id);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/user/{userId}")
    public ResponseEntity<List<TicketResponse>> getUserTickets(@PathVariable String userId) {
        log.info("GET /api/tickets/user/{} - Fetching user tickets", userId);
        List<TicketResponse> tickets = ticketService.getTicketsByUserId(userId);
        return ResponseEntity.ok(tickets);
    }

    @GetMapping("/user/{userId}/upcoming")
    public ResponseEntity<List<TicketResponse>> getUpcomingTickets(@PathVariable String userId) {
        log.info("GET /api/tickets/user/{}/upcoming - Fetching upcoming tickets", userId);
        List<TicketResponse> tickets = ticketService.getUpcomingTickets(userId);
        return ResponseEntity.ok(tickets);
    }

    @GetMapping("/user/{userId}/active")
    public ResponseEntity<List<TicketResponse>> getActiveTickets(@PathVariable String userId) {
        log.info("GET /api/tickets/user/{}/active - Fetching active tickets", userId);
        List<TicketResponse> tickets = ticketService.getActiveTickets(userId);
        return ResponseEntity.ok(tickets);
    }

    @PutMapping("/{id}/cancel")
    public ResponseEntity<TicketResponse> cancelTicket(
            @PathVariable Long id,
            @RequestParam String userId) {
        log.info("PUT /api/tickets/{}/cancel - Cancelling ticket for user: {}", id, userId);
        TicketResponse response = ticketService.cancelTicket(id, userId);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}/use")
    public ResponseEntity<TicketResponse> useTicket(
            @PathVariable Long id,
            @RequestParam String userId) {
        log.info("PUT /api/tickets/{}/use - Using ticket for user: {}", id, userId);
        TicketResponse response = ticketService.useTicket(id, userId);
        return ResponseEntity.ok(response);
    }
}
