package br.com.flagplatform.config;

import br.com.flagplatform.storage.StorageConfig;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
@RequiredArgsConstructor
public class WebConfig implements WebMvcConfigurer {

    private final StorageConfig storageConfig;

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        String uploadDir = storageConfig.getUploadDir();
        if (!uploadDir.endsWith("/")) {
            uploadDir += "/";
        }
        registry.addResourceHandler("/api/v1/uploads/**")
                .addResourceLocations("file:" + uploadDir);
    }
}
