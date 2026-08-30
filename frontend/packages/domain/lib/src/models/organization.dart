import '../enums/document_type.dart';
import '../enums/organization_status.dart';
import '../enums/organization_type.dart';

/// Organização esportiva do Flag Platform.
///
/// Shape de `GET /api/v1/organizations` (lista, detalhe e atualização).
class Organization {
  final String id;
  final String legalName;
  final String tradeName;
  final String? abbreviation;
  final OrganizationType? organizationType;
  final String? document;
  final DocumentType? documentType;
  final String? presidentName;
  final String? presidentCpf;
  final String? email;
  final String? phone;
  final String? website;
  final String? instagram;
  final String country;
  final String? state;
  final String? city;
  final String? logoUrl;
  final String? primaryColor;
  final String? secondaryColor;
  final String? tertiaryColor;
  final String? quaternaryColor;
  final String timezone;
  final String locale;
  final OrganizationStatus? status;

  /// UUID do usuário que criou a organização (exposto pelo backend, #359).
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Organization({
    required this.id,
    required this.legalName,
    required this.tradeName,
    required this.country,
    required this.timezone,
    required this.locale,
    this.abbreviation,
    this.organizationType,
    this.document,
    this.documentType,
    this.presidentName,
    this.presidentCpf,
    this.email,
    this.phone,
    this.website,
    this.instagram,
    this.state,
    this.city,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.tertiaryColor,
    this.quaternaryColor,
    this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Organization.fromJson(Map<String, dynamic> json) => Organization(
        id: json['id'] as String,
        legalName: json['legalName'] as String,
        tradeName: json['tradeName'] as String,
        abbreviation: json['abbreviation'] as String?,
        organizationType: json['organizationType'] is String
            ? OrganizationType.fromJson(json['organizationType'] as String)
            : null,
        document: json['document'] as String?,
        documentType: json['documentType'] is String
            ? DocumentType.fromJson(json['documentType'] as String)
            : null,
        presidentName: json['presidentName'] as String?,
        presidentCpf: json['presidentCpf'] as String?,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        website: json['website'] as String?,
        instagram: json['instagram'] as String?,
        country: json['country'] as String,
        state: json['state'] as String?,
        city: json['city'] as String?,
        logoUrl: json['logoUrl'] as String?,
        primaryColor: json['primaryColor'] as String?,
        secondaryColor: json['secondaryColor'] as String?,
        tertiaryColor: json['tertiaryColor'] as String?,
        quaternaryColor: json['quaternaryColor'] as String?,
        timezone: json['timezone'] as String,
        locale: json['locale'] as String,
        status: json['status'] is String
            ? OrganizationStatus.fromJson(json['status'] as String)
            : null,
        createdBy: json['createdBy'] as String?,
        createdAt: _tryParseDate(json['createdAt']),
        updatedAt: _tryParseDate(json['updatedAt']),
      );

  /// Corpo de criação/atualização (`POST/PUT /api/v1/organizations`).
  Map<String, dynamic> toJson() => {
        'legalName': legalName,
        'tradeName': tradeName,
        if (abbreviation != null) 'abbreviation': abbreviation,
        if (organizationType != null) 'organizationType': organizationType!.toJson(),
        if (document != null) 'document': document,
        if (documentType != null) 'documentType': documentType!.toJson(),
        if (presidentName != null) 'presidentName': presidentName,
        if (presidentCpf != null) 'presidentCpf': presidentCpf,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (website != null) 'website': website,
        if (instagram != null) 'instagram': instagram,
        'country': country,
        if (state != null) 'state': state,
        if (city != null) 'city': city,
        if (logoUrl != null) 'logoUrl': logoUrl,
        if (primaryColor != null) 'primaryColor': primaryColor,
        if (secondaryColor != null) 'secondaryColor': secondaryColor,
        if (tertiaryColor != null) 'tertiaryColor': tertiaryColor,
        if (quaternaryColor != null) 'quaternaryColor': quaternaryColor,
        'timezone': timezone,
        'locale': locale,
        if (createdBy != null) 'createdBy': createdBy,
      };
}

DateTime? _tryParseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
