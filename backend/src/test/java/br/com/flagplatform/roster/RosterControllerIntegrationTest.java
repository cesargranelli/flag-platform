package br.com.flagplatform.roster;

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
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@ActiveProfiles("test")
class RosterControllerIntegrationTest {

    private static final String ORGANIZATIONS_URL = "/api/v1/organizations";
    private static final String COMPETITIONS_URL = "/api/v1/competitions";
    private static final String CATEGORIES_URL = "/api/v1/categories";
    private static final String MODALITIES_URL = "/api/v1/modalities";
    private static final String TEAMS_URL = "/api/v1/teams";
    private static final String ATHLETES_URL = "/api/v1/athletes";
    private static final String ROSTER_URL = "/api/v1/teams/%s/roster";

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
    void add_list_remove_flow() throws Exception {
        Chain chain = setupChain("FLOW");
        String athleteId = createAthlete("João Silva", "João", "QB", 7, null);

        mockMvc.perform(post(ROSTER_URL.formatted(chain.teamId))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(rosterBody(athleteId, null)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.teamId").value(chain.teamId))
                .andExpect(jsonPath("$.athleteId").value(athleteId))
                .andExpect(jsonPath("$.athleteName").value("João Silva"))
                .andExpect(jsonPath("$.athleteNickname").value("João"))
                .andExpect(jsonPath("$.position").value("QB"))
                .andExpect(jsonPath("$.number").value(7))
                .andExpect(jsonPath("$.status").value("ACTIVE"));

        mockMvc.perform(get(ROSTER_URL.formatted(chain.teamId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].athleteName").value("João Silva"));

        mockMvc.perform(delete(ROSTER_URL.formatted(chain.teamId) + "/" + athleteId))
                .andExpect(status().isNoContent());

        mockMvc.perform(get(ROSTER_URL.formatted(chain.teamId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isEmpty());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void add_duplicateAthlete_returnsConflict() throws Exception {
        Chain chain = setupChain("DUP");
        String athleteId = createAthlete("Ana Souza", "Ana", "RB", 3, null);

        addToRoster(chain.teamId, athleteId, null);

        mockMvc.perform(post(ROSTER_URL.formatted(chain.teamId))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(rosterBody(athleteId, "INACTIVE")))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void add_unknownTeam_returnsNotFound() throws Exception {
        String athleteId = createAthlete("Bia Santos", "Bia", "DB", 21, null);

        mockMvc.perform(post(ROSTER_URL.formatted(UUID.randomUUID()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(rosterBody(athleteId, null)))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void add_unknownAthlete_returnsNotFound() throws Exception {
        Chain chain = setupChain("ATH_NF");

        mockMvc.perform(post(ROSTER_URL.formatted(chain.teamId))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(rosterBody(UUID.randomUUID().toString(), null)))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void list_unknownTeam_returnsNotFound() throws Exception {
        mockMvc.perform(get(ROSTER_URL.formatted(UUID.randomUUID())))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void list_ordersByJerseyNumber_publicAccess() throws Exception {
        Chain chain = setupChain("ORDER");
        String biaId = createAthlete("Bia Santos", "Bia", "DB", 21, null);
        String anaId = createAthlete("Ana Souza", "Ana", "RB", 3, null);
        String zecaId = createAthlete("Zeca Silva", "Zeca", "WR", null, null);

        addToRoster(chain.teamId, biaId, "ACTIVE");
        addToRoster(chain.teamId, anaId, "ACTIVE");
        addToRoster(chain.teamId, zecaId, "ACTIVE");

        MvcResult result = mockMvc.perform(get(ROSTER_URL.formatted(chain.teamId)))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode array = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(array).hasSize(3);
        assertThat(array.get(0).path("athleteName").asText()).isEqualTo("Ana Souza");
        assertThat(array.get(0).path("number").asInt()).isEqualTo(3);
        assertThat(array.get(1).path("athleteName").asText()).isEqualTo("Bia Santos");
        assertThat(array.get(1).path("number").asInt()).isEqualTo(21);
        assertThat(array.get(2).path("athleteName").asText()).isEqualTo("Zeca Silva");
        assertThat(array.get(2).path("number").isNull()).isTrue();
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void batch_importsValidSkipsAlreadyInscribed() throws Exception {
        Chain chain = setupChain("BATCH");
        String a1 = createAthlete("Atleta Um", "Um", "QB", 1, null);
        String a2 = createAthlete("Atleta Dois", "Dois", "RB", 2, null);
        String a3 = createAthlete("Atleta Tres", "Tres", "WR", 3, null);
        addToRoster(chain.teamId, a1, "ACTIVE");

        String body = "{\"athletes\":[" +
                "{\"athleteId\":\"" + a1 + "\"}," +
                "{\"athleteId\":\"" + a2 + "\"}," +
                "{\"athleteId\":\"" + a3 + "\"}" +
                "]}";

        mockMvc.perform(post(ROSTER_URL.formatted(chain.teamId) + "/batch")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.total").value(3))
                .andExpect(jsonPath("$.imported").value(2))
                .andExpect(jsonPath("$.skipped").value(1))
                .andExpect(jsonPath("$.lines[0].status").value("SKIPPED"))
                .andExpect(jsonPath("$.lines[0].reason").value("Atleta já inscrito"))
                .andExpect(jsonPath("$.lines[1].status").value("IMPORTED"))
                .andExpect(jsonPath("$.lines[2].status").value("IMPORTED"));
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void batch_unknownAthlete_reportsInvalid() throws Exception {
        Chain chain = setupChain("BATCH_NF");

        String body = "{\"athletes\":[" +
                "{\"athleteId\":\"" + UUID.randomUUID() + "\"}" +
                "]}";

        mockMvc.perform(post(ROSTER_URL.formatted(chain.teamId) + "/batch")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.imported").value(0))
                .andExpect(jsonPath("$.lines[0].status").value("INVALID"))
                .andExpect(jsonPath("$.lines[0].reason").value("Atleta não encontrado"));
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void remove_unknownEntry_returnsNotFound() throws Exception {
        Chain chain = setupChain("RM_NF");

        mockMvc.perform(delete(ROSTER_URL.formatted(chain.teamId) + "/" + UUID.randomUUID()))
                .andExpect(status().isNotFound());
    }

    @Test
    void add_requiresAuthentication() throws Exception {
        mockMvc.perform(post(ROSTER_URL.formatted(UUID.randomUUID()))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(rosterBody(UUID.randomUUID().toString(), null)))
                .andExpect(status().isForbidden());
    }

    @Test
    void remove_requiresAuthentication() throws Exception {
        mockMvc.perform(delete(ROSTER_URL.formatted(UUID.randomUUID()) + "/" + UUID.randomUUID()))
                .andExpect(status().isForbidden());
    }

    private Chain setupChain(String suffix) throws Exception {
        String organizationId = createOrganization(
                "ROS_" + suffix, "Associação de Flag " + suffix);
        String competitionId = createCompetition(
                organizationId, "COMP_ROS_" + suffix + " TAÇA");
        String categoryId = createCategory(competitionId, "CAT_Masculino 5x5");
        String teamId = createTeam(categoryId, "Tritões " + suffix, "TRI", null);

        return new Chain(teamId);
    }

    private String createOrganization(String tradeName, String legalName) throws Exception {
        MvcResult result = mockMvc.perform(post(ORGANIZATIONS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(organizationBody(tradeName, legalName)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andReturn();

        return readId(result);
    }

    private String createCompetition(String organizationId, String name) throws Exception {
        MvcResult result = mockMvc.perform(post(COMPETITIONS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(competitionBody(organizationId, name)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andReturn();

        return readId(result);
    }

    private String createCategory(String competitionId, String name) throws Exception {
        MvcResult result = mockMvc.perform(post(CATEGORIES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(categoryBody(competitionId, name)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andReturn();

        return readId(result);
    }

    private String createTeam(String categoryId, String name,
                              String shortName, String logoUrl) throws Exception {
        MvcResult result = mockMvc.perform(post(TEAMS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(teamBody(categoryId, name, shortName, logoUrl)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andReturn();

        return readId(result);
    }

    private String createAthlete(String name, String nickname, String position,
                                 Integer number, String photoUrl) throws Exception {
        MvcResult result = mockMvc.perform(post(ATHLETES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(athleteBody(name, nickname, position, number, photoUrl)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andReturn();

        return readId(result);
    }

    private void addToRoster(String teamId, String athleteId, String status) throws Exception {
        mockMvc.perform(post(ROSTER_URL.formatted(teamId))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(rosterBody(athleteId, status)))
                .andExpect(status().isCreated());
    }

    private String readId(MvcResult result) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString())
                .path("id").asText();
    }

    private String rosterBody(String athleteId, String status) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("athleteId", athleteId);
        if (status != null) {
            fields.put("status", status);
        }
        return objectMapper.writeValueAsString(fields);
    }

    private String organizationBody(String tradeName, String legalName) throws Exception {
        return objectMapper.writeValueAsString(organizationFields(tradeName, legalName));
    }

    private Map<String, Object> organizationFields(String tradeName, String legalName) {
        Map<String, Object> fields = new HashMap<>();
        fields.put("legalName", legalName);
        fields.put("tradeName", tradeName);
        fields.put("abbreviation", "ROS");
        fields.put("organizationType", "ASSOCIATION");
        fields.put("document", cnpj("org-" + tradeName));
        fields.put("documentType", "CNPJ");
        fields.put("presidentName", "Maria Silva");
        fields.put("presidentCpf", cpf("pres-" + tradeName));
        fields.put("email", "contato@ros.org.br");
        fields.put("phone", "11999999999");
        fields.put("website", "https://ros.org.br");
        fields.put("instagram", "ros.flag");
        fields.put("country", "BR");
        fields.put("state", "São Paulo");
        fields.put("city", "São Paulo");
        fields.put("logoUrl", "https://ros.org.br/logo.png");
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
        fields.put("description", "Campeonato para roster");
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
        fields.put("document", cnpj("team-" + name));
        fields.put("documentType", "CNPJ");
        if (shortName != null) {
            fields.put("shortName", shortName);
        }
        if (logoUrl != null) {
            fields.put("logoUrl", logoUrl);
        }
        return objectMapper.writeValueAsString(fields);
    }

    private String athleteBody(String name, String nickname, String position,
                               Integer number, String photoUrl) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("name", name);
        fields.put("cpf", cpf(name));
        if (nickname != null) {
            fields.put("nickname", nickname);
        }
        if (position != null) {
            fields.put("position", position);
        }
        if (number != null) {
            fields.put("number", number);
        }
        if (photoUrl != null) {
            fields.put("photoUrl", photoUrl);
        }
        return objectMapper.writeValueAsString(fields);
    }

    private record Chain(String teamId) {
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

    /**
     * Gera um CPF valido e unico a partir de um seed.
     */
    private String cpf(String seed) {
        String base = String.format("%09d",
                Math.abs((seed + "-" + System.nanoTime()).hashCode()) % 1000000000L);
        int[] digits = base.chars().map(c -> c - '0').toArray();
        int d1 = cpfDv(digits, 10);
        int d2 = cpfDv(concat(digits, d1), 11);
        return base + d1 + d2;
    }

    private int cpfDv(int[] digits, int start) {
        int sum = 0;
        for (int i = 0; i < digits.length; i++) {
            sum += digits[i] * (start - i);
        }
        int rest = (sum * 10) % 11;
        return rest == 10 ? 0 : rest;
    }

    private int[] concat(int[] a, int b) {
        int[] r = new int[a.length + 1];
        System.arraycopy(a, 0, r, 0, a.length);
        r[a.length] = b;
        return r;
    }

}
