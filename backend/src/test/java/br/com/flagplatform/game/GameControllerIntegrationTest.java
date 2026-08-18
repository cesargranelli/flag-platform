package br.com.flagplatform.game;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
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
    private static final String MODALITIES_URL = "/api/v1/modalities";
    private static final String ROUNDS_URL = "/api/v1/rounds";
    private static final String TEAMS_URL = "/api/v1/teams";
    private static final String VENUES_URL = "/api/v1/venues";
    private static final String GAMES_URL = "/api/v1/games";

    @Autowired
    private WebApplicationContext context;

    @Autowired
    private JdbcTemplate jdbcTemplate;

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
    @WithMockUser(roles = "ORGANIZER")
    void create_withUnknownRound_returnsNotFound() throws Exception {
        mockMvc.perform(post(GAMES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(UUID.randomUUID().toString(),
                                UUID.randomUUID().toString(), UUID.randomUUID().toString(),
                                null, "2026-02-01T19:00:00")))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void create_withUnknownTeam_returnsNotFound() throws Exception {
        Chain chain = setupChain("TEAM_NF");

        mockMvc.perform(post(GAMES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(chain.roundId, chain.homeTeamId,
                                UUID.randomUUID().toString(), null, "2026-02-01T19:00:00")))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void create_withUnknownVenue_returnsNotFound() throws Exception {
        Chain chain = setupChain("VENUE_NF");

        mockMvc.perform(post(GAMES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                                UUID.randomUUID().toString(), "2026-02-01T19:00:00")))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void create_withSameHomeAndAwayTeam_returnsBadRequest() throws Exception {
        Chain chain = setupChain("SAME_TEAM");

        mockMvc.perform(post(GAMES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(chain.roundId, chain.homeTeamId, chain.homeTeamId,
                                null, "2026-02-01T19:00:00")))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
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
    void listByRound_unknownRound_returnsNotFound() throws Exception {
        mockMvc.perform(get(ROUNDS_URL + "/" + UUID.randomUUID() + "/games"))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void listByCompetition_returnsGamesOrderedByScheduledAt_withTeamAndVenueNames_publicAccess()
            throws Exception {
        Chain chain = setupChain("COMP_GAMES");

        String secondRoundId = createRound(
                chain.categoryId, 2, "Segunda Rodada COMP_GAMES", "REGULAR");
        String thirdTeamId = createTeam(
                chain.categoryId, "Time Extra COMP_GAMES", "TEX", null);
        String fourthTeamId = createTeam(
                chain.categoryId, "Time Extra 2 COMP_GAMES", "TEX2", null);

        String laterGameId = createGame(secondRoundId, chain.homeTeamId, chain.awayTeamId,
                chain.venueId, "2026-02-01T19:00:00");
        String earlierGameId = createGame(chain.roundId, thirdTeamId, fourthTeamId,
                null, "2026-02-01T15:00:00");

        MvcResult result = mockMvc.perform(
                        get(COMPETITIONS_URL + "/" + chain.competitionId + "/games"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andReturn();

        JsonNode array = objectMapper.readTree(result.getResponse().getContentAsString());
        assertThat(array).hasSize(2);

        int earlierIndex = indexOfId(array, earlierGameId);
        int laterIndex = indexOfId(array, laterGameId);
        assertThat(earlierIndex).isNotNegative();
        assertThat(laterIndex).isNotNegative();
        assertThat(earlierIndex).isLessThan(laterIndex);

        JsonNode earlier = array.get(earlierIndex);
        assertThat(earlier.path("roundNumber").asInt()).isEqualTo(1);
        assertThat(earlier.path("homeTeamName").asText()).isEqualTo("Time Extra COMP_GAMES");
        assertThat(earlier.path("awayTeamName").asText()).isEqualTo("Time Extra 2 COMP_GAMES");
        assertThat(earlier.path("venueName").isNull()).isTrue();
        assertThat(earlier.path("venueAddress").isNull()).isTrue();
        assertThat(earlier.path("venueMapsUrl").isNull()).isTrue();
        assertThat(earlier.path("scheduledAt").asText()).isEqualTo("2026-02-01T15:00:00");
        assertThat(earlier.path("status").asText()).isEqualTo("SCHEDULED");

        JsonNode later = array.get(laterIndex);
        assertThat(later.path("roundNumber").asInt()).isEqualTo(2);
        assertThat(later.path("homeTeamName").asText()).isEqualTo("Tritões COMP_GAMES");
        assertThat(later.path("awayTeamName").asText()).isEqualTo("Águias COMP_GAMES");
        assertThat(later.path("venueName").asText()).isEqualTo("Arena COMP_GAMES");
        assertThat(later.path("venueAddress").asText()).isEqualTo("Rua A, 1");
        assertThat(later.path("venueMapsUrl").isNull()).isTrue();
        assertThat(later.path("scheduledAt").asText()).isEqualTo("2026-02-01T19:00:00");
        assertThat(later.path("status").asText()).isEqualTo("SCHEDULED");
    }

    @Test
    void listByCompetition_unknownCompetition_returnsNotFound_publicAccess() throws Exception {
        mockMvc.perform(get(COMPETITIONS_URL + "/" + UUID.randomUUID() + "/games"))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
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
    @WithMockUser(roles = "ORGANIZER")
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
    @WithMockUser(roles = "ORGANIZER")
    void update_unknownId_returnsNotFound() throws Exception {
        Chain chain = setupChain("UPDATE_NF");

        mockMvc.perform(put(GAMES_URL + "/" + UUID.randomUUID())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                                null, "2026-02-01T19:00:00")))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
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

    @Test
    @WithMockUser(roles = {"ORGANIZER", "MESA"})
    void updateStatus_scheduledToInProgress_returnsUpdatedGame() throws Exception {
        Chain chain = setupChain("STATUS_IP");

        String gameId = createGame(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                null, "2026-02-01T19:00:00");

        mockMvc.perform(patch(GAMES_URL + "/" + gameId + "/status")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(statusBody("IN_PROGRESS")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(gameId))
                .andExpect(jsonPath("$.status").value("IN_PROGRESS"));
    }

    @Test
    @WithMockUser(roles = {"ORGANIZER", "MESA"})
    void updateStatus_invalidTransition_returnsConflict() throws Exception {
        Chain chain = setupChain("STATUS_CONFLICT");

        String gameId = createGame(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                null, "2026-02-01T19:00:00");

        patchGameStatus(gameId, "IN_PROGRESS");

        mockMvc.perform(patch(GAMES_URL + "/" + gameId + "/status")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(statusBody("CANCELLED")))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.status").value(409))
                .andExpect(jsonPath("$.message")
                        .value("Cannot transition game status from 'IN_PROGRESS' to 'CANCELLED'."));
    }

    @Test
    @WithMockUser(roles = "MESA")
    void updateStatus_unknownId_returnsNotFound() throws Exception {
        mockMvc.perform(patch(GAMES_URL + "/" + UUID.randomUUID() + "/status")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(statusBody("IN_PROGRESS")))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = {"ORGANIZER", "MESA"})
    void updateStatus_nullStatus_returnsBadRequest() throws Exception {
        Chain chain = setupChain("STATUS_NULL");

        String gameId = createGame(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                null, "2026-02-01T19:00:00");

        Map<String, Object> invalid = new HashMap<>();
        invalid.put("status", null);

        mockMvc.perform(patch(GAMES_URL + "/" + gameId + "/status")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalid)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields[?(@.field == 'status')]").exists());
    }

    @Test
    void updateStatus_requiresAuthentication() throws Exception {
        mockMvc.perform(patch(GAMES_URL + "/" + UUID.randomUUID() + "/status")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(statusBody("IN_PROGRESS")))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = {"ORGANIZER", "MESA"})
    void registerResult_inProgressGame_returnsFinishedGameWithScores() throws Exception {
        Chain chain = setupChain("RESULT_OK");

        String gameId = createGame(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                null, "2026-02-01T19:00:00");
        patchGameStatus(gameId, "IN_PROGRESS");

        mockMvc.perform(post(GAMES_URL + "/" + gameId + "/result")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(resultBody(3, 1)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(gameId))
                .andExpect(jsonPath("$.status").value("FINISHED"))
                .andExpect(jsonPath("$.homeScore").value(3))
                .andExpect(jsonPath("$.awayScore").value(1));
    }

    @Test
    @WithMockUser(roles = {"ORGANIZER", "MESA"})
    void registerResult_scheduledGame_returnsConflict() throws Exception {
        Chain chain = setupChain("RESULT_SCHEDULED");

        String gameId = createGame(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                null, "2026-02-01T19:00:00");

        mockMvc.perform(post(GAMES_URL + "/" + gameId + "/result")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(resultBody(2, 0)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message")
                        .value("Cannot register a result for a game in status 'SCHEDULED'."));
    }

    @Test
    @WithMockUser(roles = {"ORGANIZER", "MESA"})
    void registerResult_finishedGame_returnsConflict() throws Exception {
        Chain chain = setupChain("RESULT_FINISHED");

        String gameId = createGame(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                null, "2026-02-01T19:00:00");
        patchGameStatus(gameId, "IN_PROGRESS");
        registerResult(gameId, 2, 0);

        mockMvc.perform(post(GAMES_URL + "/" + gameId + "/result")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(resultBody(1, 1)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message")
                        .value("Cannot register a result for a game in status 'FINISHED'."));
    }

    @Test
    @WithMockUser(roles = "MESA")
    void registerResult_unknownId_returnsNotFound() throws Exception {
        mockMvc.perform(post(GAMES_URL + "/" + UUID.randomUUID() + "/result")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(resultBody(2, 0)))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = {"ORGANIZER", "MESA"})
    void registerResult_negativeScore_returnsBadRequest() throws Exception {
        Chain chain = setupChain("RESULT_NEGATIVE");

        String gameId = createGame(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                null, "2026-02-01T19:00:00");
        patchGameStatus(gameId, "IN_PROGRESS");

        Map<String, Object> invalid = new HashMap<>();
        invalid.put("homeScore", -1);
        invalid.put("awayScore", 0);

        mockMvc.perform(post(GAMES_URL + "/" + gameId + "/result")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalid)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields[?(@.field == 'homeScore')]").exists());
    }

    @Test
    void registerResult_requiresAuthentication() throws Exception {
        mockMvc.perform(post(GAMES_URL + "/" + UUID.randomUUID() + "/result")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(resultBody(2, 0)))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = {"ORGANIZER", "MESA"})
    void addScoreEvent_inProgressGame_incrementsScore() throws Exception {
        Chain chain = setupChain("SCORE_IP");
        String gameId = createGame(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                null, "2026-02-01T19:00:00");
        patchGameStatus(gameId, "IN_PROGRESS");

        mockMvc.perform(post(GAMES_URL + "/" + gameId + "/score/events")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(scoreEventBody(chain.homeTeamId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.homeScore").value(1));
    }

    @Test
    @WithMockUser(roles = {"ORGANIZER", "MESA"})
    void correctScore_setsScoresDuringInProgress() throws Exception {
        Chain chain = setupChain("SCORE_CORR");
        String gameId = createGame(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                null, "2026-02-01T19:00:00");
        patchGameStatus(gameId, "IN_PROGRESS");

        mockMvc.perform(patch(GAMES_URL + "/" + gameId + "/score")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(scoreCorrectionBody(3, 1)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.homeScore").value(3))
                .andExpect(jsonPath("$.awayScore").value(1));
    }

    @Test
    @WithMockUser(roles = {"ORGANIZER", "MESA"})
    void listScoreEvents_returnsHistory_publicAccess() throws Exception {
        Chain chain = setupChain("SCORE_LIST");
        String gameId = createGame(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                null, "2026-02-01T19:00:00");
        patchGameStatus(gameId, "IN_PROGRESS");

        mockMvc.perform(post(GAMES_URL + "/" + gameId + "/score/events")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(scoreEventBody(chain.homeTeamId)))
                .andExpect(status().isOk());

        mockMvc.perform(get(GAMES_URL + "/" + gameId + "/score/events"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].teamId").value(chain.homeTeamId));
    }

    @Test
    @WithMockUser(roles = {"ORGANIZER", "MESA"})
    void registerResult_recalculatesStandingsForCategory() throws Exception {        Chain chain = setupChain("RESULT_STANDINGS");

        String gameId = createGame(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                null, "2026-02-01T19:00:00");
        patchGameStatus(gameId, "IN_PROGRESS");
        registerResult(gameId, 3, 1);

        // Segundo jogo entre os mesmos times em outra rodada, deixado como
        // SCHEDULED: não deve contar no recálculo automático da classificação.
        String secondRoundId = createRound(chain.categoryId, 2, "Segunda Rodada RESULT_STANDINGS", "REGULAR");
        createGame(secondRoundId, chain.homeTeamId, chain.awayTeamId,
                null, "2026-02-02T19:00:00");

        Integer count = jdbcTemplate.queryForObject(
                "SELECT count(*) FROM platform.standings WHERE category_id = ?",
                Integer.class,
                UUID.fromString(chain.categoryId()));
        assertThat(count).isEqualTo(2);

        Integer played = jdbcTemplate.queryForObject(
                "SELECT played FROM platform.standings WHERE category_id = ? AND team_id = ?",
                Integer.class,
                UUID.fromString(chain.categoryId()),
                UUID.fromString(chain.homeTeamId()));
        assertThat(played).isEqualTo(1);

        Integer points = jdbcTemplate.queryForObject(
                "SELECT points FROM platform.standings WHERE category_id = ? AND team_id = ?",
                Integer.class,
                UUID.fromString(chain.categoryId()),
                UUID.fromString(chain.homeTeamId()));
        assertThat(points).isEqualTo(3);
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

        return new Chain(competitionId, categoryId, roundId, homeTeamId, awayTeamId, venueId);
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
        fields.put("document", cnpj("org-" + tradeName));
        fields.put("documentType", "CNPJ");
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

    private void patchGameStatus(String gameId, String status) throws Exception {
        mockMvc.perform(patch(GAMES_URL + "/" + gameId + "/status")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(statusBody(status)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value(status));
    }

    private void registerResult(String gameId, int homeScore, int awayScore) throws Exception {
        mockMvc.perform(post(GAMES_URL + "/" + gameId + "/result")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(resultBody(homeScore, awayScore)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("FINISHED"));
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void batch_importsGamesSkipsDuplicate() throws Exception {
        Chain chain = setupChain("BATCH_G");
        String thirdTeamId = createTeam(chain.categoryId, "Time B G3", "TBG3", null);
        // Cria um jogo com a mesma combinacao casa/fora do batch para testar o skip.
        createGame(chain.roundId, chain.homeTeamId, chain.awayTeamId,
                chain.venueId, "2026-03-01T19:00:00");

        String body = "{\"games\":[" +
                "{\"homeTeamId\":\"" + chain.homeTeamId + "\"," +
                "\"awayTeamId\":\"" + chain.awayTeamId + "\"," +
                "\"venueId\":\"" + chain.venueId + "\"," +
                "\"scheduledAt\":\"2026-03-01T19:00:00\"}," +
                "{\"homeTeamId\":\"" + chain.homeTeamId + "\"," +
                "\"awayTeamId\":\"" + thirdTeamId + "\"," +
                "\"venueId\":\"" + chain.venueId + "\"," +
                "\"scheduledAt\":\"2026-03-02T19:00:00\"}" +
                "]}";

        mockMvc.perform(post(ROUNDS_URL + "/" + chain.roundId + "/games/batch")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.total").value(2))
                .andExpect(jsonPath("$.imported").value(1))
                .andExpect(jsonPath("$.skipped").value(1))
                .andExpect(jsonPath("$.lines[0].status").value("SKIPPED"))
                .andExpect(jsonPath("$.lines[0].reason").value("Jogo já existe nesta rodada"))
                .andExpect(jsonPath("$.lines[1].status").value("IMPORTED"));
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void batch_sameTeam_reportsInvalid() throws Exception {
        Chain chain = setupChain("BATCH_SAME");

        String body = "{\"games\":[" +
                "{\"homeTeamId\":\"" + chain.homeTeamId + "\"," +
                "\"awayTeamId\":\"" + chain.homeTeamId + "\"," +
                "\"scheduledAt\":\"2026-03-01T19:00:00\"}" +
                "]}";

        mockMvc.perform(post(ROUNDS_URL + "/" + chain.roundId + "/games/batch")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.imported").value(0))
                .andExpect(jsonPath("$.lines[0].status").value("INVALID"))
                .andExpect(jsonPath("$.lines[0].reason")
                        .value("Time da casa deve ser diferente do visitante"));
    }

    private String statusBody(String status) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("status", status);
        return objectMapper.writeValueAsString(fields);
    }    private String resultBody(int homeScore, int awayScore) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("homeScore", homeScore);
        fields.put("awayScore", awayScore);
        return objectMapper.writeValueAsString(fields);
    }

    private String scoreEventBody(String teamId) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("teamId", teamId);
        return objectMapper.writeValueAsString(fields);
    }

    private String scoreCorrectionBody(int homeScore, int awayScore) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("homeScore", homeScore);
        fields.put("awayScore", awayScore);
        return objectMapper.writeValueAsString(fields);
    }

    private record Chain(String competitionId, String categoryId, String roundId,
                         String homeTeamId, String awayTeamId, String venueId) {
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
