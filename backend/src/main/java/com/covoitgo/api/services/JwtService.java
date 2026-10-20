package com.covoitgo.api.services;

import com.covoitgo.api.models.Utilisateur;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Function;

/**
 * Service zur Generierung, Signierung und Validierung von JSON Web Tokens (JWT).
 * Verwendet den HMAC-SHA256 Algorithmus mit einem geheimen Schlüssel (Secret Key).
 */
@Service
public class JwtService {

    @Value("${jwt.secret:covoitgoSecretKeyForJwtSigningMustBeAtLeast256BitsLong2026SuperSecure}")
    private String secretKey;

    @Value("${jwt.expiration-ms:86400000}") // Standard: 24 Stunden (86.400.000 ms)
    private long jwtExpiration;

    // Erzeugt den kryptografischen Schlüssel aus dem geheimen String
    private SecretKey getSigningKey() {
        byte[] keyBytes = secretKey.getBytes(StandardCharsets.UTF_8);
        return Keys.hmacShaKeyFor(keyBytes);
    }

    /**
     * Erstellt ein signiertes JWT-Token für einen bestimmten Benutzer.
     * Enthält Standard-Claims (sub, iat, exp) und benutzerdefinierte Claims (id, role, nom, prenom).
     */
    public String generateToken(Utilisateur utilisateur) {
        Map<String, Object> extraClaims = new HashMap<>();
        extraClaims.put("id", utilisateur.getId());
        extraClaims.put("role", utilisateur.getRole());
        extraClaims.put("nom", utilisateur.getNom());
        extraClaims.put("prenom", utilisateur.getPrenom());

        return buildToken(extraClaims, utilisateur.getEmail(), jwtExpiration);
    }

    private String buildToken(Map<String, Object> extraClaims, String subject, long expiration) {
        long now = System.currentTimeMillis();
        return Jwts.builder()
                .claims(extraClaims)
                .subject(subject)
                .issuedAt(new Date(now))
                .expiration(new Date(now + expiration))
                .signWith(getSigningKey())
                .compact();
    }

    /**
     * Extrahiert die E-Mail-Adresse (Subject) aus dem Token.
     */
    public String extractEmail(String token) {
        return extractClaim(token, Claims::getSubject);
    }

    /**
     * Extrahiert ein beliebiges Claim aus dem Token.
     */
    public <T> T extractClaim(String token, Function<Claims, T> claimsResolver) {
        final Claims claims = extractAllClaims(token);
        return claimsResolver.apply(claims);
    }

    /**
     * Parst das Token und überprüft gleichzeitig dessen kryptografische Signatur.
     * Wirft eine JwtException, falls die Signatur manipuliert wurde oder das Token ungültig ist.
     */
    public Claims extractAllClaims(String token) {
        return Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();
    }

    /**
     * Prüft, ob das Token abgelaufen ist.
     */
    public boolean isTokenExpired(String token) {
        return extractExpiration(token).before(new Date());
    }

    private Date extractExpiration(String token) {
        return extractClaim(token, Claims::getExpiration);
    }

    /**
     * Prüft, ob das Token für den angegebenen Benutzer gültig und nicht abgelaufen ist.
     */
    public boolean isTokenValid(String token, String email) {
        final String tokenEmail = extractEmail(token);
        return (tokenEmail.equals(email) && !isTokenExpired(token));
    }
}
