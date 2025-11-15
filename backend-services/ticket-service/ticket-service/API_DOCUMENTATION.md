# Ticket Service API

A clean, production-ready Spring Boot microservice for managing public transport tickets in the UrbanFlow system.

## Architecture

### Clean Code Principles
- **Separation of Concerns**: Clear layering (Controller → Service → Repository)
- **Single Responsibility**: Each class has one well-defined purpose
- **DRY**: No code duplication, shared components via mapper
- **SOLID Principles**: Dependency injection, interface contracts, proper abstraction
- **Immutable DTOs**: Using Lombok builders for consistency
- **Comprehensive Error Handling**: Global exception handler for all error scenarios

### Technology Stack
- **Spring Boot 3.5.7** (Java 17)
- **PostgreSQL 15** (Database)
- **RabbitMQ 3** (Message Broker)
- **Docker** (Containerization)
- **Hibernate/JPA** (ORM)
- **Lombok** (Boilerplate reduction)
- **Spring Validation** (Input validation)

## Project Structure

```
src/main/java/com/example/ticket_service/
├── config/
│   └── SecurityConfig.java          # Security configuration
├── controller/
│   └── TicketController.java        # REST endpoints
├── domain/
│   ├── Ticket.java                  # Entity model
│   └── TicketStatus.java            # Enum for ticket states
├── dto/
│   ├── TicketRequest.java           # Input DTO
│   └── TicketResponse.java          # Output DTO
├── exception/
│   ├── ErrorResponse.java           # Error response model
│   ├── GlobalExceptionHandler.java  # Centralized error handling
│   ├── ResourceNotFoundException.java
│   └── SeatAlreadyBookedException.java
├── mapper/
│   └── TicketMapper.java            # Entity ↔ DTO conversion
├── repository/
│   └── TicketRepository.java        # Database operations
└── service/
    └── TicketService.java           # Business logic
```

## Domain Model

### Ticket Entity
```java
{
  "id": 1,
  "userId": "user123",
  "routeId": 5,
  "origin": "Downtown Station",
  "destination": "Airport Terminal",
  "departureTime": "2025-11-16T14:30:00",
  "arrivalTime": "2025-11-16T15:15:00",
  "price": 12.50,
  "status": "ACTIVE",
  "seatNumber": "A12",
  "purchaseDate": "2025-11-15T19:45:09",
  "validUntil": "2025-11-16T15:30:00",
  "qrCode": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Ticket Status
- `ACTIVE` - Ready to use
- `USED` - Already consumed
- `EXPIRED` - Past validity period
- `CANCELLED` - Cancelled by user
- `REFUNDED` - Refunded to user

## API Endpoints

### Create Ticket
```http
POST /api/tickets
Content-Type: application/json

{
  "userId": "user123",
  "routeId": 5,
  "origin": "Downtown Station",
  "destination": "Airport Terminal",
  "departureTime": "2025-11-16T14:30:00",
  "arrivalTime": "2025-11-16T15:15:00",
  "price": 12.50,
  "seatNumber": "A12"
}
```

**Response:** `201 Created`
```json
{
  "id": 1,
  "userId": "user123",
  "routeId": 5,
  "origin": "Downtown Station",
  "destination": "Airport Terminal",
  "departureTime": "2025-11-16T14:30:00",
  "arrivalTime": "2025-11-16T15:15:00",
  "price": 12.50,
  "status": "ACTIVE",
  "seatNumber": "A12",
  "purchaseDate": "2025-11-15T19:45:09",
  "validUntil": "2025-11-16T15:30:00",
  "qrCode": "550e8400-e29b-41d4-a716-446655440000"
}
```

### Get Ticket by ID
```http
GET /api/tickets/{id}
```

**Response:** `200 OK`

### Get All Tickets for User
```http
GET /api/tickets/user/{userId}
```

**Response:** `200 OK` (Array of tickets)

### Get Upcoming Tickets
```http
GET /api/tickets/user/{userId}/upcoming
```

Returns only tickets with future departure times.

**Response:** `200 OK` (Array of upcoming tickets)

### Get Active Tickets
```http
GET /api/tickets/user/{userId}/active
```

Returns only tickets with `ACTIVE` status.

**Response:** `200 OK` (Array of active tickets)

### Cancel Ticket
```http
PUT /api/tickets/{id}/cancel?userId=user123
```

**Response:** `200 OK` (Updated ticket with `CANCELLED` status)

### Use Ticket
```http
PUT /api/tickets/{id}/use?userId=user123
```

Marks ticket as used. Validates:
- Ticket is `ACTIVE`
- Ticket has not expired

**Response:** `200 OK` (Updated ticket with `USED` status)

## Error Handling

### Validation Errors (400 Bad Request)
```json
{
  "timestamp": "2025-11-15T19:45:09",
  "status": 400,
  "error": "Validation Failed",
  "errors": {
    "userId": "User ID is required",
    "price": "Price must be positive"
  }
}
```

### Resource Not Found (404)
```json
{
  "timestamp": "2025-11-15T19:45:09",
  "status": 404,
  "error": "Not Found",
  "message": "Ticket not found with ID: 999"
}
```

### Seat Already Booked (409 Conflict)
```json
{
  "timestamp": "2025-11-15T19:45:09",
  "status": 409,
  "error": "Conflict",
  "message": "Seat A12 is already booked for this route"
}
```

### Business Logic Error (400)
```json
{
  "timestamp": "2025-11-15T19:45:09",
  "status": 400,
  "error": "Bad Request",
  "message": "Only active tickets can be cancelled"
}
```

## Running the Application

### Prerequisites
- Docker & Docker Compose
- Java 17 (for local development)
- Maven 3.9+ (for local development)

### Start All Services
```bash
cd backend-services/ticket-service/ticket-service
docker-compose up -d
```

### View Logs
```bash
docker-compose logs -f ticket-service
```

### Stop Services
```bash
docker-compose down
```

### Rebuild After Code Changes
```bash
docker-compose up --build -d
```

## Testing the API

### Using cURL

**Create a ticket:**
```bash
curl -X POST http://localhost:8082/api/tickets \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "user123",
    "routeId": 5,
    "origin": "Downtown",
    "destination": "Airport",
    "departureTime": "2025-11-16T14:30:00",
    "arrivalTime": "2025-11-16T15:15:00",
    "price": 12.50,
    "seatNumber": "A12"
  }'
