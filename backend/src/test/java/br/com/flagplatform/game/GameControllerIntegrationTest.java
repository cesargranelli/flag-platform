package br.com.flagplatform.game;

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
class GameControllerIntegrationTest {

    private static final String ORGANIZATIONS_URL = "/api/v1/organizations";
    private static final String COMPETITIONS_URL = "/api/v1/competitions";
    private static final String CATEGORIES_URL = "/api/v1/categories";
    private static final String ROUNDS_URL = "/api/v1/rounds";
    private static final String TEAMS_URL = "/api/v1/teams";
    private static final String VENUES_URL = "/api/v1/venues";
    private static final String GAMES_URL = "/api/v1/games";

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
    void create_game_returnsCreatedWithScheduledStatus() throws Exception {
        Chain chain = setupChain("CREATE");

        mockMvc.perform(post(GAMES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                                chain.venueId, "2026-02-01T19:00:00")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.roundId").value(chain.roundId))
                .andExpect(jsonPath("$.homeTeamId").value(chain.homeTeamId))
                .andExpect(jsonPath("$.awayTeamId").value(chain.awayTeamId))
                .andExpect(jsonPath("$.venueId").value(chain.venueId))
                .andExpect(jsonPath("$.scheduledAt").value("2026-02-01T19:00:00"))
                .andExpect(jsonPath("$.status").value("SCHEDULED"))
                .andExpect(jsonPath("$.createdAt").isNotEmpty());
    }

    @Test
    @WithMockUser
    void create_withUnknownRound_returnsNotFound() throws Exception {
        mockMvc.perform(post(GAMES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(UUID.randomUUID().toString(),
                                UUID.randomUUID().toString(), UUID.randomUUID().toString(),
                                null, "2026-02-01T19:00:00")))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser
    void create_withUnknownTeam_returnsNotFound() throws Exception {
        Chain chain = setupChain("TEAM_NF");

        mockMvc.perform(post(GAMES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(chain.roundId, chain.homeTeamId,
                                UUID.randomUUID().toString(), null, "2026-02-01T19:00:00")))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser
    void create_withUnknownVenue_returnsNotFound() throws Exception {
        Chain chain = setupChain("VENUE_NF");

        mockMvc.perform(post(GAMES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                                UUID.randomUUID().toString(), "2026-02-01T19:00:00")))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser
    void create_withSameHomeAndAwayTeam_returnsBadRequest() throws Exception {
        Chain chain = setupChain("SAME_TEAM");

        mockMvc.perform(post(GAMES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(chain.roundId, chain.homeTeamId, chain.homeTeamId,
                                null, "2026-02-01T19:00:00")))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser
    void listByRound_returnsGamesOrderedByScheduledAt_publicAccess() throws Exception {
        Chain chain = setupChain("ORDER");

        String thirdTeamId = createTeam(chain.categoryId, "Time Extra 1 ORDER", "TEX1", null);
        String fourthTeamId = createTeam(chain.categoryId, "Time Extra 2 ORDER", "TEX2", null);

        String laterGameId = createGame(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                null, "2026-02-01T19:00:00");
        String earlierGameId = createGame(chain.roundId, thirdTeamId, fourthTeamId,
                null, "2026-02-01T15:00:00");

        MvcResult result = mockMvc.perform(get(ROUNDS_URL + "/" + chain.roundId + "/games"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0].status").value("SCHEDULED"))
                .andReturn();

        JsonNode array = objectMapper.readTree(result.getResponse().getContentAsString());
        int earlierIndex = indexOfId(array, earlierGameId);
        int laterIndex = indexOfId(array, laterGameId);

        assertThat(earlierIndex).isNotNegative();
        assertThat(laterIndex).isNotNegative();
        assertThat(earlierIndex).isLessThan(laterIndex);
    }

    @Test
    void listByRound_unknownRound_returnsEmptyList_publicAccess() throws Exception {
        mockMvc.perform(get(ROUNDS_URL + "/" + UUID.randomUUID() + "/games"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$").isEmpty());
    }

    @Test
    @WithMockUser
    void getById_returnsGame_publicAccess() throws Exception {
        Chain chain = setupChain("GET_BY_ID");

        String gameId = createGame(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                chain.venueId, "2026-02-01T19:00:00");

        mockMvc.perform(get(GAMES_URL + "/" + gameId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(gameId))
                .andExpect(jsonPath("$.roundId").value(chain.roundId))
                .andExpect(jsonPath("$.homeTeamId").value(chain.homeTeamId))
                .andExpect(jsonPath("$.awayTeamId").value(chain.awayTeamId))
                .andExpect(jsonPath("$.venueId").value(chain.venueId))
                .andExpect(jsonPath("$.scheduledAt").value("2026-02-01T19:00:00"))
                .andExpect(jsonPath("$.status").value("SCHEDULED"));
    }

    @Test
    void getById_unknownId_returnsNotFound() throws Exception {
        mockMvc.perform(get(GAMES_URL + "/" + UUID.randomUUID()))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser
    void update_changesScheduledAtAndVenue() throws Exception {
        Chain chain = setupChain("UPDATE");

        String gameId = createGame(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                null, "2026-02-01T19:00:00");

        mockMvc.perform(put(GAMES_URL + "/" + gameId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                                chain.venueId, "2026-02-01T21:00:00")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(gameId))
                .andExpect(jsonPath("$.roundId").value(chain.roundId))
                .andExpect(jsonPath("$.homeTeamId").value(chain.homeTeamId))
                .andExpect(jsonPath("$.awayTeamId").value(chain.awayTeamId))
                .andExpect(jsonPath("$.venueId").value(chain.venueId))
                .andExpect(jsonPath("$.scheduledAt").value("2026-02-01T21:00:00"))
                .andExpect(jsonPath("$.status").value("SCHEDULED"));
    }

    @Test
    @WithMockUser
    void update_unknownId_returnsNotFound() throws Exception {
        Chain chain = setupChain("UPDATE_NF");

        mockMvc.perform(put(GAMES_URL + "/" + UUID.randomUUID())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                                null, "2026-02-01T19:00:00")))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser
    void create_withInvalidBody_returnsValidationErrors() throws Exception {
        Map<String, Object> invalid = new HashMap<>();
        invalid.put("roundId", null);
        invalid.put("homeTeamId", null);
        invalid.put("awayTeamId", null);
        invalid.put("scheduledAt", null);

        mockMvc.perform(post(GAMES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalid)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields[?(@.field == 'roundId')]").exists())
                .andExpect(jsonPath("$.fields[?(@.field == 'homeTeamId')]").exists())
                .andExpect(jsonPath("$.fields[?(@.field == 'awayTeamId')]").exists())
                .andExpect(jsonPath("$.fields[?(@.field == 'scheduledAt')]").exists());
    }

    @Test
    void create_requiresAuthentication() throws Exception {
        mockMvc.perform(post(GAMES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(UUID.randomUUID().toString(),
                                UUID.randomUUID().toString(), UUID.randomUUID().toString(),
                                null, "2026-02-01T19:00:00")))
                .andExpect(status().isForbidden());
    }

    @Test
    void update_requiresAuthentication() throws Exception {
        mockMvc.perform(put(GAMES_URL + "/" + UUID.randomUUID())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(UUID.randomUUID().toString(),
                                UUID.randomUUID().toString(), UUID.randomUUID().toString(),
                                null, "2026-02-01T19:00:00")))
                .andExpect(status().isForbidden());
    }

    private int indexOfId(JsonNode array, String id) {
        for (int i = 0; i < array.size(); i++) {
            if (id.equals(array.get(i).path("id").asText())) {
                return i;
            }
        }
        return -1;
    }

    private Chain setupChain(String suffix) throws Exception {
        String organizationId = createOrganization(
                "GAME_" + suffix, "Associação de Flag " + suffix);
        String competitionId = createCompetition(
                organizationId, "COMP_GAME_" + suffix + " TAÇA");
        String categoryId = createCategory(competitionId, "CAT_Masculino 5x5");

        String roundId = createRound(categoryId, 1, "Primeira Rodada " + suffix, "REGULAR");
        String homeTeamId = createTeam(categoryId, "Tritões " + suffix, "TRI", null);
        String awayTeamId = createTeam(categoryId, "Águias " + suffix, "AGU", null);
        String venueId = createVenue(organizationId, "Arena " + suffix, "Rua A, 1", null);

        return new Chain(categoryId, roundId, homeTeamId, awayTeamId, venueId);
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

    private String createVenue(String organizationId, String name,
                               String address, String mapsUrl) throws Exception {
        MvcResult result = mockMvc.perform(post(VENUES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(venueBody(organizationId, name, address, mapsUrl)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.organizationId").value(organizationId))
                .andExpect(jsonPath("$.name").value(name))
                .andReturn();

        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        return body.path("id").asText();
    }

    private String createGame(String roundId, String homeTeamId, String awayTeamId,
                              String venueId, String scheduledAt) throws Exception {
        MvcResult result = mockMvc.perform(post(GAMES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(roundId, homeTeamId, awayTeamId, venueId, scheduledAt)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.roundId").value(roundId))
                .andExpect(jsonPath("$.homeTeamId").value(homeTeamId))
                .andExpect(jsonPath("$.awayTeamId").value(awayTeamId))
                .andExpect(jsonPath("$.status").value("SCHEDULED"))
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
        fields.put("abbreviation", "GAME");
        fields.put("organizationType", "ASSOCIATION");
        fields.put("email", "contato@game.org.br");
        fields.put("phone", "11999999999");
        fields.put("website", "https://game.org.br");
        fields.put("instagram", "game.flag");
        fields.put("country", "BR");
        fields.put("state", "São Paulo");
        fields.put("city", "São Paulo");
        fields.put("logoUrl", "https://game.org.br/logo.png");
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
        fields.put("description", "Campeonato para jogos");
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

    private String venueBody(String organizationId, String name,
                             String address, String mapsUrl) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("organizationId", organizationId);
        fields.put("name", name);
        if (address != null) {
            fields.put("address", address);
        }
        if (mapsUrl != null) {
            fields.put("mapsUrl", mapsUrl);
        }
        return objectMapper.writeValueAsString(fields);
    }

    private String gameBody(String roundId, String homeTeamId, String awayTeamId,
                            String venueId, String scheduledAt) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("roundId", roundId);
        fields.put("homeTeamId", homeTeamId);
        fields.put("awayTeamId", awayTeamId);
        if (venueId != null) {
            fields.put("venueId", venueId);
        }
        fields.put("scheduledAt", scheduledAt);
        return objectMapper.writeValueAsString(fields);
    }

    private record Chain(String categoryId, String roundId, String homeTeamId,
                         String awayTeamId, String venueId) {
    }

}
