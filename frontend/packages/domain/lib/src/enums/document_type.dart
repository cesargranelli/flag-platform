enum DocumentType {
  cnpj,
  cpf;

  static DocumentType? fromJson(String? value) => switch (value) {
        'CNPJ' => DocumentType.cnpj,
        'CPF' => DocumentType.cpf,
        _ => null,
      };

  String toJson() => switch (this) {
        DocumentType.cnpj => 'CNPJ',
        DocumentType.cpf => 'CPF',
      };

  String get label => switch (this) {
        DocumentType.cnpj => 'CNPJ',
        DocumentType.cpf => 'CPF',
      };
}
