# UrbanFlow 🚌

**Modern Urban Transport Management System - Microservices Architecture**

## 📋 Project Overview

UrbanFlow is a comprehensive urban transport management system built with a microservices architecture (SOA). The system enables:
- 🕒 Real-time bus schedule consultation
- 🎫 Online ticket purchasing
- 📍 Live bus tracking via GPS
- 📅 Subscription management
- 🔔 Real-time notifications for delays/cancellations

---

## 🏗️ Architecture

### Microservices
1. **User Management Service** - Authentication, registration, user profiles
2. **Ticket Purchase Service** - Ticket sales and management
3. **Route & Schedule Service** - Bus routes and timetables
4. **Geolocation Service** - Real-time bus tracking (GPS integration)
5. **Subscription Service** - Monthly/annual subscriptions
6. **Notification Service** - Email/SMS alerts
7. **API Gateway** - Centralized entry point

### Architecture Pattern
- **Database per Service** - Each microservice has its own PostgreSQL database
- **Event-Driven** - RabbitMQ for asynchronous communication
- **RESTful APIs** - Synchronous service-to-service communication

---

## 🛠️ Technology Stack

### Backend
- **Framework**: Spring Boot (Java)
- **API Documentation**: Swagger/OpenAPI
- **Security**: Spring Security + JWT
- **Validation**: Bean Validation (Hibernate Validator)

### Frontend
- **Framework**: React
- **Styling**: Tailwind CSS
- **State Management**: Redux/Context API
- **HTTP Client**: Axios

### Message Broker
- **RabbitMQ** - Event-driven communication between services

### Databases
- **PostgreSQL** - One database per microservice
- **JPA/Hibernate** - ORM for database operations

### DevOps & Infrastructure
- **Containerization**: Docker
- **Orchestration**: Kubernetes (K8s)
- **Cloud Platform**: AWS
  - EKS (Elastic Kubernetes Service)
  - RDS (Relational Database Service)
  - S3 (Storage)
  - CloudWatch (Logging)

### Monitoring & Observability
- **Prometheus** - Metrics collection
- **Grafana** - Metrics visualization and dashboards
- **Spring Boot Actuator** - Health checks and metrics endpoints

### Testing
- **Unit Testing**: JUnit 5, Mockito
- **Integration Testing**: Spring Boot Test, TestContainers
- **API Testing**: REST Assured

### API Gateway
- **Spring Cloud Gateway** - Request routing, load balancing, authentication

---

## 📁 Project Structure

```
UrbanFlow/
├── api-gateway/              # API Gateway service
├── user-service/             # User management microservice
├── ticket-service/           # Ticket purchase microservice
├── route-service/            # Routes & schedules microservice
├── geolocation-service/      # Bus tracking microservice
├── subscription-service/     # Subscription management microservice
├── notification-service/     # Notifications microservice
├── frontend/                 # React frontend application
├── infrastructure/           # Infrastructure as Code
│   ├── docker/              # Docker compose files
│   ├── kubernetes/          # K8s manifests
│   └── terraform/           # AWS infrastructure (optional)
├── monitoring/              # Prometheus & Grafana configs
└── docs/                    # Project documentation
    ├── architecture/        # Architecture diagrams
    ├── api/                 # API specifications
    └── deployment/          # Deployment guides
```

---

## 🚀 Getting Started

### Prerequisites
- Java 17+
- Node.js 18+
- Docker & Docker Compose
- PostgreSQL
- RabbitMQ
- Maven
- kubectl (for Kubernetes)

### Local Development Setup

1. **Clone the repository**
```bash
git clone https://github.com/jihaneeee/UrbanFlow.git
cd UrbanFlow
```

2. **Start infrastructure services**
```bash
docker-compose -f infrastructure/docker/docker-compose.dev.yml up -d
```

3. **Run microservices** (example for ticket-service)
```bash
cd ticket-service
mvn spring-boot:run
```

4. **Run frontend**
```bash
cd frontend
npm install
npm start
```

---

## 📊 Service Ports (Development)

| Service | Port |
|---------|------|
| API Gateway | 8080 |
| User Service | 8081 |
| Ticket Service | 8082 |
| Route Service | 8083 |
| Geolocation Service | 8084 |
| Subscription Service | 8085 |
| Notification Service | 8086 |
| Frontend | 3000 |
| RabbitMQ Management | 15672 |
| Prometheus | 9090 |
| Grafana | 3001 |

---

## 🔐 Security

- JWT-based authentication
- OAuth2 integration (optional)
- API rate limiting
- HTTPS in production
- Database encryption

---

## 📦 Deployment

### Docker
```bash
# Build all services
./build-all.sh

# Run with Docker Compose
docker-compose up -d
```

### Kubernetes (AWS EKS)
```bash
# Apply K8s manifests
kubectl apply -f infrastructure/kubernetes/

# Check deployments
kubectl get pods -n urbanflow
```

---

## 📈 Monitoring

Access monitoring dashboards:
- **Grafana**: http://localhost:3001
- **Prometheus**: http://localhost:9090
- **RabbitMQ Management**: http://localhost:15672

---

## 🧪 Testing

### Unit Tests
```bash
mvn test
```

### Integration Tests
```bash
mvn verify -P integration-tests
```

---

## 📝 Project Phases

- [x] **Phase 1**: Architecture & Design
- [ ] **Phase 2**: Implementation
- [ ] **Phase 3**: Testing
- [ ] **Phase 4**: Deployment
- [ ] **Phase 5**: Documentation

---

## 👥 Team

- **Repository**: [UrbanFlow](https://github.com/jihaneeee/UrbanFlow)
- **Branch**: main

---

## 📄 License

This project is part of an academic microservices architecture study.

