# RabbitMQ Messaging Architecture - UrbanFlow Ticket Service

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      URBANFLOW MICROSERVICES                             │
└─────────────────────────────────────────────────────────────────────────┘

    ┌──────────────┐         ┌──────────────┐         ┌──────────────┐
    │ User Service │         │Route Service │         │Vehicle Svc   │
    │  Port 8081   │         │  Port 8083   │         │ Port 8084    │
    └──────┬───────┘         └──────┬───────┘         └──────┬───────┘
           │                        │                        │
           │ User Events            │ Route Events           │ Vehicle Events
           │                        │                        │
           └────────────────────────┼────────────────────────┘
                                    │
                     ┌──────────────▼──────────────┐
                     │   RabbitMQ Message Broker   │
                     │   ┌─────────────────────┐   │
                     │   │  Topic Exchanges    │   │
                     │   │  ├─ ticket.events   │   │
                     │   │  ├─ payment.events  │   │
                     │   │  └─ route.events    │   │
                     │   └─────────────────────┘   │
                     │   ┌─────────────────────┐   │
                     │   │   Message Queues    │   │
                     │   │  ├─ payment.queue   │   │
                     │   │  ├─ notification.q  │   │
                     │   │  ├─ analytics.q     │   │
                     │   │  └─ refund.queue    │   │
                     │   └─────────────────────┘   │
                     └─────────────────────────────┘
                                    │
           ┌────────────────────────┼────────────────────────┐
           │                        │                        │
    ┌──────▼───────┐       ┌───────▼────────┐     ┌────────▼────────┐
    │Ticket Service│       │Payment Service │     │ Notification    │
    │  Port 8082   │       │  Port 8085     │     │ Service         │
    │              │       │                │     │ Port 8086       │
    │ PRODUCER +   │       │ CONSUMER +     │     │ CONSUMER        │
    │ CONSUMER     │       │ PRODUCER       │     │                 │
    └──────────────┘       └────────────────┘     └─────────────────┘
```

## Message Flow Workflows

### 1. Ticket Purchase Flow (Complete End-to-End)

```
┌─────┐                ┌─────────┐               ┌──────────┐
│User │                │ Ticket  │               │RabbitMQ  │
│     │                │ Service │               │          │
└──┬──┘                └────┬────┘               └────┬─────┘
   │                        │                         │
   │ POST /api/tickets      │                         │
   │───────────────────────>│                         │
   │                        │                         │
   │                        │ 1. Save to DB           │
   │                        │    (status: ACTIVE)     │
   │                        │─────────┐               │
   │                        │         │               │
   │                        │<────────┘               │
   │                        │                         │
   │                        │ 2. Publish              │
   │                        │    TicketCreatedEvent   │
   │                        │────────────────────────>│
   │                        │                         │
   │  201 Created           │                         │ 3. Route to queues:
   │<───────────────────────│                         │    ├─ payment.queue
   │  {ticketId: 1}         │                         │    ├─ notification.queue
   │                        │                         │    └─ analytics.queue
   │                        │                         │
   │                        │                         │
                            │                         │
                   ┌────────▼────────┐                │
                   │ Payment Service │                │
                   │                 │                │
                   └────────┬────────┘                │
                            │                         │
                            │ 4. Consume from         │
                            │    payment.queue        │
                            │<────────────────────────│
                            │                         │
                            │ 5. Process payment      │
                            │    (Stripe/PayPal)      │
                            │─────────┐               │
                            │         │               │
                            │<────────┘               │
                            │                         │
                            │ 6. Publish              │
                            │    PaymentCompletedEvent│
                            │────────────────────────>│
                            │                         │
                            │                         │ 7. Route to
                            │                         │    ticket.payment.queue
   │                        │                         │
   │                        │ 8. Consume from         │
   │                        │    ticket.payment.queue │
   │                        │<────────────────────────│
   │                        │                         │
   │                        │ 9. Update status        │
   │                        │    Generate QR code     │
   │                        │─────────┐               │
   │                        │         │               │
   │                        │<────────┘               │
   │                        │                         │
