package br.com.flagplatform.storage;

import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class StorageService {

    private final StorageConfig config;
    private Path uploadPath;

    @PostConstruct
    public void init() {
        uploadPath = Path.of(config.getUploadDir());
        try {
            Files.createDirectories(uploadPath);
            log.info("Diretório de uploads inicializado: {}", uploadPath.toAbsolutePath());
        } catch (IOException e) {
            throw new StorageException("Falha ao criar diretório de uploads: " + uploadPath, e);
        }
    }

    public String store(MultipartFile file) {
        String originalFilename = file.getOriginalFilename();
        String extension = "";
        if (originalFilename != null && originalFilename.contains(".")) {
            extension = originalFilename.substring(originalFilename.lastIndexOf("."));
        }
        String filename = UUID.randomUUID() + extension;
        Path target = uploadPath.resolve(filename);

        try {
            Files.copy(file.getInputStream(), target);
        } catch (IOException e) {
            throw new StorageException("Falha ao salvar arquivo: " + filename, e);
        }

        return "/api/v1/uploads/" + filename;
    }
}
