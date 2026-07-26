package br.com.flagplatform.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    private static final String[] PUBLIC_GET_PATTERNS = {
            "/api/v1/organizations/**",
            "/api/v1/competitions/**",
            "/api/v1/categories/**",
            "/api/v1/venues/**",
            "/api/v1/teams/**",
            "/api/v1/rounds/**",
            "/api/v1/games/**",
            "/api/v1/standings/**"
    };

    private static final String[] SWAGGER_PATTERNS = {
            "/swagger-ui.html",
            "/swagger-ui/**",
            "/api-docs/**",
            "/v3/api-docs/**"
    };

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        // Swagger público
                        .requestMatchers(SWAGGER_PATTERNS).permitAll()
                        // Health check público
                        .requestMatchers("/actuator/health").permitAll()
                        // Leitura pública para todas as entidades
                        .requestMatchers(HttpMethod.GET, PUBLIC_GET_PATTERNS).permitAll()
                        // Escrita exige autenticação
                        .anyRequest().authenticated()
                );

        return http.build();
    }
}
