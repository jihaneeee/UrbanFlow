# Ticket Service Architecture Guide

## 🎯 Overview

The Ticket Service is a microservice responsible for managing bus tickets in the UrbanFlow transportation system. It handles ticket creation, cancellation, validation, and communicates with other services through RabbitMQ message queues.

## 📐 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         TICKET SERVICE                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐      │
│  │              │      │              │      │              │      │
│  │  Controller  │─────▶│   Service    │─────▶│  Repository  │      │
│  │    Layer     │      │    Layer     │      │    Layer     │      │
│  │              │      │              │      │              │      │
│  └──────────────┘      └──────┬───────┘      └──────┬───────┘      │
│                               │                      │              │
│                               │                      ▼              │
│                               │              ┌──────────────┐       │
│                               │              │              │       │
│                               │              │   Database   │       │
│                               │              │  (Postgres)  │       │
│                               │              │              │       │
│                               │              └──────────────┘       │
│                               │                                     │
│                               ▼                                     │
│                    ┌──────────────────┐                             │
│                    │                  │                             │
│                    │  Event Publisher │                             │
│                    │   & Consumer     │                             │
│                    │                  │                             │
│                    └────────┬─────────┘                             │
│                             │                                       │
└─────────────────────────────┼───────────────────────────────────────┘
                              │
                              │
                              ▼
                    ┌──────────────────┐
                    │                  │
                    │    RabbitMQ      │
                    │   Message Broker │
                    │                  │
                    └────────┬─────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
  │              │   │              │   │              │
  │   Payment    │   │    Route     │   │ Notification │
  │   Service    │   │   Service    │   │   Service    │
  │              │   │              │   │              │
  └──────────────┘   └──────────────┘   └──────────────┘
```

## 🏗️ Component Architecture

### 1. **Controller Layer** (`TicketController`)
**What it does:** The front door of the service - receives HTTP requests from users or other services.

**Responsibilities:**
- Exposes REST API endpoints
- Validates incoming requests
- Returns HTTP responses

**Key Endpoints:**
- `POST /api/tickets` - Create a new ticket
- `GET /api/tickets/{id}` - Get ticket by ID
- `GET /api/tickets/user/{userId}` - Get all user's tickets
- `PUT /api/tickets/{id}/cancel` - Cancel a ticket
- `PUT /api/tickets/{id}/use` - Mark ticket as used

### 2. **Service Layer** (`TicketService`)
**What it does:** The brain of the service - contains all business logic.

**Responsibilities:**
- Validates business rules (e.g., "Can't cancel a used ticket")
- Processes ticket operations
- Coordinates with repository and event publishers
- Handles transactions

**Key Operations:**
- Create ticket → Publish "Ticket Created" event
- Cancel ticket → Publish "Ticket Cancelled" event
- Use ticket → Publish "Ticket Used" event

### 3. **Repository Layer** (`TicketRepository`)
**What it does:** Talks to the database.

**Responsibilities:**
- Save and retrieve tickets from PostgreSQL
- Execute custom queries (find by user, find expired tickets, etc.)
- Manage data persistence

### 4. **Messaging Layer** (RabbitMQ Integration)

This is where the magic happens! The service talks to other microservices through RabbitMQ.

#### **Event Publisher** (`TicketEventPublisher`)
Sends messages to other services when something important happens.

#### **Event Consumer** (`TicketEventConsumer`)
Listens for messages from other services and reacts to them.

## 🐰 RabbitMQ Workflow Explained (For Beginners)

### What is RabbitMQ?
Think of RabbitMQ as a **post office** for microservices. Instead of services talking to each other directly, they send messages through this post office.

### Key Concepts:

1. **Exchange** = A sorting office that receives messages and routes them
2. **Queue** = A mailbox where messages wait to be read
3. **Routing Key** = The address on an envelope that tells the exchange where to send the message
4. **Binding** = Connects an exchange to a queue with routing rules

### Message Flow Architecture

```
                    TICKET SERVICE PUBLISHING EVENTS
                                  │
                                  │
                                  ▼
                        ┌──────────────────┐
                        │                  │
                        │ ticket.events    │◄────── Exchange
                        │   (Exchange)     │
                        │                  │
                        └────────┬─────────┘
                                 │
          ┌──────────────────────┼──────────────────────┐
          │                      │                      │
          │ ticket.created       │ ticket.cancelled     │ ticket.used
          │                      │                      │
          ▼                      ▼                      ▼
    ┌──────────┐          ┌──────────┐          ┌──────────┐
    │ payment. │          │ refund.  │          │analytics.│
    │  ticket. │          │ ticket.  │          │ ticket.  │
    │  created │          │cancelled │          │  events  │
    │  (Queue) │          │  (Queue) │          │  (Queue) │
    └────┬─────┘          └────┬─────┘          └────┬─────┘
         │                     │                     │
         ▼                     ▼                     ▼
    ┌─────────┐          ┌─────────┐          ┌─────────┐
    │ Payment │          │ Refund  │          │Analytics│
    │ Service │          │ Service │          │ Service │
    └─────────┘          └─────────┘          └─────────┘