```

### 2. Ticket Cancellation Flow

```
┌─────┐                ┌─────────┐               ┌──────────┐
│User │                │ Ticket  │               │RabbitMQ  │
│     │                │ Service │               │          │
└──┬──┘                └────┬────┘               └────┬─────┘
   │                        │                         │
   │ PUT /tickets/1/cancel  │                         │
   │───────────────────────>│                         │
   │                        │                         │
   │                        │ 1. Update status        │
   │                        │    (CANCELLED)          │
   │                        │─────────┐               │
   │                        │         │               │
   │                        │<────────┘               │
   │                        │                         │
   │                        │ 2. Publish              │
   │                        │    TicketCancelledEvent │
   │                        │────────────────────────>│
   │                        │                         │
   │  200 OK                │                         │ 3. Route to:
   │<───────────────────────│                         │    ├─ refund.queue
   │  {status: CANCELLED}   │                         │    └─ notification.queue
   │                        │                         │
   │                        │                         │
                            │                         │
                   ┌────────▼────────┐                │
                   │ Payment Service │                │
                   │                 │                │
                   └────────┬────────┘                │
                            │                         │
                            │ 4. Consume from         │
                            │    refund.queue         │
                            │<────────────────────────│
                            │                         │
                            │ 5. Process refund       │
                            │    to user wallet       │
                            │─────────┐               │
                            │         │               │
                            │<────────┘               │
                            │                         │
```

### 3. Route Cancellation (Auto-Cancel Tickets)

```
┌───────────┐         ┌─────────┐            ┌──────────┐
│   Route   │         │ Ticket  │            │RabbitMQ  │
│  Service  │         │ Service │            │          │
└─────┬─────┘         └────┬────┘            └────┬─────┘
      │                    │                      │
      │ Route cancelled    │                      │
      │ (weather/strike)   │                      │
      │                    │                      │
      │ 1. Publish         │                      │
      │    RouteCancelledEvent                    │
      │────────────────────────────────────────────>
      │                    │                      │
      │                    │                      │ 2. Route to
      │                    │                      │    ticket.route.queue
      │                    │                      │
      │                    │ 3. Consume from      │
      │                    │    ticket.route.queue│
      │                    │<─────────────────────│
      │                    │                      │
      │                    │ 4. Find all tickets  │
      │                    │    for routeId       │
      │                    │─────────┐            │
      │                    │         │            │
      │                    │<────────┘            │
      │                    │                      │
      │                    │ 5. Cancel each       │
      │                    │    ticket (loop)     │
      │                    │─────────┐            │
      │                    │         │            │
      │                    │<────────┘            │
      │                    │                      │
      │                    │ 6. Publish           │
      │                    │    TicketCancelledEvent
      │                    │    (for each ticket) │
      │                    │─────────────────────>│
      │                    │                      │
      │                    │                      │ 7. Route to
      │                    │                      │    refund.queue +
      │                    │                      │    notification.queue
```

### 4. Ticket Usage Flow (Scan at Gate)

```
┌────────┐            ┌─────────┐               ┌──────────┐
│Scanner │            │ Ticket  │               │RabbitMQ  │
│Device  │            │ Service │               │          │
└───┬────┘            └────┬────┘               └────┬─────┘
    │                      │                         │
    │ PUT /tickets/1/use   │                         │
    │─────────────────────>│                         │
    │                      │                         │
    │                      │ 1. Validate ticket      │
    │                      │    - Check status       │
    │                      │    - Check expiry       │
    │                      │─────────┐               │
    │                      │         │               │
    │                      │<────────┘               │
    │                      │                         │
    │                      │ 2. Update status (USED) │
    │                      │─────────┐               │
    │                      │         │               │
    │                      │<────────┘               │
    │                      │                         │
    │                      │ 3. Publish              │
    │                      │    TicketUsedEvent      │
    │                      │────────────────────────>│
    │                      │                         │
    │  200 OK              │                         │ 4. Route to
    │<─────────────────────│                         │    analytics.queue
    │  {status: USED}      │                         │
    │                      │                         │
