package br.com.flagplatform.config;

import org.flywaydb.core.Flyway;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import javax.sql.DataSource;

/**
 * Explicit Flyway configuration to guarantee migrations run before
 * Hibernate schema validation in Spring Boot 4.x.
 * <p>
 * Spring Boot 4.x modularized auto-configuration. Defining Flyway
 * as an explicit @Bean ensures it initializes before the JPA
 * EntityManagerFactory attempts schema validation.
 */
@Configuration
public class FlywayConfig {

    @Bean(initMethod = "migrate")
    public Flyway flyway(DataSource dataSource) {
        return Flyway.configure()
                .dataSource(dataSource)
                .schemas("platform")
                .locations("classpath:db/migration")
                .defaultSchema("platform")
                .load();
    }

}
