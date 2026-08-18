package br.com.flagplatform.checkin;

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

import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@ActiveProfiles("test")
class CheckInControllerIntegrationTest {

    private static final String ORGANIZATIONS_URL = "/api/v1/organizations";
    private static final String COMPETITIONS_URL = "/api/v1/competitions";
    private static final String CATEGORIES_URL = "/api/v1/categories";
    private static final String MODALITIES_URL = "/api/v1/modalities";
    private static final String ROUNDS_URL = "/api/v1/rounds";
    private static final String TEAMS_URL = "/api/v1/teams";
    private static final String VENUES_URL = "/api/v1/venues";
    private static final String GAMES_URL = "/api/v1/games";
    private static final String ATHLETES_URL = "/api/v1/athletes";
    private static final String ROSTER_URL = "/api/v1/teams/%s/roster";
    private static final String CHECKIN_URL = "/api/v1/games/%s/checkin";
    private static final String AUTH_URL = "/api/v1/auth";

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
    @WithMockUser(username = "mesa-list@exemplo.com", roles = {"ORGANIZER", "MESA"})
    void getCheckinList_returnsBothTeamsRosters() throws Exception {
        Chain chain = setupChain("LIST");
        registerUser("mesa-list@exemplo.com");

        String homeAthlete = createAthlete("João Silva", "João", "QB", 7, null);
        String awayAthlete = createAthlete("Bia Santos", "Bia", "DB", 21, null);
        addToRoster(chain.teamAId, homeAthlete);
        addToRoster(chain.teamBId, awayAthlete);
        String gameId = createGame(chain.roundId, chain.teamAId, chain.teamBId);

        mockMvc.perform(get(CHECKIN_URL.formatted(gameId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$.length()").value(2))
                .andExpect(jsonPath("$[0].athleteName").value("João Silva"))
                .andExpect(jsonPath("$[0].status").isEmpty())
                .andExpect(jsonPath("$[1].athleteName").value("Bia Santos"));
    }

    @Test
    @WithMockUser(username = "mesa-present@exemplo.com", roles = {"ORGANIZER", "MESA"})
    void checkin_marksPresent_andRegistersValidatedBy() throws Exception {
        Chain chain = setupChain("PRESENT");
        registerUser("mesa-present@exemplo.com");

        String homeAthlete = createAthlete("João Silva", "João", "QB", 7, null);
        addToRoster(chain.teamAId, homeAthlete);
        String gameId = createGame(chain.roundId, chain.teamAId, chain.teamBId);

        mockMvc.perform(post(CHECKIN_URL.formatted(gameId) + "/" + homeAthlete)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(checkInBody("PRESENT")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("PRESENT"))
                .andExpect(jsonPath("$.validatedBy").isNotEmpty())
                .andExpect(jsonPath("$.validatedAt").isNotEmpty());

        mockMvc.perform(get(CHECKIN_URL.formatted(gameId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].status").value("PRESENT"))
                .andExpect(jsonPath("$[0].validatedBy").isNotEmpty());
    }

    @Test
    @WithMockUser(username = "mesa-mn@exemplo.com", roles = {"ORGANIZER", "MESA"})
    void setMatchNumber_definesOverride_withoutChangingOfficial() throws Exception {
        Chain chain = setupChain("MN_DEFINE");
        registerUser("mesa-mn@exemplo.com");

        String homeAthlete = createAthlete("João Silva", "João", "QB", 7, null);
        addToRoster(chain.teamAId, homeAthlete);
        String gameId = createGame(chain.roundId, chain.teamAId, chain.teamBId);

        mockMvc.perform(put(CHECKIN_URL.formatted(gameId) + "/" + homeAthlete + "/match-number")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(matchNumberBody(10)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.number").value(10))
                .andExpect(jsonPath("$.athleteNumber").value(7))
                .andExpect(jsonPath("$.matchNumber").value(10));

        mockMvc.perform(get(CHECKIN_URL.formatted(gameId)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].number").value(10))
                .andExpect(jsonPath("$[0].athleteNumber").value(7))
                .andExpect(jsonPath("$[0].matchNumber").value(10));
    }

    @Test
    @WithMockUser(username = "mesa-mnclr@exemplo.com", roles = {"ORGANIZER", "MESA"})
    void setMatchNumber_clearOverride_returnsOfficial() throws Exception {
        Chain chain = setupChain("MN_CLEAR");
        registerUser("mesa-mnclr@exemplo.com");

        String homeAthlete = createAthlete("João Silva", "João", "QB", 7, null);
        addToRoster(chain.teamAId, homeAthlete);
        String gameId = createGame(chain.roundId, chain.teamAId, chain.teamBId);

        mockMvc.perform(put(CHECKIN_URL.formatted(gameId) + "/" + homeAthlete + "/match-number")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(matchNumberBody(10)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.matchNumber").value(10));

        mockMvc.perform(put(CHECKIN_URL.formatted(gameId) + "/" + homeAthlete + "/match-number")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(matchNumberBody(null)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.matchNumber").isEmpty())
                .andExpect(jsonPath("$.number").value(7))
                .andExpect(jsonPath("$.athleteNumber").value(7));
    }

    @Test
    @WithMockUser(username = "mesa-mndup@exemplo.com", roles = {"ORGANIZER", "MESA"})
    void setMatchNumber_duplicateInSameTeam_returnsConflict() throws Exception {
        Chain chain = setupChain("MN_DUP");
        registerUser("mesa-mndup@exemplo.com");

        String athleteA = createAthlete("João Silva", "João", "QB", 7, null);
        String athleteB = createAthlete("Pedro Souza", "Pedro", "RB", 21, null);
        addToRoster(chain.teamAId, athleteA);
        addToRoster(chain.teamAId, athleteB);
        String gameId = createGame(chain.roundId, chain.teamAId, chain.teamBId);

        mockMvc.perform(put(CHECKIN_URL.formatted(gameId) + "/" + athleteA + "/match-number")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(matchNumberBody(10)))
                .andExpect(status().isOk());

        mockMvc.perform(put(CHECKIN_URL.formatted(gameId) + "/" + athleteB + "/match-number")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(matchNumberBody(10)))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser(username = "mesa-notin@exemplo.com", roles = {"ORGANIZER", "MESA"})
    void checkin_athleteNotInRosters_returnsBadRequest() throws Exception {
        Chain chain = setupChain("NOT_IN");
        registerUser("mesa-notin@exemplo.com");

        String outsider = createAthlete("Zeca Silva", "Zeca", "WR", null, null);
        String gameId = createGame(chain.roundId, chain.teamAId, chain.teamBId);

        mockMvc.perform(post(CHECKIN_URL.formatted(gameId) + "/" + outsider)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(checkInBody("PRESENT")))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(username = "mesa@exemplo.com", roles = {"ORGANIZER", "MESA"})
    void getCheckinList_unknownGame_returnsNotFound() throws Exception {
        mockMvc.perform(get(CHECKIN_URL.formatted(UUID.randomUUID())))
                .andExpect(status().isNotFound());
    }

    @Test
    void getCheckinList_anonymous_returnsForbidden() throws Exception {
        mockMvc.perform(get(CHECKIN_URL.formatted(UUID.randomUUID())))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void getCheckinList_withoutMesaRole_returnsForbidden() throws Exception {
        mockMvc.perform(get(CHECKIN_URL.formatted(UUID.randomUUID())))
                .andExpect(status().isForbidden());
    }

    @Test
    void checkin_requiresAuthentication() throws Exception {
        mockMvc.perform(post(CHECKIN_URL.formatted(UUID.randomUUID()) + "/" + UUID.randomUUID())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(checkInBody("PRESENT")))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "mesa-validate@exemplo.com", roles = {"ORGANIZER", "MESA"})
    void validate_duringInProgress_returnsPresent() throws Exception {
        Chain chain = setupChain("VAL_OK");
        registerUser("mesa-validate@exemplo.com");

        String homeAthlete = createAthlete("João Silva", "João", "QB", 7, null);
        addToRoster(chain.teamAId, homeAthlete);
        String gameId = createGame(chain.roundId, chain.teamAId, chain.teamBId);
        patchGameStatus(gameId, "IN_PROGRESS");

        mockMvc.perform(post(CHECKIN_URL.formatted(gameId) + "/" + homeAthlete + "/validate"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("PRESENT"))
                .andExpect(jsonPath("$.teamId").value(chain.teamAId))
                .andExpect(jsonPath("$.validatedBy").isNotEmpty())
                .andExpect(jsonPath("$.validatedAt").isNotEmpty());
    }

    @Test
    @WithMockUser(username = "mesa-notreg@exemplo.com", roles = {"ORGANIZER", "MESA"})
    void validate_athleteNotInRoster_returnsNotRegistered() throws Exception {
        Chain chain = setupChain("VAL_NR");
        registerUser("mesa-notreg@exemplo.com");

        String outsider = createAthlete("Zeca Silva", "Zeca", "WR", null, null);
        String gameId = createGame(chain.roundId, chain.teamAId, chain.teamBId);
        patchGameStatus(gameId, "IN_PROGRESS");

        mockMvc.perform(post(CHECKIN_URL.formatted(gameId) + "/" + outsider + "/validate"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("NOT_REGISTERED"))
                .andExpect(jsonPath("$.teamId").doesNotExist());
    }

    @Test
    @WithMockUser(username = "mesa-sched@exemplo.com", roles = {"ORGANIZER", "MESA"})
    void validate_whenGameScheduled_returnsConflict() throws Exception {
        Chain chain = setupChain("VAL_SCHED");
        registerUser("mesa-sched@exemplo.com");

        String homeAthlete = createAthlete("João Silva", "João", "QB", 7, null);
        addToRoster(chain.teamAId, homeAthlete);
        String gameId = createGame(chain.roundId, chain.teamAId, chain.teamBId);

        mockMvc.perform(post(CHECKIN_URL.formatted(gameId) + "/" + homeAthlete + "/validate"))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser(username = "mesa-val@exemplo.com", roles = {"ORGANIZER", "MESA"})
    void getValidations_returnsRosterWithValidationStatus() throws Exception {
        Chain chain = setupChain("VAL_LIST");
        registerUser("mesa-val@exemplo.com");

        String homeAthlete = createAthlete("João Silva", "João", "QB", 7, null);
        addToRoster(chain.teamAId, homeAthlete);
        String gameId = createGame(chain.roundId, chain.teamAId, chain.teamBId);
        patchGameStatus(gameId, "IN_PROGRESS");
        validateAthlete(gameId, homeAthlete);

        mockMvc.perform(get("/api/v1/games/" + gameId + "/validations"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[0].status").value("PRESENT"));
    }

    @Test
    void getValidations_anonymous_isPublic() throws Exception {
        mockMvc.perform(get("/api/v1/games/" + UUID.randomUUID() + "/validations"))
                .andExpect(status().isNotFound());
    }

    private void registerUser(String email) throws Exception {
        mockMvc.perform(post(AUTH_URL + "/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerBody("Mesa Exemplo", email, "segredo123")))
                .andExpect(status().isCreated());
    }

    private Chain setupChain(String suffix) throws Exception {
        String organizationId = createOrganization(
                "CHK_" + suffix, "Associação de Flag " + suffix);
        String competitionId = createCompetition(
                organizationId, "COMP_CHK_" + suffix + " TAÇA");
        String categoryId = createCategory(competitionId, "CAT_Masculino 5x5");
        String roundId = createRound(categoryId, 1, "Primeira Rodada " + suffix, "REGULAR");
        String teamAId = createTeam(categoryId, "Tritões " + suffix, "TRI", null);
        String teamBId = createTeam(categoryId, "Águias " + suffix, "AGU", null);

        return new Chain(roundId, teamAId, teamBId);
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

    private void addToRoster(String teamId, String athleteId) throws Exception {
        mockMvc.perform(post(ROSTER_URL.formatted(teamId))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(rosterBody(athleteId)))
                .andExpect(status().isCreated());
    }

    private void patchGameStatus(String gameId, String status) throws Exception {
        mockMvc.perform(patch(GAMES_URL + "/" + gameId + "/status")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(checkInBody(status)))
                .andExpect(status().isOk());
    }

    private void validateAthlete(String gameId, String athleteId) throws Exception {
        mockMvc.perform(post(CHECKIN_URL.formatted(gameId) + "/" + athleteId + "/validate"))
                .andExpect(status().isOk());
    }

    private String createGame(String roundId, String homeTeamId, String awayTeamId) throws Exception {
        MvcResult result = mockMvc.perform(post(GAMES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(roundId, homeTeamId, awayTeamId)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andReturn();

        return readId(result);
    }

    private String readId(MvcResult result) throws Exception {
        return objectMapper.readTree(result.getResponse().getContentAsString())
                .path("id").asText();
    }

    private String registerBody(String name, String email, String password) throws Exception {
        return objectMapper.writeValueAsString(Map.of(
                "name", name,
                "email", email,
                "password", password));
    }

    private String checkInBody(String status) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("status", status);
        return objectMapper.writeValueAsString(fields);
    }

    private String rosterBody(String athleteId) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("athleteId", athleteId);
        return objectMapper.writeValueAsString(fields);
    }

    private String organizationBody(String tradeName, String legalName) throws Exception {
        return objectMapper.writeValueAsString(organizationFields(tradeName, legalName));
    }

    private Map<String, Object> organizationFields(String tradeName, String legalName) {
        Map<String, Object> fields = new HashMap<>();
        fields.put("legalName", legalName);
        fields.put("tradeName", tradeName);
        fields.put("abbreviation", "CHK");
        fields.put("organizationType", "ASSOCIATION");
        fields.put("email", "contato@chk.org.br");
        fields.put("phone", "11999999999");
        fields.put("website", "https://chk.org.br");
        fields.put("instagram", "chk.flag");
        fields.put("country", "BR");
        fields.put("state", "São Paulo");
        fields.put("city", "São Paulo");
        fields.put("logoUrl", "https://chk.org.br/logo.png");
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
        fields.put("description", "Campeonato para check-in");
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

    private String gameBody(String roundId, String homeTeamId, String awayTeamId) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("roundId", roundId);
        fields.put("homeTeamId", homeTeamId);
        fields.put("awayTeamId", awayTeamId);
        fields.put("scheduledAt", "2026-02-01T19:00:00");
        return objectMapper.writeValueAsString(fields);
    }

    private String matchNumberBody(Integer number) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("number", number);
        return objectMapper.writeValueAsString(fields);
    }

    private record Chain(String roundId, String teamAId, String teamBId) {
    }

}
