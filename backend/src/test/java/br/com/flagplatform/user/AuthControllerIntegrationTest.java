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

import java.util.Map;

import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@ActiveProfiles("test")
class AuthControllerIntegrationTest {

    private static final String BASE_URL = "/api/v1/auth";

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
    @WithMockUser(username = "ana@exemplo.com", roles = "ADMIN")
    void register_approve_loginAndMe_flow() throws Exception {
        // Cadastro cria um usuário ORGANIZER PENDENTE, sem expor a senha.
        MvcResult registerResult = mockMvc.perform(post(BASE_URL + "/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerBody("Ana Lima", "ana@exemplo.com", "segredo123")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.name").value("Ana Lima"))
                .andExpect(jsonPath("$.email").value("ana@exemplo.com"))
                .andExpect(jsonPath("$.role").value("ORGANIZER"))
                .andExpect(jsonPath("$.status").value("PENDING"))
                .andExpect(jsonPath("$.password").doesNotExist())
                .andExpect(jsonPath("$.passwordHash").doesNotExist())
                .andReturn();

        String userId = objectMapper.readTree(registerResult.getResponse().getContentAsString())
                .path("id").asText();

        // Pendente não autentica.
        mockMvc.perform(post(BASE_URL + "/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody("ana@exemplo.com", "segredo123")))
                .andExpect(status().isForbidden());

        // ADMIN aprova.
        mockMvc.perform(post(BASE_URL + "/users/" + userId + "/approve"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("ACTIVE"));

        // Login retorna o token JWT + usuário.
        MvcResult loginResult = mockMvc.perform(post(BASE_URL + "/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody("ana@exemplo.com", "segredo123")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.expiresInSeconds").isNumber())
                .andExpect(jsonPath("$.user.email").value("ana@exemplo.com"))
                .andExpect(jsonPath("$.user.role").value("ORGANIZER"))
                .andReturn();

        String token = objectMapper
                .readTree(loginResult.getResponse().getContentAsString())
                .path("token")
                .asText();

        // Token dá acesso ao /auth/me.
        mockMvc.perform(get(BASE_URL + "/me")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Ana Lima"))
                .andExpect(jsonPath("$.email").value("ana@exemplo.com"))
                .andExpect(jsonPath("$.role").value("ORGANIZER"));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void listPending_andReject_flow() throws Exception {
        mockMvc.perform(post(BASE_URL + "/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerBody("Carla", "carla@exemplo.com", "segredo123")))
                .andExpect(status().isCreated());

        MvcResult pending = mockMvc.perform(get(BASE_URL + "/users/pending"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[?(@.email == 'carla@exemplo.com')]").exists())
                .andReturn();

        JsonNode array = objectMapper.readTree(pending.getResponse().getContentAsString());
        JsonNode carla = null;
        for (JsonNode node : array) {
            if ("carla@exemplo.com".equals(node.path("email").asText())) {
                carla = node;
                break;
            }
        }
        String carlaId = carla.path("id").asText();

        mockMvc.perform(post(BASE_URL + "/users/" + carlaId + "/reject"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("REJECTED"));

        mockMvc.perform(post(BASE_URL + "/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody("carla@exemplo.com", "segredo123")))
                .andExpect(status().isForbidden());
    }

    @Test
    void register_duplicateEmail_returnsConflict() throws Exception {
        register("Carlos Souza", "carlos@exemplo.com", "segredo123");

        mockMvc.perform(post(BASE_URL + "/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerBody("Carlos Silva", "carlos@exemplo.com", "outra-senha")))
                .andExpect(status().isConflict());
    }

    @Test
    void register_invalidBody_returnsValidationErrors() throws Exception {
        mockMvc.perform(post(BASE_URL + "/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerBody("", "email-invalido", "123")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields[?(@.field == 'name')]").exists())
                .andExpect(jsonPath("$.fields[?(@.field == 'email')]").exists())
                .andExpect(jsonPath("$.fields[?(@.field == 'password')]").exists());
    }

    @Test
    void login_invalidCredentials_returnsUnauthorized() throws Exception {
        register("Bia Rocha", "bia@exemplo.com", "segredo123");

        mockMvc.perform(post(BASE_URL + "/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody("bia@exemplo.com", "senha-errada")))
                .andExpect(status().isUnauthorized());

        mockMvc.perform(post(BASE_URL + "/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(loginBody("nao-existe@exemplo.com", "segredo123")))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void me_withoutToken_returnsForbidden() throws Exception {
        mockMvc.perform(get(BASE_URL + "/me"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void createUser_withAdminRole_returnsCreated() throws Exception {
        mockMvc.perform(post(BASE_URL + "/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createUserBody("Mesa Central", "mesa@exemplo.com", "segredo123", "MESA")))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.email").value("mesa@exemplo.com"))
                .andExpect(jsonPath("$.role").value("MESA"));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void listUsers_withAdminRole_returnsList() throws Exception {
        mockMvc.perform(post(BASE_URL + "/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerBody("Beta Lima", "beta@exemplo.com", "segredo123")))
                .andExpect(status().isCreated());

        mockMvc.perform(get(BASE_URL + "/users"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$[?(@.email == 'beta@exemplo.com')]").exists());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void createUser_withoutAdminRole_returnsForbidden() throws Exception {
        mockMvc.perform(post(BASE_URL + "/users")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(createUserBody("Mesa", "mesa@exemplo.com", "segredo123", "MESA")))
                .andExpect(status().isForbidden());
    }

    private void register(String name, String email, String password) throws Exception {
        mockMvc.perform(post(BASE_URL + "/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(registerBody(name, email, password)))
                .andExpect(status().isCreated());
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

    private String createUserBody(String name, String email, String password, String role) throws Exception {
        return objectMapper.writeValueAsString(Map.of(
                "name", name,
                "email", email,
                "password", password,
                "role", role));
    }

}
