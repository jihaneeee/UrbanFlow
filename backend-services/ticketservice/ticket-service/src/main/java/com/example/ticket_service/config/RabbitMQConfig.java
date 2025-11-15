package com.example.ticket_service.config;

import org.springframework.amqp.core.*;
import org.springframework.amqp.rabbit.connection.ConnectionFactory;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitMQConfig {

    // ============= EXCHANGES =============
    public static final String TICKET_EXCHANGE = "ticket.events";
    public static final String PAYMENT_EXCHANGE = "payment.events";
    public static final String ROUTE_EXCHANGE = "route.events";

    // ============= QUEUES (Ticket Service Publishes To) =============
    public static final String PAYMENT_QUEUE = "payment.ticket.created";
    public static final String NOTIFICATION_QUEUE = "notification.ticket.events";
    public static final String ANALYTICS_QUEUE = "analytics.ticket.events";
    public static final String REFUND_QUEUE = "refund.ticket.cancelled";

    // ============= QUEUES (Ticket Service Consumes From) =============
    public static final String TICKET_PAYMENT_QUEUE = "ticket.payment.completed";
    public static final String TICKET_ROUTE_QUEUE = "ticket.route.cancelled";

    // ============= ROUTING KEYS =============
    public static final String TICKET_CREATED_KEY = "ticket.created";
    public static final String TICKET_CANCELLED_KEY = "ticket.cancelled";
    public static final String TICKET_USED_KEY = "ticket.used";
    public static final String TICKET_EXPIRED_KEY = "ticket.expired";
    public static final String PAYMENT_COMPLETED_KEY = "payment.completed";
    public static final String PAYMENT_FAILED_KEY = "payment.failed";
    public static final String ROUTE_CANCELLED_KEY = "route.cancelled";

    // ============= EXCHANGE DECLARATIONS =============

    @Bean
    public TopicExchange ticketExchange() {
        return new TopicExchange(TICKET_EXCHANGE);
    }

    @Bean
    public TopicExchange paymentExchange() {
        return new TopicExchange(PAYMENT_EXCHANGE);
    }

    @Bean
    public TopicExchange routeExchange() {
        return new TopicExchange(ROUTE_EXCHANGE);
    }

    // ============= QUEUE DECLARATIONS (Outbound) =============

    @Bean
    public Queue paymentQueue() {
        return QueueBuilder.durable(PAYMENT_QUEUE)
                .withArgument("x-message-ttl", 3600000) // 1 hour TTL
                .build();
    }

    @Bean
    public Queue notificationQueue() {
        return QueueBuilder.durable(NOTIFICATION_QUEUE).build();
    }

    @Bean
    public Queue analyticsQueue() {
        return QueueBuilder.durable(ANALYTICS_QUEUE).build();
    }

    @Bean
    public Queue refundQueue() {
        return QueueBuilder.durable(REFUND_QUEUE).build();
    }

    // ============= QUEUE DECLARATIONS (Inbound) =============

    @Bean
    public Queue ticketPaymentQueue() {
        return QueueBuilder.durable(TICKET_PAYMENT_QUEUE).build();
    }

    @Bean
    public Queue ticketRouteQueue() {
        return QueueBuilder.durable(TICKET_ROUTE_QUEUE).build();
    }

    // ============= BINDINGS (Ticket Service Publishes) =============

    @Bean
    public Binding bindingPaymentQueue() {
        return BindingBuilder
                .bind(paymentQueue())
                .to(ticketExchange())
                .with(TICKET_CREATED_KEY);
    }

    @Bean
    public Binding bindingNotificationCreated() {
        return BindingBuilder
                .bind(notificationQueue())
                .to(ticketExchange())
                .with("ticket.*"); // All ticket events
    }

    @Bean
    public Binding bindingAnalytics() {
        return BindingBuilder
                .bind(analyticsQueue())
                .to(ticketExchange())
                .with("ticket.*");
    }

    @Bean
    public Binding bindingRefundQueue() {
        return BindingBuilder
                .bind(refundQueue())
                .to(ticketExchange())
                .with(TICKET_CANCELLED_KEY);
    }

    // ============= BINDINGS (Ticket Service Consumes) =============

    @Bean
    public Binding bindingTicketPaymentQueue() {
        return BindingBuilder
                .bind(ticketPaymentQueue())
                .to(paymentExchange())
                .with(PAYMENT_COMPLETED_KEY);
    }

    @Bean
    public Binding bindingTicketRouteQueue() {
        return BindingBuilder
                .bind(ticketRouteQueue())
                .to(routeExchange())
                .with(ROUTE_CANCELLED_KEY);
    }

    // ============= MESSAGE CONVERTER =============

    @Bean
    public MessageConverter jsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }

    @Bean
    public RabbitTemplate rabbitTemplate(ConnectionFactory connectionFactory) {
        RabbitTemplate rabbitTemplate = new RabbitTemplate(connectionFactory);
        rabbitTemplate.setMessageConverter(jsonMessageConverter());
        return rabbitTemplate;
    }
}
