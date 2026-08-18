package br.com.flagplatform.modality;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@ActiveProfiles("test")
class ModalityControllerIntegrationTest {

    private static final String MODALITIES_URL = "/api/v1/modalities";

    @Autowired
    private WebApplicationContext context;

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
    void list_returnsSeededModalities() throws Exception {
        mockMvc.perform(get(MODALITIES_URL))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(4))
                .andExpect(jsonPath("$[0].format").value("11x11"))
                .andExpect(jsonPath("$[0].name").value("Full Pads"))
                .andExpect(jsonPath("$[0].contactType").value("FULL_PAD"))
                .andExpect(jsonPath("$[0].playersPerTeam").value(11))
                .andExpect(jsonPath("$[1].format").value("5x5"))
                .andExpect(jsonPath("$[1].contactType").value("FLAG"))
                .andExpect(jsonPath("$[2].format").value("8x8"))
                .andExpect(jsonPath("$[3].format").value("9x9"));
    }

    @Test
    void list_isPublic() throws Exception {
        mockMvc.perform(get(MODALITIES_URL))
                .andExpect(status().isOk());
    }

}
