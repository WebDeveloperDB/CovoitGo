package com.covoitgo.api.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * Konfigurationsklasse für Sicherheits-Beans.
 * Definiert den BCryptPasswordEncoder zur sicheren Passwort-Verschlüsselung.
 */
@Configuration
public class SecurityBeansConfig {

    @Bean
    public PasswordEncoder passwordEncoder() {
        // BCrypt mit Standard-Stärke 10 (10 Rounds Hashing mit automatischem Salt)
        return new BCryptPasswordEncoder();
    }
}
