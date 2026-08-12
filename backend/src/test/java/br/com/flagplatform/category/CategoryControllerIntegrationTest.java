package br.com.flagplatform.category;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@ActiveProfiles("test")
class CategoryControllerIntegrationTest {

    private static final String ORGANIZATIONS_URL = "/api/v1/organizations";
    private static final String COMPETITIONS_URL = "/api/v1/competitions";
    private static final String CATEGORIES_URL = "/api/v1/categories";

    @Autowired
    private WebApplicationContext context;

    private final ObjectMapper objectMapper = new ObjectMapper();

    private MockMvc mockMvc;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders
                .webAppContextSetup(context)
                .apply(springSecurity())
                .build();
    }

    @Test
    @WithMockUser
    void create_listByCompetition_update_andDelete_flow() throws Exception {
        String organizationId = createOrganization("CATORG_FLOW", "Org Fluxo Categoria");
        String competitionId = createCompetition(organizationId, "COMP_CAT_TAÇA SP");

        String firstCategoryId = createCategory(competitionId, "CAT_A Masculino");
        String secondCategoryId = createCategory(competitionId, "CAT_B Feminino");

        mockMvc.perform(get(COMPETITIONS_URL + "/" + competitionId + "/categories"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(firstCategoryId))
                .andExpect(jsonPath("$[0].competitionId").value(competitionId))
                .andExpect(jsonPath("$[0].name").value("CAT_A Masculino"))
                .andExpect(jsonPath("$[1].id").value(secondCategoryId))
                .andExpect(jsonPath("$[1].name").value("CAT_B Feminino"));

        mockMvc.perform(put(CATEGORIES_URL + "/" + secondCategoryId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(categoryBody(competitionId, "CAT_B Feminino 7x7")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(secondCategoryId))
                .andExpect(jsonPath("$.competitionId").value(competitionId))
                .andExpect(jsonPath("$.name").value("CAT_B Feminino 7x7"));

        mockMvc.perform(delete(CATEGORIES_URL + "/" + firstCategoryId))
                .andExpect(status().isNoContent());

        mockMvc.perform(get(COMPETITIONS_URL + "/" + competitionId + "/categories"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].id").value(secondCategoryId))
                .andExpect(jsonPath("$[0].name").value("CAT_B Feminino 7x7"));
    }

    @Test
    @WithMockUser
    void create_duplicateName_returnsConflict() throws Exception {
        String organizationId = createOrganization("CATORG_DUP", "Org Duplicada Categoria");
        String competitionId = createCompetition(organizationId, "COMP_CAT_DUPLICADO");

        createCategory(competitionId, "CAT_Masculino 5x5");

        mockMvc.perform(post(CATEGORIES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(categoryBody(competitionId, "CAT_Masculino 5x5")))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser
    void create_withInvalidBody_returnsValidationErrors() throws Exception {
        Map<String, Object> invalid = new HashMap<>();
        invalid.put("name", "");

        mockMvc.perform(post(CATEGORIES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalid)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields[?(@.field == 'name')]").exists())
                .andExpect(jsonPath("$.fields[?(@.field == 'competitionId')]").exists());
    }

    @Test
    void create_requiresAuthentication() throws Exception {
        mockMvc.perform(post(CATEGORIES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(categoryBody(UUID.randomUUID().toString(), "CAT_Sem Auth")))
                .andExpect(status().isForbidden());
    }

    @Test
    void update_requiresAuthentication() throws Exception {
        mockMvc.perform(put(CATEGORIES_URL + "/" + UUID.randomUUID())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(categoryBody(UUID.randomUUID().toString(), "CAT_Sem Auth")))
                .andExpect(status().isForbidden());
    }

    @Test
    void delete_requiresAuthentication() throws Exception {
        mockMvc.perform(delete(CATEGORIES_URL + "/" + UUID.randomUUID()))
                .andExpect(status().isForbidden());
    }

    @Test
    void getByCompetition_unknownCompetition_returnsEmptyList() throws Exception {
        mockMvc.perform(get(COMPETITIONS_URL + "/" + UUID.randomUUID() + "/categories"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$").isEmpty());
    }

    private String createOrganization(String tradeName, String legalName) throws Exception {
        MvcResult result = mockMvc.perform(post(ORGANIZATIONS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(organizationBody(tradeName, legalName)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.tradeName").value(tradeName))
                .andExpect(jsonPath("$.message").isNotEmpty())
                .andReturn();

        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        return body.path("id").asText();
    }

    private String createCompetition(String organizationId, String name) throws Exception {
        MvcResult result = mockMvc.perform(post(COMPETITIONS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(competitionBody(organizationId, name)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.organizationId").value(organizationId))
                .andExpect(jsonPath("$.name").value(name))
                .andReturn();

        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        return body.path("id").asText();
    }

    private String createCategory(String competitionId, String name) throws Exception {
        MvcResult result = mockMvc.perform(post(CATEGORIES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(categoryBody(competitionId, name)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.competitionId").value(competitionId))
                .andExpect(jsonPath("$.name").value(name))
                .andReturn();

        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        return body.path("id").asText();
    }

    private String organizationBody(String tradeName, String legalName) throws Exception {
        return objectMapper.writeValueAsString(organizationFields(tradeName, legalName));
    }

    private Map<String, Object> organizationFields(String tradeName, String legalName) {
        Map<String, Object> fields = new HashMap<>();
        fields.put("legalName", legalName);
        fields.put("tradeName", tradeName);
        fields.put("abbreviation", "CATORG");
        fields.put("organizationType", "ASSOCIATION");
        fields.put("email", "contato@catorg.com.br");
        fields.put("phone", "11999999999");
        fields.put("website", "https://catorg.com.br");
        fields.put("instagram", "catorg.flag");
        fields.put("country", "BR");
        fields.put("state", "São Paulo");
        fields.put("city", "São Paulo");
        fields.put("logoUrl", "https://catorg.com.br/logo.png");
        fields.put("primaryColor", "#000000");
        fields.put("secondaryColor", "#FFFFFF");
        fields.put("timezone", "America/Sao_Paulo");
        fields.put("locale", "pt-BR");
        return fields;
    }

    private String competitionBody(String organizationId, String name) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("organizationId", organizationId);
        fields.put("name", name);
        fields.put("description", "Campeonato para categorias");
        fields.put("startDate", "2026-01-15");
        fields.put("endDate", "2026-06-30");
        return objectMapper.writeValueAsString(fields);
    }

    private String categoryBody(String competitionId, String name) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("competitionId", competitionId);
        fields.put("name", name);
        return objectMapper.writeValueAsString(fields);
    }

}
