package br.com.flagplatform.category;

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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@ActiveProfiles("test")
class CategoryControllerIntegrationTest {

    private static final String ORGANIZATIONS_URL = "/api/v1/organizations";
    private static final String COMPETITIONS_URL = "/api/v1/competitions";
    private static final String CATEGORIES_URL = "/api/v1/categories";
    private static final String MODALITIES_URL = "/api/v1/modalities";

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
    void create_derivesName_whenNotInformed() throws Exception {
        String organizationId = createOrganization("CATORG_FLOW", "Org Fluxo Categoria");
        String competitionId = createCompetition(organizationId, "COMP_CAT_TAÇA SP");
        String modalityId = firstModalityId();

        Map<String, Object> fields = categoryFields(competitionId, modalityId, "MALE", "ADULT");
        fields.put("name", null);

        mockMvc.perform(post(CATEGORIES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(fields)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.competitionId").value(competitionId))
                .andExpect(jsonPath("$.modalityId").value(modalityId))
                .andExpect(jsonPath("$.modalityName").isNotEmpty())
                .andExpect(jsonPath("$.modalityFormat").isNotEmpty())
                .andExpect(jsonPath("$.gender").value("MALE"))
                .andExpect(jsonPath("$.ageGroup").value("ADULT"))
                .andExpect(jsonPath("$.name").isNotEmpty());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void create_listByCompetition_update_andDelete_flow() throws Exception {
        String organizationId = createOrganization("CATORG_FLOW2", "Org Fluxo Categoria 2");
        String competitionId = createCompetition(organizationId, "COMP_CAT_TAÇA SP");
        String modalityId = firstModalityId();

        String firstCategoryId = createCategory(competitionId, modalityId, "MALE", "ADULT", "CAT_A Masculino");
        String secondCategoryId = createCategory(competitionId, modalityId, "FEMALE", "ADULT", "CAT_B Feminino");

        mockMvc.perform(get(COMPETITIONS_URL + "/" + competitionId + "/categories"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(firstCategoryId))
                .andExpect(jsonPath("$[0].competitionId").value(competitionId))
                .andExpect(jsonPath("$[0].name").value("CAT_A Masculino"))
                .andExpect(jsonPath("$[1].id").value(secondCategoryId))
                .andExpect(jsonPath("$[1].name").value("CAT_B Feminino"));

        mockMvc.perform(put(CATEGORIES_URL + "/" + secondCategoryId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(categoryBody(competitionId, modalityId, "FEMALE", "SUB11", "CAT_B Feminino 7x7")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(secondCategoryId))
                .andExpect(jsonPath("$.competitionId").value(competitionId))
                .andExpect(jsonPath("$.ageGroup").value("SUB11"))
                .andExpect(jsonPath("$.name").value("CAT_B Feminino 7x7"));

        mockMvc.perform(delete(CATEGORIES_URL + "/" + firstCategoryId))
                .andExpect(status().isNoContent());

        mockMvc.perform(get(COMPETITIONS_URL + "/" + competitionId + "/categories"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].id").value(secondCategoryId))
                .andExpect(jsonPath("$[0].name").value("CAT_B Feminino 7x7"));
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void create_duplicateCombination_returnsConflict() throws Exception {
        String organizationId = createOrganization("CATORG_DUP", "Org Duplicada Categoria");
        String competitionId = createCompetition(organizationId, "COMP_CAT_DUPLICADO");
        String modalityId = firstModalityId();

        createCategory(competitionId, modalityId, "MALE", "ADULT", "CAT_Masculino 5x5");

        mockMvc.perform(post(CATEGORIES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(categoryBody(competitionId, modalityId, "MALE", "ADULT", "CAT_Outro Rótulo")))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void create_sameCombinationDifferentGender_isAllowed() throws Exception {
        String organizationId = createOrganization("CATORG_GEN", "Org Generos");
        String competitionId = createCompetition(organizationId, "COMP_CAT_GENEROS");
        String modalityId = firstModalityId();

        createCategory(competitionId, modalityId, "MALE", "ADULT", null);
        createCategory(competitionId, modalityId, "FEMALE", "ADULT", null);
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void create_withUnknownModality_returnsNotFound() throws Exception {
        String organizationId = createOrganization("CATORG_MODNF", "Org Modalidade NF");
        String competitionId = createCompetition(organizationId, "COMP_CAT_MODNF");

        mockMvc.perform(post(CATEGORIES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(categoryBody(competitionId, UUID.randomUUID().toString(), "MALE", "ADULT", null)))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void create_withInvalidBody_returnsValidationErrors() throws Exception {
        Map<String, Object> invalid = new HashMap<>();
        invalid.put("name", "");

        mockMvc.perform(post(CATEGORIES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(invalid)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fields[?(@.field == 'modalityId')]").exists())
                .andExpect(jsonPath("$.fields[?(@.field == 'gender')]").exists())
                .andExpect(jsonPath("$.fields[?(@.field == 'ageGroup')]").exists())
                .andExpect(jsonPath("$.fields[?(@.field == 'competitionId')]").exists());
    }

    @Test
    void create_requiresAuthentication() throws Exception {
        mockMvc.perform(post(CATEGORIES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(categoryBody(UUID.randomUUID().toString(), UUID.randomUUID().toString(), "MALE", "ADULT", "CAT_Sem Auth")))
                .andExpect(status().isForbidden());
    }

    @Test
    void update_requiresAuthentication() throws Exception {
        mockMvc.perform(put(CATEGORIES_URL + "/" + UUID.randomUUID())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(categoryBody(UUID.randomUUID().toString(), UUID.randomUUID().toString(), "MALE", "ADULT", "CAT_Sem Auth")))
                .andExpect(status().isForbidden());
    }

    @Test
    void delete_requiresAuthentication() throws Exception {
        mockMvc.perform(delete(CATEGORIES_URL + "/" + UUID.randomUUID()))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void getById_returnsCategoryDetail() throws Exception {
        String organizationId = createOrganization("CATORG_DET", "Org Detalhe Categoria");
        String competitionId = createCompetition(organizationId, "COMP_CAT_DETALHE");
        String modalityId = firstModalityId();
        String categoryId = createCategory(competitionId, modalityId, "MALE", "SUB14", "CAT_Detalhe");

        mockMvc.perform(get(CATEGORIES_URL + "/" + categoryId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(categoryId))
                .andExpect(jsonPath("$.competitionId").value(competitionId))
                .andExpect(jsonPath("$.modalityId").value(modalityId))
                .andExpect(jsonPath("$.gender").value("MALE"))
                .andExpect(jsonPath("$.ageGroup").value("SUB14"))
                .andExpect(jsonPath("$.name").value("CAT_Detalhe"));
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void delete_softDeletes_andHidesFromList_andGetByIdReturnsNotFound() throws Exception {
        String organizationId = createOrganization("CATORG_SOFT", "Org Soft Delete");
        String competitionId = createCompetition(organizationId, "COMP_CAT_SOFT");
        String modalityId = firstModalityId();
        String categoryId = createCategory(competitionId, modalityId, "MALE", "ADULT", "CAT_Soft Delete");

        mockMvc.perform(delete(CATEGORIES_URL + "/" + categoryId))
                .andExpect(status().isNoContent());

        mockMvc.perform(get(COMPETITIONS_URL + "/" + competitionId + "/categories"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isEmpty());

        mockMvc.perform(get(CATEGORIES_URL + "/" + categoryId))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "ORGANIZER")
    void delete_softDeletedCombination_canBeReused() throws Exception {
        String organizationId = createOrganization("CATORG_REUSE", "Org Reuso Combinação");
        String competitionId = createCompetition(organizationId, "COMP_CAT_REUSO");
        String modalityId = firstModalityId();
        String categoryId = createCategory(competitionId, modalityId, "MALE", "ADULT", "CAT_Reuso");

        mockMvc.perform(delete(CATEGORIES_URL + "/" + categoryId))
                .andExpect(status().isNoContent());

        String newCategoryId = createCategory(competitionId, modalityId, "MALE", "ADULT", "CAT_Reuso");

        mockMvc.perform(get(CATEGORIES_URL + "/" + newCategoryId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("CAT_Reuso"));
    }

    @Test
    void getByCompetition_unknownCompetition_returnsEmptyList() throws Exception {
        mockMvc.perform(get(COMPETITIONS_URL + "/" + UUID.randomUUID() + "/categories"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$").isArray())
                .andExpect(jsonPath("$").isEmpty());
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

    private String firstModalityId() throws Exception {
        MvcResult result = mockMvc.perform(get(MODALITIES_URL))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").isNotEmpty())
                .andReturn();

        JsonNode body = objectMapper.readTree(result.getResponse().getContentAsString());
        return body.get(0).path("id").asText();
    }

    private String createCategory(String competitionId, String modalityId, String gender, String ageGroup, String name)
            throws Exception {
        MvcResult result = mockMvc.perform(post(CATEGORIES_URL)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(categoryBody(competitionId, modalityId, gender, ageGroup, name)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").isNotEmpty())
                .andExpect(jsonPath("$.competitionId").value(competitionId))
                .andExpect(jsonPath("$.modalityId").value(modalityId))
                .andExpect(jsonPath("$.gender").value(gender))
                .andExpect(jsonPath("$.ageGroup").value(ageGroup))
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
        fields.put("abbreviation", "CATORG");
        fields.put("organizationType", "ASSOCIATION");
        fields.put("document", cnpj("org-" + tradeName));
        fields.put("documentType", "CNPJ");
        fields.put("presidentName", "Maria Silva");
        fields.put("presidentCpf", cpf("pres-" + tradeName));
        fields.put("email", "contato@catorg.com.br");
        fields.put("phone", "11999999999");
        fields.put("website", "https://catorg.com.br");
        fields.put("instagram", "catorg.flag");
        fields.put("country", "BR");
        fields.put("state", "São Paulo");
        fields.put("city", "São Paulo");
        fields.put("logoUrl", "https://catorg.com.br/logo.png");
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
        fields.put("description", "Campeonato para categorias");
        fields.put("startDate", "2026-01-15");
        fields.put("endDate", "2026-06-30");
        return objectMapper.writeValueAsString(fields);
    }

    private Map<String, Object> categoryFields(String competitionId, String modalityId, String gender, String ageGroup) {
        Map<String, Object> fields = new HashMap<>();
        fields.put("competitionId", competitionId);
        fields.put("modalityId", modalityId);
        fields.put("gender", gender);
        fields.put("ageGroup", ageGroup);
        return fields;
    }

    private String categoryBody(String competitionId, String modalityId, String gender, String ageGroup, String name)
            throws Exception {
        Map<String, Object> fields = categoryFields(competitionId, modalityId, gender, ageGroup);
        fields.put("name", name);
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

}
