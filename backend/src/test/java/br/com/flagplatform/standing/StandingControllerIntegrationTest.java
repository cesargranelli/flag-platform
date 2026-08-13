package br.com.flagplatform.standing;

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

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@ActiveProfiles("test")
class StandingControllerIntegrationTest {

    private static final String ORGANIZATIONS_URL = "/api/v1/organizations";
    private static final String COMPETITIONS_URL = "/api/v1/competitions";
    private static final String CATEGORIES_URL = "/api/v1/categories";
    private static final String ROUNDS_URL = "/api/v1/rounds";
    private static final String TEAMS_URL = "/api/v1/teams";
    private static final String GAMES_URL = "/api/v1/games";
    private static final String STANDINGS_URL = "/api/v1/categories/%s/standings";

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
    void getStandings_returnsOrderedTable_publicAccess() throws Exception {
        Chain chain = setupStandings("ORDER");

        // Time A 5x2 Time B
        String game1 = createGame(chain.roundId, chain.teamAId, chain.teamBId,
                "2026-02-01T19:00:00");
        patchGameStatus(game1, "IN_PROGRESS");
        registerResult(game1, 5, 2);

        // Time C 3x1 Time B
        String game2 = createGame(chain.roundId, chain.teamCId, chain.teamBId,
                "2026-02-01T20:00:00");
        patchGameStatus(game2, "IN_PROGRESS");
        registerResult(game2, 3, 1);

        // Sem autenticação: endpoint público
        mockMvc.perform(get(STANDINGS_URL.formatted(chain.categoryId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$").value(hasSize(3)))

                // Time A: 1V 0E 0D, 5-2, saldo +3, PTS 3
                .andExpect(jsonPath("$[0].position").value(1))
                .andExpect(jsonPath("$[0].teamId").value(chain.teamAId))
                .andExpect(jsonPath("$[0].teamName").value("Alfa ORDER"))
                .andExpect(jsonPath("$[0].played").value(1))
                .andExpect(jsonPath("$[0].wins").value(1))
                .andExpect(jsonPath("$[0].draws").value(0))
                .andExpect(jsonPath("$[0].losses").value(0))
                .andExpect(jsonPath("$[0].goalsFor").value(5))
                .andExpect(jsonPath("$[0].goalsAgainst").value(2))
                .andExpect(jsonPath("$[0].goalDifference").value(3))
                .andExpect(jsonPath("$[0].points").value(3))

                // Time C: 1V 0E 0D, 3-1, saldo +2, PTS 3 (mesmos pontos do A,
                // saldo menor, então fica atrás)
                .andExpect(jsonPath("$[1].position").value(2))
                .andExpect(jsonPath("$[1].teamId").value(chain.teamCId))
                .andExpect(jsonPath("$[1].teamName").value("Charlie ORDER"))
                .andExpect(jsonPath("$[1].points").value(3))
                .andExpect(jsonPath("$[1].goalDifference").value(2))

                // Time B: 0V 0E 2D, 3-8, saldo -5, PTS 0
                .andExpect(jsonPath("$[2].position").value(3))
                .andExpect(jsonPath("$[2].teamId").value(chain.teamBId))
                .andExpect(jsonPath("$[2].teamName").value("Bravo ORDER"))
                .andExpect(jsonPath("$[2].played").value(2))
                .andExpect(jsonPath("$[2].wins").value(0))
                .andExpect(jsonPath("$[2].draws").value(0))
                .andExpect(jsonPath("$[2].losses").value(2))
                .andExpect(jsonPath("$[2].goalsFor").value(3))
                .andExpect(jsonPath("$[2].goalsAgainst").value(8))
                .andExpect(jsonPath("$[2].goalDifference").value(-5))
                .andExpect(jsonPath("$[2].points").value(0));
    }

    @Test
    @WithMockUser
    void getStandings_withDraw_accumulatesPointForDraw() throws Exception {
        Chain chain = setupStandings("DRAW");

        // Time A 2x2 Time B (empate: 1 ponto para cada)
        String game1 = createGame(chain.roundId, chain.teamAId, chain.teamBId,
                "2026-02-01T19:00:00");
        patchGameStatus(game1, "IN_PROGRESS");
        registerResult(game1, 2, 2);

        // Time C 1x0 Time A
        String game2 = createGame(chain.roundId, chain.teamCId, chain.teamAId,
                "2026-02-01T20:00:00");
        patchGameStatus(game2, "IN_PROGRESS");
        registerResult(game2, 1, 0);

        mockMvc.perform(get(STANDINGS_URL.formatted(chain.categoryId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").value(hasSize(3)))

                // Time C: 1V 0E 0D, PTS 3
                .andExpect(jsonPath("$[0].teamName").value("Charlie DRAW"))
                .andExpect(jsonPath("$[0].points").value(3))
                .andExpect(jsonPath("$[0].goalDifference").value(1))

                // Time B: 0V 1E 0D, PTS 1 (empate vale 1 ponto: 0*3 + 1*1);
                // desempate por saldo: B tem 2-2 (saldo 0), A tem 2-3 (saldo -1)
                .andExpect(jsonPath("$[1].teamName").value("Bravo DRAW"))
                .andExpect(jsonPath("$[1].wins").value(0))
                .andExpect(jsonPath("$[1].draws").value(1))
                .andExpect(jsonPath("$[1].losses").value(0))
                .andExpect(jsonPath("$[1].points").value(1))
                .andExpect(jsonPath("$[1].goalDifference").value(0))

                // Time A: 0V 1E 1D, PTS 1 (empate vale 1 ponto), saldo -1
                .andExpect(jsonPath("$[2].teamName").value("Alfa DRAW"))
                .andExpect(jsonPath("$[2].draws").value(1))
                .andExpect(jsonPath("$[2].losses").value(1))
                .andExpect(jsonPath("$[2].points").value(1))
                .andExpect(jsonPath("$[2].goalDifference").value(-1));
    }

    @Test
    void getStandings_unknownCategory_returnsEmptyList_publicAccess() throws Exception {
        mockMvc.perform(get(STANDINGS_URL.formatted(UUID.randomUUID())))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$").isEmpty());
    }

    private Chain setupStandings(String suffix) throws Exception {
        String organizationId = createOrganization(
                "STAND_" + suffix, "Associação de Flag " + suffix);
        String competitionId = createCompetition(
                organizationId, "COMP_STAND_" + suffix + " TAÇA");
        String categoryId = createCategory(competitionId, "CAT_Masculino 5x5");

        String roundId = createRound(categoryId, 1, "Primeira Rodada " + suffix, "REGULAR");
        String teamAId = createTeam(categoryId, "Alfa " + suffix, "ALF", null);
        String teamBId = createTeam(categoryId, "Bravo " + suffix, "BRA", null);
        String teamCId = createTeam(categoryId, "Charlie " + suffix, "CHA", null);

        return new Chain(categoryId, roundId, teamAId, teamBId, teamCId);
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

    private String createRound(String categoryId, int number, String name,
                               String type) throws Exception {
        MvcResult result = mockMvc.perform(post(ROUNDS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(roundBody(categoryId, number, name, type)))
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

    private String createGame(String roundId, String homeTeamId, String awayTeamId,
                              String scheduledAt) throws Exception {
        MvcResult result = mockMvc.perform(post(GAMES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(roundId, homeTeamId, awayTeamId, scheduledAt)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andReturn();

        return readId(result);
    }

    private String readId(MvcResult result) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString())
                .path("id").asText();
    }

    private String organizationBody(String tradeName, String legalName) throws Exception {
        return objectMapper.writeValueAsString(organizationFields(tradeName, legalName));
    }

    private Map<String, Object> organizationFields(String tradeName, String legalName) {
        Map<String, Object> fields = new HashMap<>();
        fields.put("legalName", legalName);
        fields.put("tradeName", tradeName);
        fields.put("abbreviation", "STAND");
        fields.put("organizationType", "ASSOCIATION");
        fields.put("email", "contato@stand.org.br");
        fields.put("phone", "11999999999");
        fields.put("website", "https://stand.org.br");
        fields.put("instagram", "stand.flag");
        fields.put("country", "BR");
        fields.put("state", "São Paulo");
        fields.put("city", "São Paulo");
        fields.put("logoUrl", "https://stand.org.br/logo.png");
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
        fields.put("description", "Campeonato para classificacao");
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

    private String gameBody(String roundId, String homeTeamId, String awayTeamId,
                            String scheduledAt) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("roundId", roundId);
        fields.put("homeTeamId", homeTeamId);
        fields.put("awayTeamId", awayTeamId);
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

    private String statusBody(String status) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("status", status);
        return objectMapper.writeValueAsString(fields);
    }

    private String resultBody(int homeScore, int awayScore) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("homeScore", homeScore);
        fields.put("awayScore", awayScore);
        return objectMapper.writeValueAsString(fields);
    }

    private record Chain(String categoryId, String roundId, String teamAId,
                         String teamBId, String teamCId) {
    }

}
