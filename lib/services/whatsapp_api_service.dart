import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class WhatsAppApiService {
  // Configurações para um Gateway de WhatsApp (Ex: Z-API, Evolution API, etc.)
  // O usuário precisará preencher essas informações com os dados do serviço que contratar.
  static const String _baseUrl = "SUA_URL_DO_GATEWAY_AQUI";
  static const String _instanceId = "SUA_INSTANCIA_AQUI";
  static const String _token = "SEU_TOKEN_AQUI";

  static Future<bool> sendAutomatedMessage({
    required String phone,
    required String message,
  }) async {
    // Se não houver configuração, avisamos no log e retornamos false
    if (_baseUrl == "SUA_URL_DO_GATEWAY_AQUI") {
      debugPrint("⚠️ WhatsApp API não configurada. Para automatizar, contrate um serviço de Gateway.");
      return false;
    }

    try {
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final formattedPhone = cleanPhone.startsWith('55') ? cleanPhone : '55$cleanPhone';

      final response = await http.post(
        Uri.parse("$_baseUrl/send-text/$_instanceId"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $_token",
        },
        body: jsonEncode({
          "phone": formattedPhone,
          "message": message,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Mensagem automatizada enviada com sucesso!");
        return true;
      } else {
        debugPrint("❌ Erro ao enviar mensagem automatizada: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Falha na conexão com API de WhatsApp: $e");
      return false;
    }
  }
}
