package br.com.flagplatform.competition;

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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@ActiveProfiles("test")
class CompetitionControllerIntegrationTest {

    private static final String ORGANIZATIONS_URL = "/api/v1/organizations";
    private static final String COMPETITIONS_URL = "/api/v1/competitions";

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
    @WithMockUser(roles = "ORGANIZER")
    void create_get_listByOrganization_andUpdate_flow() throws Exception {
        String organizationId = createOrganization(
                "COMP_APFA", "Associação Paulista de Futebol Americano");

        String competitionId = createCompetition(organizationId, "Taça SP");

        mockMvc.perform(get(COMPETITIONS_URL + "/" + competitionId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(competitionId))
                .andExpect(jsonPath("$.organizationId").value(organizationId))
                .andExpect(jsonPath("$.name").value("Taça SP"))
                .andExpect(jsonPath("$.status").value("DRAFT"));

        mockMvc.perform(get(ORGANIZATIONS_URL + "/" + organizationId + "/competitions"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(competitionId))
                .andExpect(jsonPath("$[0].name").value("Taça SP"));

        mockMvc.perform(put(COMPETITIONS_URL + "/" + competitionId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(competitionBody(organizationId, "Taça SP 2026", "PUBLISHED")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(competitionId))
                .andExpect(jsonPath("$.name").value("Taça SP 2026"))
                .andExpect(jsonPath("$.status").value("PUBLISHED"));
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void create_duplicateName_returnsConflict() throws Exception {
        String organizationId = createOrganization("COMP_FLAGSP", "Flag SP");

        createCompetition(organizationId, "Campeonato Único");

        mockMvc.perform(post(COMPETITIONS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(competitionBody(organizationId, "Campeonato Único", null)))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void create_withInvalidBody_returnsValidationErrors() throws Exception {
        Map<String, Object> invalid = new HashMap<>();
        invalid.put("name", "");

        mockMvc.perform(post(COMPETITIONS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalid)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields[?(@.field == 'name')]").exists())
                .andExpect(jsonPath("$.fields[?(@.field == 'organizationId')]").exists());
    }

    @Test
    void create_requiresAuthentication() throws Exception {
        mockMvc.perform(post(COMPETITIONS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(competitionBody(UUID.randomUUID().toString(), "Sem Auth", null)))
                .andExpect(status().isForbidden());
    }

    @Test
    void update_requiresAuthentication() throws Exception {
        mockMvc.perform(put(COMPETITIONS_URL + "/" + UUID.randomUUID())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(competitionBody(UUID.randomUUID().toString(), "Sem Auth", null)))
                .andExpect(status().isForbidden());
    }

    @Test
    void getById_unknownId_returnsNotFound() throws Exception {
        mockMvc.perform(get(COMPETITIONS_URL + "/" + UUID.randomUUID()))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void listAll_returnsCompetitionsOrderedByNameWithOrganizationName() throws Exception {
        String firstOrgId = createOrganization("COMP_SUM_APFA", "Associação Paulista de Futebol Americano");
        String secondOrgId = createOrganization("COMP_SUM_FLAGSP", "Flag SP");

        String tacaId = createCompetition(firstOrgId, "Taça SP");
        String copaId = createCompetition(secondOrgId, "Copa Paulista");

        MvcResult result = mockMvc.perform(get(COMPETITIONS_URL))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andReturn();

        JsonNode array = objectMapper.readTree(result.getResponse().getContentAsString());
        int copaIndex = indexOfId(array, copaId);
        int tacaIndex = indexOfId(array, tacaId);

        assertThat(copaIndex).isNotNegative();
        assertThat(tacaIndex).isNotNegative();
        assertThat(copaIndex).isLessThan(tacaIndex);

        assertThat(array.get(copaIndex).path("id").asText()).isEqualTo(copaId);
        assertThat(array.get(copaIndex).path("name").asText()).isEqualTo("Copa Paulista");
        assertThat(array.get(copaIndex).path("organizationName").asText()).isEqualTo("COMP_SUM_FLAGSP");
        assertThat(array.get(copaIndex).path("status").asText()).isEqualTo("DRAFT");

        assertThat(array.get(tacaIndex).path("id").asText()).isEqualTo(tacaId);
        assertThat(array.get(tacaIndex).path("name").asText()).isEqualTo("Taça SP");
        assertThat(array.get(tacaIndex).path("organizationName").asText()).isEqualTo("COMP_SUM_APFA");
        assertThat(array.get(tacaIndex).path("status").asText()).isEqualTo("DRAFT");
    }

    private int indexOfId(JsonNode array, String id) {
        for (int i = 0; i < array.size(); i++) {
            if (id.equals(array.get(i).path("id").asText())) {
                return i;
            }
        }
        return -1;
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
                        .content(competitionBody(organizationId, name, null)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.organizationId").value(organizationId))
                .andExpect(jsonPath("$.name").value(name))
                .andExpect(jsonPath("$.status").value("DRAFT"))
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
        fields.put("abbreviation", "COMP");
        fields.put("organizationType", "ASSOCIATION");
        fields.put("document", cnpj("org-" + tradeName));
        fields.put("documentType", "CNPJ");
        fields.put("email", "contato@comp.com.br");
        fields.put("phone", "11999999999");
        fields.put("website", "https://comp.com.br");
        fields.put("instagram", "comp.flag");
        fields.put("country", "BR");
        fields.put("state", "São Paulo");
        fields.put("city", "São Paulo");
        fields.put("logoUrl", "https://comp.com.br/logo.png");
        fields.put("primaryColor", "#000000");
        fields.put("secondaryColor", "#FFFFFF");
        fields.put("timezone", "America/Sao_Paulo");
        fields.put("locale", "pt-BR");
        return fields;
    }

    private String competitionBody(String organizationId, String name, String status) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("organizationId", organizationId);
        fields.put("name", name);
        fields.put("description", "Campeonato estadual de flag football");
        fields.put("startDate", "2026-01-15");
        fields.put("endDate", "2026-06-30");
        if (status != null) {
            fields.put("status", status);
        }
        return objectMapper.writeValueAsString(fields);
    }

    /**
     * Gera um CNPJ valido e unico a partir de um seed.
     */
    private String cnpj(String seed) {
        String base = String.format("%012d",
                Math.abs((seed + "-" + System.nanoTime()).hashCode()) % 1000000000000L);
        int[] w1 = {5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2};
        int[] w2 = {6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2};
        int[] digits = base.chars().map(c -> c - '0').toArray();
        int d1 = dv(digits, w1, 12);
        int d2 = dv(concat(digits, d1), w2, 13);
        return base + d1 + d2;
    }

    private int dv(int[] digits, int[] weights, int length) {
        int sum = 0;
        for (int i = 0; i < length; i++) {
            sum += digits[i] * weights[i];
        }
        int rest = sum % 11;
        return rest < 2 ? 0 : 11 - rest;
    }

    private int[] concat(int[] a, int b) {
        int[] r = new int[a.length + 1];
        System.arraycopy(a, 0, r, 0, a.length);
        r[a.length] = b;
        return r;
    }

}
