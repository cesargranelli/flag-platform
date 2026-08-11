package br.com.flagplatform;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.modulith.Modulith;
import org.springframework.modulith.core.ApplicationModules;

@Modulith
@SpringBootApplication
public class FlagPlatformApplication {

    static void main(String[] args) {
        SpringApplication.run(FlagPlatformApplication.class, args);

        var modules = ApplicationModules.of(FlagPlatformApplication.class);
        modules.forEach(System.out::println);
    }

}
