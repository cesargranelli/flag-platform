package br.com.flagplatform.config;

import br.com.flagplatform.security.JwtAuthenticationFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    private static final String[] PUBLIC_GET_PATTERNS = {
            "/api/v1/organizations/**",
            "/api/v1/competitions/**",
            "/api/v1/venues/**",
            "/api/v1/teams/**",
            "/api/v1/rounds/**",
            "/api/v1/games/**",
            "/api/v1/standings/**",
            "/api/v1/athletes/**",
            "/api/v1/uploads/**"
    };

    private static final String[] PUBLIC_AUTH_PATTERNS = {
            "/api/v1/auth/register",
            "/api/v1/auth/login",
            "/api/v1/auth/forgot-password",
            "/api/v1/auth/reset-password"
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
                .cors(Customizer.withDefaults())
                .sessionManagement(session ->
                        session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        // Swagger público
                        .requestMatchers(SWAGGER_PATTERNS).permitAll()
                        // Health check público
                        .requestMatchers("/actuator/health").permitAll()
                        // Métricas Prometheus (scraping)
                        .requestMatchers("/actuator/prometheus").permitAll()
                        // Cadastro e login públicos
                        .requestMatchers(HttpMethod.POST, PUBLIC_AUTH_PATTERNS).permitAll()
                        // Check-in de atletas exige role MESA/ADMIN (não é leitura pública)
                        .requestMatchers(HttpMethod.GET, "/api/v1/games/*/checkin")
                                .hasAnyRole("ADMIN", "MESA")
                        // Leitura pública para todas as entidades
                        .requestMatchers(HttpMethod.GET, PUBLIC_GET_PATTERNS).permitAll()
                        // Escrita exige autenticação
                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);

        return http.build();
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

}
