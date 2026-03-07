import 'package:flutter/material.dart';
import '../models/institution.dart';
import '../services/api_service.dart';
import '../services/session_manager.dart';

class InstitutionProvider with ChangeNotifier {
  Institution? _institution;
  bool _isLoading = false;

  Institution? get institution => _institution;
  bool get isLoading => _isLoading;

  Color get primaryColor {
    if (_institution?.primaryColor != null) {
      try {
        final hexColor = _institution!.primaryColor!.replaceAll('#', '');
        return Color(int.parse('FF$hexColor', radix: 16));
      } catch (e) {
        return const Color(0xFF4F46E5);
      }
    }
    return const Color(0xFF4F46E5);
  }

  Future<void> fetchInstitutionProfile([String? forceId]) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = forceId ?? await SessionManager.getInstitutionId();
      debugPrint('Fetching institution profile for ID: $id');
      if (id != null) {
        _institution = await ApiService.getInstitutionProfile(id);
        debugPrint('Institution profile fetched: ${_institution?.name}');
      }
    } catch (e) {
      debugPrint('Error fetching institution profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateInstitutionProfile(Institution updatedInstitution) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('Calling ApiService.updateInstitutionProfile for ID: ${updatedInstitution.id}');
      await ApiService.updateInstitutionProfile(updatedInstitution);
      
      // Re-fetch to ensure we have exactly what's in the DB
      await fetchInstitutionProfile(updatedInstitution.id);
      
      debugPrint('Local provider state refreshed from DB');
    } catch (e) {
      debugPrint('Error updating institution profile: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setPrimaryColor(Color color) {
    if (_institution != null) {
      final hexColor = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
      _institution = Institution(
        id: _institution!.id,
        name: _institution!.name,
        address: _institution!.address,
        email: _institution!.email,
        phone: _institution!.phone,
        primaryColor: hexColor,
        logoUrl: _institution!.logoUrl,
      );
      notifyListeners();
    }
  }
}
