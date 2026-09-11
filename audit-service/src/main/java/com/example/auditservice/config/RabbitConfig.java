package com.example.auditservice.config;

import org.springframework.amqp.core.Binding;
import org.springframework.amqp.core.BindingBuilder;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.TopicExchange;
import org.springframework.amqp.support.converter.Jackson2JsonMessageConverter;
import org.springframework.amqp.support.converter.MessageConverter;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class RabbitConfig {

    @Value("${rabbitmq.queue.audit}")
    private String queueName;

    @Value("${rabbitmq.exchange.audit}")
    private String exchangeName;

    @Value("${rabbitmq.routingkey.audit}")
    private String routingKey;

    @Bean
    public Queue auditQueue() {
        return new Queue(queueName, false);
    }

    @Bean
    public TopicExchange auditExchange() {
        return new TopicExchange(exchangeName);
    }

    @Bean
    public Binding binding(Queue auditQueue, TopicExchange auditExchange) {
        return BindingBuilder.bind(auditQueue).to(auditExchange).with(routingKey);
    }

    @Bean
    public MessageConverter jsonMessageConverter() {
        return new Jackson2JsonMessageConverter();
    }
}
