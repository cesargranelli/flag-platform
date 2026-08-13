package br.com.flagplatform.security;

import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class JwtTokenProviderTest {

    private static final String SECRET =
            "test-secret-with-at-least-32-bytes-0000000";

    @Test
    void generateAndExtract_roundTripsEmail() {
        JwtTokenProvider provider = new JwtTokenProvider(SECRET, 3600);

        String token = provider.generateToken("ana@exemplo.com");

        assertThat(provider.extractEmail(token)).isEqualTo("ana@exemplo.com");
    }

    @Test
    void isValid_acceptsGeneratedToken() {
        JwtTokenProvider provider = new JwtTokenProvider(SECRET, 3600);

        String token = provider.generateToken("ana@exemplo.com");

        assertThat(provider.isValid(token)).isTrue();
    }

    @Test
    void isValid_rejectsGarbageToken() {
        JwtTokenProvider provider = new JwtTokenProvider(SECRET, 3600);

        assertThat(provider.isValid("nao-e-um-jwt")).isFalse();
    }

    @Test
    void isValid_rejectsTokenSignedWithAnotherSecret() {
        JwtTokenProvider provider = new JwtTokenProvider(SECRET, 3600);
        JwtTokenProvider other = new JwtTokenProvider(
                "another-secret-with-at-least-32-bytes-0000", 3600);

        String token = other.generateToken("ana@exemplo.com");

        assertThat(provider.isValid(token)).isFalse();
    }

    @Test
    void isValid_rejectsExpiredToken() {
        JwtTokenProvider provider = new JwtTokenProvider(SECRET, -1);

        String token = provider.generateToken("ana@exemplo.com");

        assertThat(provider.isValid(token)).isFalse();
    }

    @Test
    void getExpirationSeconds_returnsConfiguredValue() {
        JwtTokenProvider provider = new JwtTokenProvider(SECRET, 7200);

        assertThat(provider.getExpirationSeconds()).isEqualTo(7200L);
    }

}
