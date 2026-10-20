package com.covoitgo.api.config;

import com.covoitgo.api.services.JwtService;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.Collections;
import java.util.List;

/**
 * JWT AUTHENTICATION FILTER (Ticket FR403-886)
 * 
 * Dieser Filter wird bei JEDER HTTP-Anfrage genau einmal ausgeführt (OncePerRequestFilter).
 * Er überprüft, ob im HTTP-Header ein gültiges JWT-Token ("Authorization: Bearer <token>") mitgesendet wurde.
 * 
 * 1. Kein Token -> Anfrage wird ohne Authentifizierung weitergeleitet.
 * 2. Ungültiges/Abgelaufenes Token -> Authentifizierung schlägt fehl.
 * 3. Gültiges Token -> Benutzer wird im SecurityContextHolder als authentifiziert eingetragen.
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;

    public JwtAuthenticationFilter(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain
    ) throws ServletException, IOException {

        // 1. Authorization-Header auslesen
        final String authHeader = request.getHeader("Authorization");

        // Wenn kein Header vorhanden ist oder er nicht mit "Bearer " beginnt, Filterkette fortsetzen
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }

        // 2. Token extrahieren (den Prefix "Bearer " mit 7 Zeichen abschneiden)
        final String jwt = authHeader.substring(7).trim();

        try {
            // 3. E-Mail (Subject) aus dem Token extrahieren
            final String userEmail = jwtService.extractEmail(jwt);

            // Wenn eine E-Mail vorhanden ist und der Nutzer im aktuellen Thread noch nicht authentifiziert ist
            if (userEmail != null && SecurityContextHolder.getContext().getAuthentication() == null) {

                // 4. Token auf Gültigkeit & Ablaufzeit prüfen
                if (jwtService.isTokenValid(jwt, userEmail)) {
                    // Rolle aus den JWT-Claims extrahieren (PASSAGER oder CONDUCTEUR)
                    String role = jwtService.extractClaim(jwt, claims -> claims.get("role", String.class));
                    List<SimpleGrantedAuthority> authorities = (role != null && !role.isBlank())
                            ? List.of(new SimpleGrantedAuthority("ROLE_" + role.toUpperCase()))
                            : Collections.emptyList();

                    // Authentifizierungs-Token für Spring Security erstellen
                    UsernamePasswordAuthenticationToken authToken = new UsernamePasswordAuthenticationToken(
                            userEmail,
                            null,
                            authorities
                    );

                    authToken.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));

                    // 5. Benutzer im Spring Security Kontext hinterlegen
                    SecurityContextHolder.getContext().setAuthentication(authToken);
                }
            }
        } catch (Exception e) {
            // Falls das Token gefälscht, beschädigt oder abgelaufen ist:
            // Wir fangen die Exception ab, damit der SecurityContext leer bleibt.
            // Spring Security weist unauthentifizierte Anfragen auf geschützten Routen mit 401 ab.
            SecurityContextHolder.clearContext();
        }

        // Filterkette an den nächsten Filter / Controller übergeben
        filterChain.doFilter(request, response);
    }
}
