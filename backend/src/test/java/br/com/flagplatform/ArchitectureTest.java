package br.com.flagplatform;

import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModules;
import org.springframework.modulith.docs.Documenter;

class ArchitectureTest {

    // Analisa a estrutura de pacotes a partir da raiz da aplicação
    ApplicationModules modules = ApplicationModules.of(FlagPlatformApplication.class);

    @Test
    void verifyArchitecture() {
        // Valida se as regras de isolamento e acoplamento foram respeitadas
        modules.verify();
    }

    @Test
    void writeDocumentation() {
        // Gera diagramas de componentes (C4 / PlantUML) automaticamente na pasta target
        new Documenter(modules).writeModulesAsPlantUml();
    }
}
