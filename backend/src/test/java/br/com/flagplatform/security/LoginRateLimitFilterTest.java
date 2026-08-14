package br.com.flagplatform.security;

import jakarta.servlet.FilterChain;
import org.junit.jupiter.api.Test;
import org.springframework.mock.web.MockHttpServletRequest;
import org.springframework.mock.web.MockHttpServletResponse;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;

class LoginRateLimitFilterTest {

    @Test
    void allowsAttemptsWithinLimit() throws Exception {
        LoginRateLimitFilter filter = new LoginRateLimitFilter(3, 60);
        FilterChain chain = mock(FilterChain.class);

        for (int i = 0; i < 3; i++) {
            MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/v1/auth/login");
            request.setRemoteAddr("10.0.0.1");
            MockHttpServletResponse response = new MockHttpServletResponse();

            filter.doFilterInternal(request, response, chain);

            assertThat(response.getStatus()).isEqualTo(200);
        }
    }

    @Test
    void returns429AfterLimit() throws Exception {
        LoginRateLimitFilter filter = new LoginRateLimitFilter(2, 60);
        FilterChain chain = mock(FilterChain.class);
        String ip = "10.0.0.2";

        for (int i = 0; i < 2; i++) {
            MockHttpServletRequest request = new MockHttpServletRequest("POST", "/api/v1/auth/login");
            request.setRemoteAddr(ip);
            filter.doFilterInternal(request, new MockHttpServletResponse(), chain);
        }

        MockHttpServletRequest blocked = new MockHttpServletRequest("POST", "/api/v1/auth/login");
        blocked.setRemoteAddr(ip);
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilterInternal(blocked, response, chain);

        assertThat(response.getStatus()).isEqualTo(429);
    }

    @Test
    void ignoresNonLoginRequests() throws Exception {
        LoginRateLimitFilter filter = new LoginRateLimitFilter(1, 60);
        FilterChain chain = mock(FilterChain.class);

        MockHttpServletRequest request = new MockHttpServletRequest("GET", "/api/v1/competitions");
        request.setRemoteAddr("10.0.0.3");
        MockHttpServletResponse response = new MockHttpServletResponse();

        filter.doFilterInternal(request, response, chain);

        assertThat(response.getStatus()).isEqualTo(200);
    }
}
