/**
 * Gera um CPF válido (com dígitos verificadores corretos) para uso nos
 * testes E2E. O form de organização valida o CPF do presidente no client
 * (`DocumentUtils.isValidCpf`) e o backend aceita apenas dígitos.
 */
function digitoVerificador(digitos: number[], pesoInicial: number): number {
  const soma = digitos.reduce((acc, d, i) => acc + d * (pesoInicial - i), 0);
  const resto = soma % 11;
  return resto < 2 ? 0 : 11 - resto;
}

export function gerarCpfValido(): string {
  const base = Array.from({ length: 9 }, () => Math.floor(Math.random() * 10));
  const dv1 = digitoVerificador(base, 10);
  const dv2 = digitoVerificador([...base, dv1], 11);
  return [...base, dv1, dv2].join('');
}
