package br.com.flagplatform.user;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
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
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Matriz de autorização por roles (ADMIN, ORGANIZER, MESA).
 * <p>
 * Gestão (POST/PUT/DELETE) exige ADMIN ou ORGANIZER.
 * Operação de jogos (status/resultado) exige ADMIN ou MESA.
 * Leitura continua pública. Acesso negado retorna 403.
 */
@SpringBootTest
@ActiveProfiles("test")
class AuthorizationIntegrationTest {

    private static final String ORGANIZATIONS_URL = "/api/v1/organizations";
    private static final String GAMES_URL = "/api/v1/games";
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
    void anonymousManagementWrite_returnsForbidden() throws Exception {
        mockMvc.perform(post(ORGANIZATIONS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(organizationBody("ORG_ANON", "Associação Anônima")))
                .andExpect(status().isForbidden());
    }

    @Test
    void anonymousGameOperation_returnsForbidden() throws Exception {
        mockMvc.perform(patch(GAMES_URL + "/" + UUID.randomUUID() + "/status")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(statusBody("IN_PROGRESS")))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void organizer_managesOrganization() throws Exception {
        mockMvc.perform(post(ORGANIZATIONS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(organizationBody("ORG_ORG", "Associação Organizadora")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void admin_managesOrganization() throws Exception {
        mockMvc.perform(post(ORGANIZATIONS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(organizationBody("ORG_ADM", "Associação Administrada")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty());
    }

    @Test
    @WithMockUser(roles = "MESA")
    void mesa_cannotManageOrganization_returnsForbidden() throws Exception {
        mockMvc.perform(post(ORGANIZATIONS_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(organizationBody("ORG_MESA", "Associação da Mesa")))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "MESA")
    void mesa_operatesGame() throws Exception {
        // Autorizado passa pelo gate de role e chega no serviço (404 = jogo inexistente).
        mockMvc.perform(patch(GAMES_URL + "/" + UUID.randomUUID() + "/status")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(statusBody("IN_PROGRESS")))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void admin_operatesGame() throws Exception {
        mockMvc.perform(post(GAMES_URL + "/" + UUID.randomUUID() + "/result")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(resultBody(2, 0)))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void organizer_cannotOperateGame_returnsForbidden() throws Exception {
        mockMvc.perform(patch(GAMES_URL + "/" + UUID.randomUUID() + "/status")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(statusBody("IN_PROGRESS")))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "MESA")
    void mesa_cannotManageGame_returnsForbidden() throws Exception {
        mockMvc.perform(post(GAMES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(gameBody(UUID.randomUUID().toString(),
                                UUID.randomUUID().toString(), UUID.randomUUID().toString(),
                                "2026-02-01T19:00:00")))
                .andExpect(status().isForbidden());
    }

    @Test
    void publicRead_remainsOpen() throws Exception {
        mockMvc.perform(get(ORGANIZATIONS_URL))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void registeredOrganizer_managesWithJwt() throws Exception {
        String email = "org-jwt@exemplo.com";

        MvcResult register = mockMvc.perform(post(AUTH_URL + "/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerBody("Cesar JWT", email, "segredo123")))
                .andExpect(status().isCreated())
                .andReturn();

        String userId = objectMapper.readTree(register.getResponse().getContentAsString())
                .path("id").asText();

        // ADMIN aprova a conta pendente antes do login.
        mockMvc.perform(post(AUTH_URL + "/users/" + userId + "/approve"))
                .andExpect(status().isOk());

        MvcResult login = mockMvc.perform(post(AUTH_URL + "/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody(email, "segredo123")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andReturn();

        String token = objectMapper
                .readTree(login.getResponse().getContentAsString())
                .path("token")
                .asText();

        mockMvc.perform(post(ORGANIZATIONS_URL)
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(organizationBody("ORG_JWT", "Associação via JWT")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty());
    }

    private String organizationBody(String tradeName, String legalName) throws Exception {
        Map<String, Object> fields = new HashMap<>();
        fields.put("legalName", legalName);
        fields.put("tradeName", tradeName);
        fields.put("abbreviation", "ORG");
        fields.put("organizationType", "ASSOCIATION");
        fields.put("document", cnpj("org-" + tradeName));
        fields.put("documentType", "CNPJ");
        fields.put("email", "contato@org.com.br");
        fields.put("phone", "11999999999");
        fields.put("website", "https://org.com.br");
        fields.put("instagram", "org.flag");
        fields.put("country", "BR");
        fields.put("state", "São Paulo");
        fields.put("city", "São Paulo");
        fields.put("logoUrl", "https://org.com.br/logo.png");
        fields.put("primaryColor", "#000000");
        fields.put("secondaryColor", "#FFFFFF");
        fields.put("timezone", "America/Sao_Paulo");
        fields.put("locale", "pt-BR");
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

    private String registerBody(String name, String email, String password) throws Exception {
        return objectMapper.writeValueAsString(Map.of(
                "name", name,
                "email", email,
                "password", password));
    }

    private String loginBody(String email, String password) throws Exception {
        return objectMapper.writeValueAsString(Map.of(
                "email", email,
                "password", password));
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
