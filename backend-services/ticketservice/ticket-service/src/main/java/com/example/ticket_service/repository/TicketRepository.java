package com.example.ticket_service.repository;

import com.example.ticket_service.domain.Ticket;
import com.example.ticket_service.domain.TicketStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface TicketRepository extends JpaRepository<Ticket, Long> {

    List<Ticket> findByUserId(String userId);

    List<Ticket> findByUserIdAndStatus(String userId, TicketStatus status);

    Optional<Ticket> findByIdAndUserId(Long id, String userId);

    List<Ticket> findByRouteId(Long routeId);

    @Query("SELECT t FROM Ticket t WHERE t.status = :status AND t.validUntil < :now")
    List<Ticket> findExpiredTickets(@Param("status") TicketStatus status, @Param("now") LocalDateTime now);

    @Query("SELECT t FROM Ticket t WHERE t.userId = :userId AND t.departureTime > :now ORDER BY t.departureTime ASC")
    List<Ticket> findUpcomingTicketsByUserId(@Param("userId") String userId, @Param("now") LocalDateTime now);

    boolean existsBySeatNumberAndRouteIdAndDepartureTime(String seatNumber, Long routeId, LocalDateTime departureTime);
}