```

## Exchange and Queue Configuration

### Exchanges

| Exchange Name    | Type  | Purpose                                    |
|-----------------|-------|-------------------------------------------|
| `ticket.events` | Topic | Ticket lifecycle events (created, cancelled, used) |
| `payment.events`| Topic | Payment processing events                  |
| `route.events`  | Topic | Route management events                    |

### Queues (Ticket Service Publishes To)

| Queue Name                  | Exchange        | Routing Key         | Consumer Service    |
|----------------------------|-----------------|---------------------|---------------------|
| `payment.ticket.created`   | ticket.events   | ticket.created      | Payment Service     |
| `notification.ticket.events`| ticket.events   | ticket.*            | Notification Service|
| `analytics.ticket.events`  | ticket.events   | ticket.*            | Analytics Service   |
| `refund.ticket.cancelled`  | ticket.events   | ticket.cancelled    | Payment Service     |

### Queues (Ticket Service Consumes From)

| Queue Name                 | Exchange        | Routing Key          | Purpose                        |
|---------------------------|-----------------|----------------------|--------------------------------|
| `ticket.payment.completed`| payment.events  | payment.completed    | Activate ticket after payment  |
| `ticket.route.cancelled`  | route.events    | route.cancelled      | Auto-cancel tickets for route  |

## Event DTOs

### TicketCreatedEvent
```json
{
  "ticketId": 1,
  "userId": "user123",
  "routeId": 5,
  "origin": "Downtown Station",
  "destination": "Airport Terminal",
  "departureTime": "2025-11-16T14:30:00",
  "arrivalTime": "2025-11-16T15:15:00",
  "price": 12.50,
  "seatNumber": "A12",
  "purchaseDate": "2025-11-15T20:26:17",
  "eventType": "TICKET_CREATED",
  "eventTimestamp": "2025-11-15T20:26:17"
}
```

### TicketCancelledEvent
```json
{
  "ticketId": 1,
  "userId": "user123",
  "routeId": 5,
  "refundAmount": 12.50,
  "seatNumber": "A12",
  "departureTime": "2025-11-16T14:30:00",
  "cancellationReason": "User requested cancellation",
  "eventType": "TICKET_CANCELLED",
  "eventTimestamp": "2025-11-15T20:30:00"
}
```

### TicketUsedEvent
```json
{
  "ticketId": 1,
  "userId": "user123",
  "routeId": 5,
  "seatNumber": "A12",
  "usedAt": "2025-11-16T14:25:00",
  "scanLocation": "Gate Scan",
  "eventType": "TICKET_USED",
  "eventTimestamp": "2025-11-16T14:25:00"
}
```

### PaymentCompletedEvent (Consumed)
```json
{
  "paymentId": 101,
  "ticketId": 1,
  "userId": "user123",
  "amount": 12.50,
  "paymentMethod": "CREDIT_CARD",
  "transactionId": "txn_123456",
  "status": "SUCCESS",
  "eventType": "PAYMENT_COMPLETED",
  "eventTimestamp": "2025-11-15T20:26:30"
}
```

### RouteCancelledEvent (Consumed)
```json
{
  "routeId": 5,
  "routeName": "Downtown to Airport",
  "departureTime": "2025-11-16T14:30:00",
  "cancellationReason": "Weather conditions",
  "eventType": "ROUTE_CANCELLED",
  "eventTimestamp": "2025-11-16T10:00:00"
}
```

## Code Structure

```
ticket-service/
├── config/
│   ├── RabbitMQConfig.java           # Exchanges, queues, bindings
│   └── SecurityConfig.java
├── messaging/
│   ├── event/                        # Event DTOs
│   │   ├── TicketCreatedEvent.java
│   │   ├── TicketCancelledEvent.java
│   │   ├── TicketUsedEvent.java
│   │   ├── PaymentCompletedEvent.java
│   │   └── RouteCancelledEvent.java
│   ├── publisher/
│   │   └── TicketEventPublisher.java # Publishes events to RabbitMQ
│   └── consumer/
│       └── TicketEventConsumer.java  # Consumes events from RabbitMQ
├── service/
│   └── TicketService.java            # Business logic + event publishing
└── controller/
    └── TicketController.java         # REST endpoints
