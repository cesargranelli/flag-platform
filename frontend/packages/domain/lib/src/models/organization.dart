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
  final String timezone;
  final String locale;
  final OrganizationStatus? status;
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
    this.email,
    this.phone,
    this.website,
    this.instagram,
    this.state,
    this.city,
    this.logoUrl,
    this.primaryColor,
    this.secondaryColor,
    this.status,
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
        timezone: json['timezone'] as String,
        locale: json['locale'] as String,
        status: json['status'] is String
            ? OrganizationStatus.fromJson(json['status'] as String)
            : null,
        createdAt: _tryParseDate(json['createdAt']),
        updatedAt: _tryParseDate(json['updatedAt']),
      );

  /// Corpo de criação/atualização (`POST/PUT /api/v1/organizations`).
  Map<String, dynamic> toJson() => {
        'legalName': legalName,
        'tradeName': tradeName,
        if (abbreviation != null) 'abbreviation': abbreviation,
        if (organizationType != null) 'organizationType': organizationType!.toJson(),
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
        'timezone': timezone,
        'locale': locale,
      };
}

DateTime? _tryParseDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
