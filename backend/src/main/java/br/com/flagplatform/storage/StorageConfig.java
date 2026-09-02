package br.com.flagplatform.storage;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;

@Configuration
public class StorageConfig {

    @Value("${app.storage.upload-dir:uploads}")
    private String uploadDir;

    @Value("${app.storage.base-url:}")
    private String baseUrl;

    public String getUploadDir() {
        return uploadDir;
    }

    public String getBaseUrl() {
        return baseUrl;
    }
}