```

```
                 OTHER SERVICES PUBLISHING EVENTS
                                  │
          ┌───────────────────────┴───────────────────────┐
          │                                               │
          ▼                                               ▼
 ┌──────────────────┐                          ┌──────────────────┐
 │ payment.events   │                          │  route.events    │
 │   (Exchange)     │                          │   (Exchange)     │
 └────────┬─────────┘                          └────────┬─────────┘
          │                                               │
          │ payment.completed                             │ route.cancelled
          │                                               │
          ▼                                               ▼
    ┌──────────┐                                   ┌──────────┐
    │ ticket.  │                                   │ ticket.  │
    │ payment. │                                   │  route.  │
    │completed │                                   │cancelled │
    │  (Queue) │                                   │  (Queue) │
    └────┬─────┘                                   └────┬─────┘
         │                                               │
         └───────────────────┬───────────────────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ TICKET SERVICE  │
                    │    (Consumer)   │
                    └─────────────────┘
```

## 📨 Event Flow Examples

### Example 1: Creating a Ticket

**User Journey:**
1. User books a ticket through the mobile app
2. API Gateway routes request to Ticket Service
3. Ticket Service creates ticket in database
4. Ticket Service publishes "Ticket Created" event

**Event Flow:**
```
┌──────────┐  1. POST /tickets   ┌────────────────┐
│   User   │────────────────────▶│ Ticket Service │
│   App    │                     │                │
└──────────┘                     └───────┬────────┘
                                         │
                                         │ 2. Save to DB
                                         │
                                         ▼
                                  ┌──────────────┐
                                  │   Database   │
                                  └──────────────┘
                                         │
                                         │ 3. Publish Event
                                         │
                                         ▼
                                  ┌──────────────┐
                                  │   RabbitMQ   │
                                  │              │
                                  │ ticket.events│
                                  └──────┬───────┘
                                         │
                      ┌──────────────────┼──────────────────┐
                      │                  │                  │
                      ▼                  ▼                  ▼
              ┌──────────────┐   ┌─────────────┐   ┌─────────────┐
              │   Payment    │   │Notification │   │  Analytics  │
              │   Service    │   │   Service   │   │   Service   │
              └──────────────┘   └─────────────┘   └─────────────┘
              
              4. Process        5. Send email    6. Record stats
                 payment           to user
```

**Code Path:**
```java
TicketController.createTicket()
    └─▶ TicketService.createTicket()
        ├─▶ TicketRepository.save() // Save to database
        └─▶ publishTicketCreatedEvent()
            └─▶ TicketEventPublisher.publishTicketCreated()
                └─▶ RabbitTemplate.convertAndSend(
                        "ticket.events",        // Exchange
                        "ticket.created",       // Routing Key
                        event                   // Message
                    )
