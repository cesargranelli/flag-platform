package br.com.flagplatform.storage;

import br.com.flagplatform.common.security.SecurityExpressions;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;
import java.util.Set;

@Tag(name = "Upload", description = "Endpoints para upload de arquivos")
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
public class FileUploadController {

    private static final Set<String> ALLOWED_TYPES = Set.of(
            MediaType.IMAGE_JPEG_VALUE,
            MediaType.IMAGE_PNG_VALUE,
            "image/webp"
    );

    private final StorageService storageService;

    @Operation(
            summary = "Upload de imagem",
            description = "Faz upload de uma imagem (JPEG, PNG ou WebP). Máximo 5MB."
    )
    @PostMapping("/upload")
    @PreAuthorize(SecurityExpressions.ADMIN_OR_ORGANIZER)
    public ResponseEntity<?> upload(@RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Arquivo vazio"));
        }

        String contentType = file.getContentType();
        if (contentType == null || !ALLOWED_TYPES.contains(contentType)) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "Tipo de arquivo não permitido. Aceitos: image/jpeg, image/png, image/webp"
            ));
        }

        String url = storageService.store(file);
        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of("url", url));
    }
}