```

## Testing RabbitMQ Integration

### 1. Check RabbitMQ Management Console
```
URL: http://localhost:15672
Username: guest
Password: guest
```

Navigate to:
- **Exchanges** tab → Verify `ticket.events`, `payment.events`, `route.events` exist
- **Queues** tab → Verify all queues are created and bound
- **Connections** tab → Verify ticket-service is connected

### 2. Test Ticket Creation (Produces Event)
```powershell
$body = @{
    userId = "user123"
    routeId = 5
    origin = "Downtown"
    destination = "Airport"
    departureTime = "2025-11-16T14:30:00"
    price = 12.50
    seatNumber = "A12"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8082/api/tickets" `
    -Method POST `
    -ContentType "application/json" `
    -Body $body
```

**Expected Result:**
- Ticket created in database
- Event published to `ticket.events` exchange
- Message routed to `payment.queue`, `notification.queue`, `analytics.queue`

### 3. Check Queue in RabbitMQ Console
- Go to Queues → `payment.ticket.created`
- Click "Get Messages"
- You should see the `TicketCreatedEvent` JSON

### 4. Simulate Payment Completion (Consumer)
Manually publish to `payment.events` exchange:

```bash
# In RabbitMQ Management Console → Exchanges → payment.events
# Click "Publish message"
Routing key: payment.completed
Payload:
{
  "paymentId": 101,
  "ticketId": 1,
  "userId": "user123",
  "amount": 12.50,
  "status": "SUCCESS",
  "eventTimestamp": "2025-11-15T20:30:00"
}
```

**Expected Result:**
- Ticket status updated to ACTIVE in database
- Consumer logs in ticket-service

### 5. Simulate Route Cancellation (Consumer)
```bash
# In RabbitMQ Management Console → Exchanges → route.events
# Click "Publish message"
Routing key: route.cancelled
Payload:
{
  "routeId": 5,
  "routeName": "Downtown to Airport",
  "cancellationReason": "Weather",
  "eventTimestamp": "2025-11-16T10:00:00"
}
```

**Expected Result:**
- All tickets for routeId=5 cancelled automatically
- Refund events published for each ticket

## Benefits of This Architecture

1. **Loose Coupling**: Services don't directly call each other
2. **Async Processing**: Non-blocking operations
3. **Scalability**: Multiple consumers can process messages in parallel
4. **Reliability**: Messages persist in queues if consumer is down
5. **Event-Driven**: Real-time notifications across services
6. **Fault Tolerance**: Failed messages can be retried
7. **Audit Trail**: All events are logged and traceable

## Next Steps: Implementing Other Services

To complete the microservices architecture, you need to implement:

1. **Payment Service** (Port 8085)
   - Consumer: `payment.ticket.created` queue
   - Producer: `payment.events` exchange

2. **Notification Service** (Port 8086)
   - Consumer: `notification.ticket.events` queue
   - Sends: Email, SMS, Push notifications

3. **Route Service** (Port 8083)
   - Producer: `route.events` exchange
   - Manages route cancellations

4. **Analytics Service** (Port 8087)
   - Consumer: `analytics.ticket.events` queue
   - Tracks metrics and usage patterns
