package br.com.flagplatform;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.modulith.Modulithic;

@Modulithic
@SpringBootApplication
public class FlagPlatformApplication {

    static void main(String[] args) {
        SpringApplication.run(FlagPlatformApplication.class, args);
    }

}