```

**Published Event Data:**
```json
{
  "ticketId": 123,
  "userId": "user-456",
  "routeId": "route-789",
  "origin": "Downtown",
  "destination": "Airport",
  "departureTime": "2025-11-16T14:00:00",
  "arrivalTime": "2025-11-16T15:30:00",
  "price": 15.50,
  "seatNumber": "A12",
  "purchaseDate": "2025-11-16T10:00:00",
  "eventTimestamp": "2025-11-16T10:00:05"
}
```

**Who Receives This Event:**
- ✅ **Payment Service** → Creates payment transaction
- ✅ **Notification Service** → Sends booking confirmation email
- ✅ **Analytics Service** → Records booking statistics

### Example 2: Payment Completed (Incoming Event)

**Scenario:** Payment Service successfully processes payment

**Event Flow:**
```
┌──────────────┐  1. Payment     ┌──────────────┐
│   Payment    │    Success      │   RabbitMQ   │
│   Service    │────────────────▶│              │
└──────────────┘                 │payment.events│
                                 └──────┬───────┘
                                        │
                                        │ payment.completed
                                        │
                                        ▼
                                ┌────────────────┐
                                │ ticket.payment.│
                                │   completed    │
                                │    (Queue)     │
                                └───────┬────────┘
                                        │
                                        │ 2. Consume
                                        │
                                        ▼
                                ┌────────────────┐
                                │ Ticket Service │
                                │   (Consumer)   │
                                └───────┬────────┘
                                        │
                                        │ 3. Update Ticket
                                        │    Status: ACTIVE
                                        │
                                        ▼
                                ┌────────────────┐
                                │   Database     │
                                └────────────────┘
```

**Code Path:**
```java
@RabbitListener(queues = "ticket.payment.completed")
TicketEventConsumer.handlePaymentCompleted(PaymentCompletedEvent)
    └─▶ Find ticket by ID
    └─▶ If payment SUCCESS: ticket.setStatus(ACTIVE)
    └─▶ If payment FAILED: ticket.setStatus(CANCELLED)
    └─▶ TicketRepository.save()
```

**Incoming Event Data:**
```json
{
  "ticketId": 123,
  "paymentId": "pay-xyz",
  "status": "SUCCESS",
  "amount": 15.50,
  "paymentMethod": "CREDIT_CARD",
  "processedAt": "2025-11-16T10:01:30"
}
```

### Example 3: Route Cancelled (Incoming Event)

**Scenario:** A bus route is cancelled (e.g., due to weather)

**Event Flow:**
```
┌──────────────┐  1. Route       ┌──────────────┐
│    Route     │   Cancelled     │   RabbitMQ   │
│   Service    │────────────────▶│              │
└──────────────┘                 │ route.events │
                                 └──────┬───────┘
                                        │
                                        │ route.cancelled
                                        │
                                        ▼
                                ┌────────────────┐
                                │ ticket.route.  │
                                │   cancelled    │
                                │    (Queue)     │
                                └───────┬────────┘
                                        │
                                        │ 2. Consume
                                        │
                                        ▼
                                ┌────────────────┐
                                │ Ticket Service │
                                │   (Consumer)   │
                                └───────┬────────┘
                                        │
                                        │ 3. Find all active
                                        │    tickets for route
                                        │
                                        ▼
                                ┌────────────────┐
                                │   Database     │
                                └───────┬────────┘
                                        │
                                        │ 4. Cancel each ticket
                                        │
                                        ▼
                                ┌────────────────┐
                                │   RabbitMQ     │
                                │                │
                                │ ticket.events  │
                                └───────┬────────┘
                                        │
                                        │ ticket.cancelled
                                        │
                                        ▼
                                ┌────────────────┐
                                │ Refund Service │
                                │                │
                                │ 5. Process     │
                                │    Refunds     │
                                └────────────────┘
```

**Code Path:**
```java
@RabbitListener(queues = "ticket.route.cancelled")
TicketEventConsumer.handleRouteCancelled(RouteCancelledEvent)
    └─▶ Find all active tickets for route
    └─▶ For each ticket:
        ├─▶ ticket.setStatus(CANCELLED)
        ├─▶ TicketRepository.save()
        └─▶ publishTicketCancelledEvent()
            └─▶ Triggers refund processing
```

## 🔄 Complete Ticket Lifecycle

```
1. PENDING (Initial State)
   │
   │ User creates ticket
   │ Event: ticket.created
   │
   ▼
2. PENDING (Waiting for Payment)
   │
   │ Payment Service processes
   │ Event: payment.completed
   │
   ├─▶ SUCCESS ──▶ 3. ACTIVE (Ready to use)
   │                  │
   │                  │ User scans ticket
   │                  │ Event: ticket.used
   │                  │
   │                  ▼
   │               4. USED (Journey completed)
   │
   └─▶ FAILED ───▶ 5. CANCELLED
                     │
                     │ OR User cancels
                     │ Event: ticket.cancelled
                     │
                     │ OR Route cancelled
                     │ Event: route.cancelled
                     │
                     ▼
                  6. REFUNDED
