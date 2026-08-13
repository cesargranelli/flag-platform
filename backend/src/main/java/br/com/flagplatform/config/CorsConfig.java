package br.com.flagplatform.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

/**
 * Configuração de CORS para acesso da API a partir dos apps Flutter (Web).
 *
 * O dev server do Flutter roda em porta aleatória do localhost, então além
 * das origens explícitas configuradas em {@code app.cors.allowed-origins},
 * sempre são liberados padrões de localhost/127.0.0.1 com qualquer porta.
 */
@Configuration
public class CorsConfig {

    /** Padrões de origem liberados por padrão (dev Flutter web). */
    private static final List<String> DEFAULT_ORIGIN_PATTERNS = List.of(
            "http://localhost:*",
            "http://127.0.0.1:*"
    );

    @Bean
    public CorsConfigurationSource corsConfigurationSource(
            @Value("${app.cors.allowed-origins:}") String configuredOrigins) {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(originPatterns(configuredOrigins));
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("*"));
        config.setExposedHeaders(List.of("Location"));
        // Autenticação via Bearer (Authorization header), sem cookies:
        // não é necessário permitir credenciais.
        config.setAllowCredentials(false);
        config.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return source;
    }

    private static List<String> originPatterns(String configuredOrigins) {
        List<String> patterns = new ArrayList<>(DEFAULT_ORIGIN_PATTERNS);
        if (configuredOrigins != null && !configuredOrigins.isBlank()) {
            patterns.addAll(
                    Arrays.stream(configuredOrigins.split(","))
                            .map(String::trim)
                            .filter(s -> !s.isEmpty())
                            .toList());
        }
        return patterns;
    }
}
