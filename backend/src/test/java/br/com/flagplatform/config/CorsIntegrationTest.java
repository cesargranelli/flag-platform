package br.com.flagplatform.config;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.HttpHeaders;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

import static org.hamcrest.Matchers.containsString;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@ActiveProfiles("test")
@TestPropertySource(properties = "app.cors.allowed-origins=https://app.flagplatform.com.br")
class CorsIntegrationTest {

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
    void getFromLocalhostOrigin_echoesAllowOriginHeader() throws Exception {
        mockMvc.perform(get("/api/v1/competitions")
                        .header(HttpHeaders.ORIGIN, "http://localhost:52758"))
                .andExpect(status().isOk())
                .andExpect(header().string(
                        HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, "http://localhost:52758"));
    }

    @Test
    void getFrom127Origin_echoesAllowOriginHeader() throws Exception {
        mockMvc.perform(get("/api/v1/competitions")
                        .header(HttpHeaders.ORIGIN, "http://127.0.0.1:8080"))
                .andExpect(status().isOk())
                .andExpect(header().string(
                        HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, "http://127.0.0.1:8080"));
    }

    @Test
    void getFromConfiguredOrigin_echoesAllowOriginHeader() throws Exception {
        mockMvc.perform(get("/api/v1/competitions")
                        .header(HttpHeaders.ORIGIN, "https://app.flagplatform.com.br"))
                .andExpect(status().isOk())
                .andExpect(header().string(
                        HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, "https://app.flagplatform.com.br"));
    }

    @Test
    void preflightRequest_isAllowedForLocalhostOrigin() throws Exception {
        mockMvc.perform(options("/api/v1/competitions")
                        .header(HttpHeaders.ORIGIN, "http://localhost:52758")
                        .header(HttpHeaders.ACCESS_CONTROL_REQUEST_METHOD, "GET"))
                .andExpect(status().isOk())
                .andExpect(header().string(
                        HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN, "http://localhost:52758"))
                .andExpect(header().string(
                        HttpHeaders.ACCESS_CONTROL_ALLOW_METHODS, containsString("GET")));
    }

    @Test
    void requestFromUnknownOrigin_isRejectedWithoutCorsHeaders() throws Exception {
        mockMvc.perform(get("/api/v1/competitions")
                        .header(HttpHeaders.ORIGIN, "https://evil.example.com"))
                .andExpect(status().isForbidden())
                .andExpect(header().doesNotExist(HttpHeaders.ACCESS_CONTROL_ALLOW_ORIGIN));
    }
}