```

**Get ticket by ID:**
```bash
curl http://localhost:8082/api/tickets/1
```

**Get user tickets:**
```bash
curl http://localhost:8082/api/tickets/user/user123
```

**Cancel ticket:**
```bash
curl -X PUT "http://localhost:8082/api/tickets/1/cancel?userId=user123"
```

### Using PowerShell

**Create a ticket:**
```powershell
$body = @{
    userId = "user123"
    routeId = 5
    origin = "Downtown"
    destination = "Airport"
    departureTime = "2025-11-16T14:30:00"
    arrivalTime = "2025-11-16T15:15:00"
    price = 12.50
    seatNumber = "A12"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:8082/api/tickets" `
    -Method POST `
    -ContentType "application/json" `
    -Body $body
```

**Get ticket:**
```powershell
Invoke-RestMethod -Uri "http://localhost:8082/api/tickets/1" -Method GET
```

## Database Schema

The `tickets` table is automatically created with the following structure:

```sql
CREATE TABLE tickets (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(255) NOT NULL,
    route_id BIGINT NOT NULL,
    origin VARCHAR(255) NOT NULL,
    destination VARCHAR(255) NOT NULL,
    departure_time TIMESTAMP NOT NULL,
    arrival_time TIMESTAMP,
    price DECIMAL(10,2) NOT NULL,
    status VARCHAR(50) NOT NULL,
    seat_number VARCHAR(255) NOT NULL,
    purchase_date TIMESTAMP NOT NULL,
    valid_until TIMESTAMP,
    qr_code VARCHAR(500)
);

CREATE INDEX idx_user_id ON tickets(user_id);
CREATE INDEX idx_route_id ON tickets(route_id);
CREATE INDEX idx_status ON tickets(status);
```

## Service URLs

- **Application:** http://localhost:8082
- **Health Check:** http://localhost:8082/actuator/health
- **PostgreSQL:** localhost:5433 (postgres/postgres123)
- **RabbitMQ Management:** http://localhost:15672 (guest/guest)

## Best Practices Implemented

1. **DTO Pattern**: Separate request/response models from entities
2. **Mapper Pattern**: Clean conversion between layers
3. **Repository Pattern**: Abstraction over data access
4. **Service Layer**: Business logic isolation
5. **Exception Handling**: Centralized with proper HTTP status codes
6. **Validation**: Bean validation annotations
7. **Logging**: SLF4J with structured logging
8. **Transactions**: `@Transactional` for data consistency
9. **Builder Pattern**: Lombok builders for object creation
10. **Immutability**: Final fields where appropriate

## Code Quality Features

- ✅ Clean separation of concerns
- ✅ SOLID principles
- ✅ Comprehensive validation
- ✅ Proper error handling
- ✅ Transactional integrity
- ✅ Database indexing for performance
- ✅ Seat booking conflict prevention
- ✅ Automatic expiration handling
- ✅ Structured logging
- ✅ Docker-ready configuration

## Future Enhancements

- [ ] Add pagination for list endpoints
- [ ] Implement ticket refund logic
- [ ] Add RabbitMQ event publishing for ticket lifecycle
- [ ] Implement QR code generation library
- [ ] Add scheduled job for automatic expiration
- [ ] Integrate with user service for validation
- [ ] Integrate with route service for validation
- [ ] Add metrics and monitoring
- [ ] Implement caching for frequently accessed tickets
- [ ] Add integration tests with Testcontainers

## License

Copyright © 2025 UrbanFlow
