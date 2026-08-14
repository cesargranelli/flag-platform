package br.com.flagplatform.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.time.Instant;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Limita tentativas de autenticação por IP (anti brute-force).
 * <p>
 * Janela deslizante em memória: acima de {@code maxAttempts} em
 * {@code windowSeconds}, retorna 429. Config:
 * {@code app.security.rate-limit.max-attempts} e
 * {@code app.security.rate-limit.window-seconds}.
 */
@Component
public class LoginRateLimitFilter extends OncePerRequestFilter {

    private final int maxAttempts;
    private final long windowSeconds;
    private final Map<String, Deque<Instant>> attempts = new ConcurrentHashMap<>();

    public LoginRateLimitFilter(
            @Value("${app.security.rate-limit.max-attempts:10}") int maxAttempts,
            @Value("${app.security.rate-limit.window-seconds:300}") long windowSeconds) {
        this.maxAttempts = maxAttempts;
        this.windowSeconds = windowSeconds;
    }

    @Override
    protected void doFilterInternal(
            HttpServletRequest request,
            HttpServletResponse response,
            FilterChain filterChain) throws ServletException, IOException {

        if ("POST".equalsIgnoreCase(request.getMethod())
                && request.getRequestURI().endsWith("/api/v1/auth/login")) {

            String ip = clientIp(request);
            if (isBlocked(ip)) {
                response.setStatus(HttpStatus.TOO_MANY_REQUESTS.value());
                response.setContentType("application/json");
                response.getWriter().write(
                        "{\"status\":429,\"title\":\"Too Many Requests\","
                                + "\"detail\":\"Too many login attempts. Try again later.\"}");
                return;
            }
            recordAttempt(ip);
        }

        filterChain.doFilter(request, response);
    }

    private boolean isBlocked(String ip) {
        Deque<Instant> window = attempts.get(ip);
        if (window == null) {
            return false;
        }
        long cutoff = Instant.now().getEpochSecond() - windowSeconds;
        window.removeIf(timestamp -> timestamp.getEpochSecond() < cutoff);
        return window.size() >= maxAttempts;
    }

    private void recordAttempt(String ip) {
        attempts.computeIfAbsent(ip, key -> new ArrayDeque<>()).addLast(Instant.now());
    }

    private String clientIp(HttpServletRequest request) {
        String forwarded = request.getHeader("X-Forwarded-For");
        if (forwarded != null && !forwarded.isBlank()) {
            return forwarded.split(",")[0].trim();
        }
        return request.getRemoteAddr();
    }
}
