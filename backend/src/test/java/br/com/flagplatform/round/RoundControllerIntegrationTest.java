package br.com.flagplatform.round;

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
class RoundControllerIntegrationTest {

    private static final String ORGANIZATIONS_URL = "/api/v1/organizations";
    private static final String COMPETITIONS_URL = "/api/v1/competitions";
    private static final String CATEGORIES_URL = "/api/v1/categories";
    private static final String ROUNDS_URL = "/api/v1/rounds";

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
    void create_listByCategory_andUpdate_flow() throws Exception {
        String organizationId = createOrganization("ROUND_APFA", "Associação Paulista de Flag Football");
        String competitionId = createCompetition(organizationId, "COMP_ROUND_TAÇA SP");
        String categoryId = createCategory(competitionId, "CAT_Masculino 5x5");

        String firstRoundId = createRound(categoryId, 1, "Primeira Rodada", "REGULAR");
        createRound(categoryId, 2, "Segunda Rodada", "PLAYOFFS");

        mockMvc.perform(get(CATEGORIES_URL + "/" + categoryId + "/rounds"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(firstRoundId))
                .andExpect(jsonPath("$[0].categoryId").value(categoryId))
                .andExpect(jsonPath("$[0].number").value(1))
                .andExpect(jsonPath("$[0].name").value("Primeira Rodada"))
                .andExpect(jsonPath("$[0].type").value("REGULAR"))
                .andExpect(jsonPath("$[1].number").value(2))
                .andExpect(jsonPath("$[1].name").value("Segunda Rodada"))
                .andExpect(jsonPath("$[1].type").value("PLAYOFFS"));

        mockMvc.perform(put(ROUNDS_URL + "/" + firstRoundId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(roundBody(categoryId, 1, "Primeira Rodada (Atualizada)", "PLAYOFFS")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(firstRoundId))
                .andExpect(jsonPath("$.number").value(1))
                .andExpect(jsonPath("$.name").value("Primeira Rodada (Atualizada)"))
                .andExpect(jsonPath("$.type").value("PLAYOFFS"));
    }

    @Test
    @WithMockUser
    void create_withUnknownCategory_returnsNotFound() throws Exception {
        mockMvc.perform(post(ROUNDS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(roundBody(UUID.randomUUID().toString(), 1,
                                "Rodada Fantasma", "REGULAR")))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser
    void create_duplicateNumber_returnsConflict() throws Exception {
        String organizationId = createOrganization("ROUND_DUP", "Org Duplicada Round");
        String competitionId = createCompetition(organizationId, "COMP_ROUND_DUPLICADO");
        String categoryId = createCategory(competitionId, "CAT_Masculino 5x5");

        createRound(categoryId, 1, "Primeira Rodada", "REGULAR");

        mockMvc.perform(post(ROUNDS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(roundBody(categoryId, 1, "Rodada Repetida", "REGULAR")))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser
    void listByCategory_returnsRoundsOrderedByNumber_publicAccess() throws Exception {
        String organizationId = createOrganization("ROUND_ORD", "Org Ordenada Round");
        String competitionId = createCompetition(organizationId, "COMP_ROUND_ORDENADO");
        String categoryId = createCategory(competitionId, "CAT_Masculino 5x5");

        createRound(categoryId, 2, "Segunda Rodada", "REGULAR");
        createRound(categoryId, 1, "Primeira Rodada", "REGULAR");

        MvcResult result = mockMvc.perform(get(CATEGORIES_URL + "/" + categoryId + "/rounds"))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode array = objectMapper.readTree(result.getResponse().getContentAsString());
        int firstIndex = indexOfNumber(array, 1);
        int secondIndex = indexOfNumber(array, 2);

        assertThat(firstIndex).isNotNegative();
        assertThat(secondIndex).isNotNegative();
        assertThat(firstIndex).isLessThan(secondIndex);
    }

    @Test
    void listByCategory_unknownCategory_returnsEmptyList_publicAccess() throws Exception {
        mockMvc.perform(get(CATEGORIES_URL + "/" + UUID.randomUUID() + "/rounds"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$").isEmpty());
    }

    @Test
    @WithMockUser
    void update_duplicateNumber_returnsConflict() throws Exception {
        String organizationId = createOrganization("ROUND_UPD", "Org Update Round");
        String competitionId = createCompetition(organizationId, "COMP_ROUND_UPDATE");
        String categoryId = createCategory(competitionId, "CAT_Masculino 5x5");

        String firstRoundId = createRound(categoryId, 1, "Primeira Rodada", "REGULAR");
        createRound(categoryId, 2, "Segunda Rodada", "REGULAR");

        mockMvc.perform(put(ROUNDS_URL + "/" + firstRoundId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(roundBody(categoryId, 2, "Segunda Rodada", "REGULAR")))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser
    void update_unknownId_returnsNotFound() throws Exception {
        String organizationId = createOrganization("ROUND_NF", "Org Not Found Round");
        String competitionId = createCompetition(organizationId, "COMP_ROUND_NOT_FOUND");
        String categoryId = createCategory(competitionId, "CAT_Masculino 5x5");

        mockMvc.perform(put(ROUNDS_URL + "/" + UUID.randomUUID())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(roundBody(categoryId, 1, "Rodada Fantasma", "REGULAR")))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser
    void create_withInvalidBody_returnsValidationErrors() throws Exception {
        Map<String, Object> invalid = new HashMap<>();
        invalid.put("name", "");

        mockMvc.perform(post(ROUNDS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalid)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields[?(@.field == 'number')]").exists())
                .andExpect(jsonPath("$.fields[?(@.field == 'name')]").exists())
                .andExpect(jsonPath("$.fields[?(@.field == 'type')]").exists());
    }

    @Test
    void create_requiresAuthentication() throws Exception {
        mockMvc.perform(post(ROUNDS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(roundBody(UUID.randomUUID().toString(), 1,
                                "Rodada Sem Auth", "REGULAR")))
                .andExpect(status().isForbidden());
    }

    @Test
    void update_requiresAuthentication() throws Exception {
        mockMvc.perform(put(ROUNDS_URL + "/" + UUID.randomUUID())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(roundBody(UUID.randomUUID().toString(), 1,
                                "Rodada Sem Auth", "REGULAR")))
                .andExpect(status().isForbidden());
    }

    private int indexOfNumber(JsonNode array, int number) {
        for (int i = 0; i < array.size(); i++) {
            if (array.get(i).path("number").asInt() == number) {
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

    private String createRound(String categoryId, int number, String name,
                               String type) throws Exception {
        MvcResult result = mockMvc.perform(post(ROUNDS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(roundBody(categoryId, number, name, type)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.categoryId").value(categoryId))
                .andExpect(jsonPath("$.number").value(number))
                .andExpect(jsonPath("$.name").value(name))
                .andExpect(jsonPath("$.type").value(type))
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
        fields.put("abbreviation", "ROUND");
        fields.put("organizationType", "ASSOCIATION");
        fields.put("email", "contato@round.org.br");
        fields.put("phone", "11999999999");
        fields.put("website", "https://round.org.br");
        fields.put("instagram", "round.flag");
        fields.put("country", "BR");
        fields.put("state", "São Paulo");
        fields.put("city", "São Paulo");
        fields.put("logoUrl", "https://round.org.br/logo.png");
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
        fields.put("description", "Campeonato para rodadas");
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

    private String roundBody(String categoryId, int number, String name,
                             String type) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("categoryId", categoryId);
        fields.put("number", number);
        fields.put("name", name);
        fields.put("type", type);
        return objectMapper.writeValueAsString(fields);
    }

}
