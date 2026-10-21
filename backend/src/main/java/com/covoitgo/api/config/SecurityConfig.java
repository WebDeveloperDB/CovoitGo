package com.covoitgo.api.config;

import jakarta.servlet.http.HttpServletResponse;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

/**
 * SPRING SECURITY KONFIGURATION (Ticket FR403-886)
 * 
 * Konfiguriert die Sicherheitsfilterkette (SecurityFilterChain):
 * - CSRF deaktiviert (da Stateless REST API mit JWT)
 * - SessionCreationPolicy.STATELESS (keine Session-Cookies auf dem Server)
 * - Öffentliche Routen: /api/auth/**, /api/trajets/recherche, Swagger, Actuator
 * - Geschützte Routen: /api/trajets (Erstellung), /api/trajets/mes-trajets, /api/trajets/{id}/demandes/**
 * - Integriert den JwtAuthenticationFilter
 */
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthFilter;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthFilter) {
        this.jwtAuthFilter = jwtAuthFilter;
    }

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                // 1. CSRF deaktivieren (da wir Stateless JWT-Token nutzen, keine Cookies)
                .csrf(csrf -> csrf.disable())

                // 2. CORS konfigurieren für Flutter Mobile und Web
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))

                // 3. Stateless Session-Management (keine HTTP-Sessions auf dem Server)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))

                // 4. Autorisierungsregeln für URLs
                .authorizeHttpRequests(auth -> auth
                        // Öffentliche Endpunkte (jeder darf zugreifen):
                        .requestMatchers("/health", "/api/health").permitAll()
                        .requestMatchers("/api/auth/**").permitAll()
                        .requestMatchers(HttpMethod.GET, "/api/trajets/recherche").permitAll()
                        .requestMatchers("/actuator/**").permitAll()
                        .requestMatchers("/v3/api-docs/**", "/swagger-ui/**", "/swagger-ui.html").permitAll()

                        // Geschützte Endpunkte (nur mit gültigem JWT-Token):
                        .requestMatchers(HttpMethod.POST, "/api/trajets").authenticated()
                        .requestMatchers(HttpMethod.GET, "/api/trajets/mes-trajets").authenticated()
                        .requestMatchers("/api/trajets/*/demandes/**").authenticated()

                        // Alle weiteren API-Endpunkte unter /api/** absichern
                        .requestMatchers("/api/**").authenticated()
                        .anyRequest().permitAll()
                )

                // 5. JWT-Filter vor dem standardmäßigen UsernamePasswordAuthenticationFilter platzieren
                .addFilterBefore(jwtAuthFilter, UsernamePasswordAuthenticationFilter.class)

                // 6. Benutzerdefinierte Antwort bei fehlender/ungültiger Authentifizierung (HTTP 401)
                .exceptionHandling(ex -> ex
                        .authenticationEntryPoint((request, response, authException) -> {
                            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                            response.setContentType("application/json;charset=UTF-8");
                            response.getWriter().write("{\"erreur\":\"Non authentifié. Token JWT manquant ou invalide.\"}");
                        })
                );

        return http.build();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(List.of("*"));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }
}
