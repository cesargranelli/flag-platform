package br.com.flagplatform.user;

/**
 * Porta para emissão de tokens de autenticação. Mantida no domínio para que o
 * módulo user não dependa de detalhes de infraestrutura de segurança.
 */
public interface TokenProvider {

    String generateToken(String subject);

    long getExpirationSeconds();

}