```

## 📋 RabbitMQ Configuration Details

### Exchanges
```
ticket.events   → Where Ticket Service publishes events
payment.events  → Where Payment Service publishes events
route.events    → Where Route Service publishes events
```

### Queues (Ticket Service Publishes To)
```
payment.ticket.created      → Payment Service listens here
notification.ticket.events  → Notification Service listens here
analytics.ticket.events     → Analytics Service listens here
refund.ticket.cancelled     → Refund Service listens here
```

### Queues (Ticket Service Consumes From)
```
ticket.payment.completed → Payment completion notifications
ticket.route.cancelled   → Route cancellation notifications
```

### Routing Keys
```
ticket.created      → New ticket created
ticket.cancelled    → Ticket cancelled
ticket.used         → Ticket used/scanned
payment.completed   → Payment processed
route.cancelled     → Route cancelled
```

## 🛡️ Error Handling & Resilience

### Transaction Management
- Database operations are wrapped in transactions
- If event publishing fails, database changes still commit
- Events are logged but don't break the main flow

### Retry Mechanism
- RabbitMQ automatically retries failed message consumption
- Dead Letter Queues handle permanently failed messages
- Circuit breakers prevent cascading failures

### Message TTL (Time To Live)
- Payment queue messages expire after 1 hour
- Prevents old messages from being processed

## 🗄️ Database Schema

### Ticket Table
```sql
CREATE TABLE tickets (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    route_id VARCHAR(255) NOT NULL,
    origin VARCHAR(255) NOT NULL,
    destination VARCHAR(255) NOT NULL,
    departure_time TIMESTAMP NOT NULL,
    arrival_time TIMESTAMP NOT NULL,
    seat_number VARCHAR(10) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL,
    qr_code VARCHAR(255) UNIQUE,
    purchase_date TIMESTAMP NOT NULL,
    valid_until TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_user_id ON tickets(user_id);
CREATE INDEX idx_route_id ON tickets(route_id);
CREATE INDEX idx_status ON tickets(status);
CREATE INDEX idx_departure_time ON tickets(departure_time);
```

## 🔐 Security

- **Authentication:** Spring Security with JWT tokens
- **Authorization:** Role-based access control
- **Data Validation:** Jakarta Validation annotations
- **SQL Injection Prevention:** JPA/Hibernate parameterized queries

## 🚀 Deployment

### Docker Setup
```yaml
services:
  ticket-service:
    image: ticket-service:latest
    environment:
      - SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/ticket_db
      - SPRING_RABBITMQ_HOST=rabbitmq
      - SPRING_RABBITMQ_PORT=5672
    ports:
      - "8080:8080"
    depends_on:
      - postgres
      - rabbitmq

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=ticket_db
      - POSTGRES_USER=ticketuser
      - POSTGRES_PASSWORD=ticketpass

  rabbitmq:
    image: rabbitmq:3.12-management
    ports:
      - "5672:5672"
      - "15672:15672"
```

## 📊 Monitoring & Observability

### Key Metrics to Monitor
- **Ticket Creation Rate:** Tickets/minute
- **Event Publishing Success Rate:** %
- **Message Queue Depth:** Number of pending messages
- **Database Response Time:** Milliseconds
- **API Response Time:** Milliseconds

### Logging
- Structured logging with SLF4J and Logback
- Log levels: INFO for business events, ERROR for failures
- Correlation IDs for request tracing

## Summary

1. **Microservices** = Small, independent services that work together
2. **RabbitMQ** = Message broker that lets services communicate asynchronously
3. **Events** = Notifications that something important happened
4. **Publisher** = Service that sends messages
5. **Consumer** = Service that receives and processes messages
6. **Asynchronous** = Services don't wait for each other; they send messages and continue working

**Why This Architecture?**
- ✅ **Scalability:** Each service can scale independently
- ✅ **Reliability:** If one service fails, others keep working
- ✅ **Maintainability:** Easy to update one service without affecting others
- ✅ **Flexibility:** Easy to add new services that listen to existing events


