package br.com.flagplatform.athlete;

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
class AthleteControllerIntegrationTest {

    private static final String ATHLETES_URL = "/api/v1/athletes";

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
    void create_getById_listAll_andUpdate_flow() throws Exception {
        String athleteId = createAthlete(
                "João Silva", "João", "QB", 7, "https://foto.com/joao.png");

        mockMvc.perform(get(ATHLETES_URL + "/" + athleteId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(athleteId))
                .andExpect(jsonPath("$.name").value("João Silva"))
                .andExpect(jsonPath("$.nickname").value("João"))
                .andExpect(jsonPath("$.position").value("QB"))
                .andExpect(jsonPath("$.number").value(7))
                .andExpect(jsonPath("$.photoUrl").value("https://foto.com/joao.png"));

        mockMvc.perform(put(ATHLETES_URL + "/" + athleteId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(athleteBody("João Silva", "Joãozinho", "WR", 10, null)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(athleteId))
                .andExpect(jsonPath("$.name").value("João Silva"))
                .andExpect(jsonPath("$.nickname").value("Joãozinho"))
                .andExpect(jsonPath("$.position").value("WR"))
                .andExpect(jsonPath("$.number").value(10));
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void listAll_returnsAthletesOrderedByName_publicAccess() throws Exception {
        createAthlete("Bia Santos", "Bia", "DB", 21, null);
        createAthlete("Ana Souza", "Ana", "RB", 3, null);

        MvcResult result = mockMvc.perform(get(ATHLETES_URL))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode array = objectMapper.readTree(result.getResponse().getContentAsString());
        int anaIndex = indexOfName(array, "Ana Souza");
        int biaIndex = indexOfName(array, "Bia Santos");

        assertThat(anaIndex).isNotNegative();
        assertThat(biaIndex).isNotNegative();
        assertThat(anaIndex).isLessThan(biaIndex);
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void getById_unknownId_returnsNotFound() throws Exception {
        mockMvc.perform(get(ATHLETES_URL + "/" + UUID.randomUUID()))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void update_unknownId_returnsNotFound() throws Exception {
        mockMvc.perform(put(ATHLETES_URL + "/" + UUID.randomUUID())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(athleteBody("João Silva", null, null, null, null)))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void create_withInvalidBody_returnsValidationErrors() throws Exception {
        Map<String, Object> invalid = new HashMap<>();
        invalid.put("name", "");
        invalid.put("number", -1);

        mockMvc.perform(post(ATHLETES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalid)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields[?(@.field == 'name')]").exists())
                .andExpect(jsonPath("$.fields[?(@.field == 'number')]").exists());
    }

    @Test
    void create_requiresAuthentication() throws Exception {
        mockMvc.perform(post(ATHLETES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(athleteBody("Atleta Sem Auth", null, null, null, null)))
                .andExpect(status().isForbidden());
    }

    @Test
    void update_requiresAuthentication() throws Exception {
        mockMvc.perform(put(ATHLETES_URL + "/" + UUID.randomUUID())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(athleteBody("Atleta Sem Auth", null, null, null, null)))
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

    private String createAthlete(String name, String nickname, String position,
                                 Integer number, String photoUrl) throws Exception {
        MvcResult result = mockMvc.perform(post(ATHLETES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(athleteBody(name, nickname, position, number, photoUrl)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.name").value(name))
                .andReturn();

        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        return body.path("id").asText();
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

}
