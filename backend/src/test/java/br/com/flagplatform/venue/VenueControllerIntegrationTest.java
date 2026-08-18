package br.com.flagplatform.venue;

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
class VenueControllerIntegrationTest {

    private static final String ORGANIZATIONS_URL = "/api/v1/organizations";
    private static final String VENUES_URL = "/api/v1/venues";

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
        String organizationId = createOrganization(
                "VEN_APFA", "Associação Paulista de Futebol Americano");

        String venueId = createVenue(
                organizationId, "Estádio do Morumbi",
                "Praça Roberto Gomes Pedrosa, 1", "https://maps.example.com/morumbi");

        mockMvc.perform(get(VENUES_URL + "/" + venueId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(venueId))
                .andExpect(jsonPath("$.organizationId").value(organizationId))
                .andExpect(jsonPath("$.name").value("Estádio do Morumbi"))
                .andExpect(jsonPath("$.address").value("Praça Roberto Gomes Pedrosa, 1"))
                .andExpect(jsonPath("$.mapsUrl").value("https://maps.example.com/morumbi"));

        mockMvc.perform(put(VENUES_URL + "/" + venueId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(venueBody(organizationId, "Estádio do Morumbi 2",
                                "Nova Rua, 2", null)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(venueId))
                .andExpect(jsonPath("$.name").value("Estádio do Morumbi 2"))
                .andExpect(jsonPath("$.address").value("Nova Rua, 2"));
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void create_withUnknownOrganization_returnsNotFound() throws Exception {
        mockMvc.perform(post(VENUES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(venueBody(UUID.randomUUID().toString(),
                                "Campo Fantasma", null, null)))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void create_duplicateName_returnsConflict() throws Exception {
        String organizationId = createOrganization("VEN_DUP", "Org Duplicada Venue");

        createVenue(organizationId, "Arena Corinthians", "Rua X, 1", null);

        mockMvc.perform(post(VENUES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(venueBody(organizationId, "Arena Corinthians",
                                "Rua X, 1", null)))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void listAll_returnsVenuesOrderedByName_publicAccess() throws Exception {
        String organizationId = createOrganization("VEN_ORD", "Org Ordenada Venue");

        createVenue(organizationId, "Zona Sul Arena", "Rua Z, 1", null);
        createVenue(organizationId, "Arena Norte", "Rua A, 1", null);

        MvcResult result = mockMvc.perform(get(VENUES_URL))
                .andExpect(status().isOk())
                .andReturn();

        JsonNode array = objectMapper.readTree(result.getResponse().getContentAsString());
        int arenaIndex = indexOfName(array, "Arena Norte");
        int zonaSulIndex = indexOfName(array, "Zona Sul Arena");

        assertThat(arenaIndex).isNotNegative();
        assertThat(zonaSulIndex).isNotNegative();
        assertThat(arenaIndex).isLessThan(zonaSulIndex);
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void getById_unknownId_returnsNotFound() throws Exception {
        mockMvc.perform(get(VENUES_URL + "/" + UUID.randomUUID()))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void update_duplicateName_returnsConflict() throws Exception {
        String organizationId = createOrganization("VEN_UPD", "Org Update Venue");

        String firstVenueId = createVenue(organizationId, "Campo A", null, null);
        createVenue(organizationId, "Campo B", null, null);

        mockMvc.perform(put(VENUES_URL + "/" + firstVenueId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(venueBody(organizationId, "Campo B", null, null)))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void create_withInvalidBody_returnsValidationErrors() throws Exception {
        Map<String, Object> invalid = new HashMap<>();
        invalid.put("name", "");

        mockMvc.perform(post(VENUES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalid)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields[?(@.field == 'name')]").exists())
                .andExpect(jsonPath("$.fields[?(@.field == 'organizationId')]").exists());
    }

    @Test
    void create_requiresAuthentication() throws Exception {
        mockMvc.perform(post(VENUES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(venueBody(UUID.randomUUID().toString(),
                                "Venue Sem Auth", null, null)))
                .andExpect(status().isForbidden());
    }

    @Test
    void update_requiresAuthentication() throws Exception {
        mockMvc.perform(put(VENUES_URL + "/" + UUID.randomUUID())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(venueBody(UUID.randomUUID().toString(),
                                "Venue Sem Auth", null, null)))
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

    private String organizationBody(String tradeName, String legalName) throws Exception {
        return objectMapper.writeValueAsString(organizationFields(tradeName, legalName));
    }

    private Map<String, Object> organizationFields(String tradeName, String legalName) {
        Map<String, Object> fields = new HashMap<>();
        fields.put("legalName", legalName);
        fields.put("tradeName", tradeName);
        fields.put("abbreviation", "VEN");
        fields.put("organizationType", "ASSOCIATION");
        fields.put("document", cnpj("org-" + tradeName));
        fields.put("documentType", "CNPJ");
        fields.put("email", "contato@ven.com.br");
        fields.put("phone", "11999999999");
        fields.put("website", "https://ven.com.br");
        fields.put("instagram", "ven.flag");
        fields.put("country", "BR");
        fields.put("state", "São Paulo");
        fields.put("city", "São Paulo");
        fields.put("logoUrl", "https://ven.com.br/logo.png");
        fields.put("primaryColor", "#000000");
        fields.put("secondaryColor", "#FFFFFF");
        fields.put("timezone", "America/Sao_Paulo");
        fields.put("locale", "pt-BR");
        return fields;
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
