package br.com.flagplatform.team;

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
class TeamControllerIntegrationTest {

    private static final String ORGANIZATIONS_URL = "/api/v1/organizations";
    private static final String COMPETITIONS_URL = "/api/v1/competitions";
    private static final String CATEGORIES_URL = "/api/v1/categories";
    private static final String MODALITIES_URL = "/api/v1/modalities";
    private static final String TEAMS_URL = "/api/v1/teams";

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
    void create_listByCategory_getById_andUpdate_flow() throws Exception {
        String organizationId = createOrganization("TEAM_APFA", "Associação Paulista de Flag Football");
        String competitionId = createCompetition(organizationId, "COMP_TEAM_TAÇA SP");
        String categoryId = createCategory(competitionId, "CAT_Masculino 5x5");

        String firstTeamId = createTeam(categoryId, "Tritões FC", "TRI",
                "https://team.example.com/tritoes.png");
        String secondTeamId = createTeam(categoryId, "Águias Negras", "AGN", null);

        mockMvc.perform(get(CATEGORIES_URL + "/" + categoryId + "/teams"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(firstTeamId))
                .andExpect(jsonPath("$[0].categoryId").value(categoryId))
                .andExpect(jsonPath("$[0].name").value("Tritões FC"))
                .andExpect(jsonPath("$[0].shortName").value("TRI"))
                .andExpect(jsonPath("$[0].logoUrl").value("https://team.example.com/tritoes.png"))
                .andExpect(jsonPath("$[1].id").value(secondTeamId))
                .andExpect(jsonPath("$[1].name").value("Águias Negras"));

        mockMvc.perform(get(TEAMS_URL + "/" + firstTeamId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(firstTeamId))
                .andExpect(jsonPath("$.categoryId").value(categoryId))
                .andExpect(jsonPath("$.name").value("Tritões FC"))
                .andExpect(jsonPath("$.shortName").value("TRI"))
                .andExpect(jsonPath("$.logoUrl").value("https://team.example.com/tritoes.png"));

        mockMvc.perform(put(TEAMS_URL + "/" + firstTeamId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(teamBody(categoryId, "Tritões FC 2", "TR2",
                                "https://team.example.com/tritoes2.png")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(firstTeamId))
                .andExpect(jsonPath("$.name").value("Tritões FC 2"))
                .andExpect(jsonPath("$.shortName").value("TR2"))
                .andExpect(jsonPath("$.logoUrl").value("https://team.example.com/tritoes2.png"));
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void create_withUnknownCategory_returnsNotFound() throws Exception {
        mockMvc.perform(post(TEAMS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(teamBody(UUID.randomUUID().toString(),
                                "Time Fantasma", null, null)))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void create_duplicateName_returnsConflict() throws Exception {
        String organizationId = createOrganization("TEAM_DUP", "Org Duplicada Team");
        String competitionId = createCompetition(organizationId, "COMP_TEAM_DUPLICADO");
        String categoryId = createCategory(competitionId, "CAT_Masculino 5x5");

        createTeam(categoryId, "Corsários", "COR", null);

        mockMvc.perform(post(TEAMS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(teamBody(categoryId, "Corsários", "COR", null)))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void listByCategory_returnsTeamsOrderedByName_publicAccess() throws Exception {
        String organizationId = createOrganization("TEAM_ORD", "Org Ordenada Team");
        String competitionId = createCompetition(organizationId, "COMP_TEAM_ORDENADO");
        String categoryId = createCategory(competitionId, "CAT_Masculino 5x5");

        createTeam(categoryId, "Zeta FC", "ZET", null);
        createTeam(categoryId, "Alpha FC", "ALF", null);

        MvcResult result = mockMvc.perform(get(CATEGORIES_URL + "/" + categoryId + "/teams"))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode array = objectMapper.readTree(result.getResponse().getContentAsString());
        int alphaIndex = indexOfName(array, "Alpha FC");
        int zetaIndex = indexOfName(array, "Zeta FC");

        assertThat(alphaIndex).isNotNegative();
        assertThat(zetaIndex).isNotNegative();
        assertThat(alphaIndex).isLessThan(zetaIndex);
    }

    @Test
    void getById_unknownId_returnsNotFound() throws Exception {
        mockMvc.perform(get(TEAMS_URL + "/" + UUID.randomUUID()))
                .andExpect(status().isNotFound());
    }

    @Test
    void listByCategory_unknownCategory_returnsEmptyList_publicAccess() throws Exception {
        mockMvc.perform(get(CATEGORIES_URL + "/" + UUID.randomUUID() + "/teams"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$").isEmpty());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void update_duplicateName_returnsConflict() throws Exception {
        String organizationId = createOrganization("TEAM_UPD", "Org Update Team");
        String competitionId = createCompetition(organizationId, "COMP_TEAM_UPDATE");
        String categoryId = createCategory(competitionId, "CAT_Masculino 5x5");

        String firstTeamId = createTeam(categoryId, "Time A", "TMA", null);
        createTeam(categoryId, "Time B", "TMB", null);

        mockMvc.perform(put(TEAMS_URL + "/" + firstTeamId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(teamBody(categoryId, "Time B", "TMB", null)))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void create_withInvalidBody_returnsValidationErrors() throws Exception {
        Map<String, Object> invalid = new HashMap<>();
        invalid.put("name", "");

        mockMvc.perform(post(TEAMS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalid)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields[?(@.field == 'name')]").exists())
                .andExpect(jsonPath("$.fields[?(@.field == 'categoryId')]").exists());
    }

    @Test
    void create_requiresAuthentication() throws Exception {
        mockMvc.perform(post(TEAMS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(teamBody(UUID.randomUUID().toString(),
                                "Time Sem Auth", null, null)))
                .andExpect(status().isForbidden());
    }

    @Test
    void update_requiresAuthentication() throws Exception {
        mockMvc.perform(put(TEAMS_URL + "/" + UUID.randomUUID())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(teamBody(UUID.randomUUID().toString(),
                                "Time Sem Auth", null, null)))
                .andExpect(status().isForbidden());
    }

    private int indexOfName(JsonNode array, String name) {
        for (int i = 0; i < array.size(); i++) {
            if (name.equals(array.get(i).path("name").asText())) {
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

    private String createTeam(String categoryId, String name,
                              String shortName, String logoUrl) throws Exception {
        MvcResult result = mockMvc.perform(post(TEAMS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(teamBody(categoryId, name, shortName, logoUrl)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.categoryId").value(categoryId))
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
        fields.put("abbreviation", "TEAM");
        fields.put("organizationType", "ASSOCIATION");
        fields.put("email", "contato@team.org.br");
        fields.put("phone", "11999999999");
        fields.put("website", "https://team.org.br");
        fields.put("instagram", "team.flag");
        fields.put("country", "BR");
        fields.put("state", "São Paulo");
        fields.put("city", "São Paulo");
        fields.put("logoUrl", "https://team.org.br/logo.png");
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
        fields.put("description", "Campeonato para times");
        fields.put("startDate", "2026-01-15");
        fields.put("endDate", "2026-06-30");
        return objectMapper.writeValueAsString(fields);
    }

    private String categoryBody(String competitionId, String name) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("competitionId", competitionId);
        fields.put("modalityId", firstModalityId());
        fields.put("gender", "MALE");
        fields.put("ageGroup", "ADULT");
        fields.put("name", name);
        return objectMapper.writeValueAsString(fields);
    }

    private String firstModalityId() throws Exception {
        MvcResult result = mockMvc.perform(get(MODALITIES_URL))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").isNotEmpty())
                .andReturn();
        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        return body.get(0).path("id").asText();
    }

    private String teamBody(String categoryId, String name,
                            String shortName, String logoUrl) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("categoryId", categoryId);
        fields.put("name", name);
        if (shortName != null) {
            fields.put("shortName", shortName);
        }
        if (logoUrl != null) {
            fields.put("logoUrl", logoUrl);
        }
        return objectMapper.writeValueAsString(fields);
    }

}
