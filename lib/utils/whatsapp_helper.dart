import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../services/whatsapp_api_service.dart';

class WhatsAppHelper {
  static Future<void> sendBookingNotification({
    required String phone,
    required String customerName,
    required String serviceName,
    required DateTime dateTime,
    required double totalPrice,
    required String professionalName,
  }) async {
    final dateStr = DateFormat('dd/MM/yyyy').format(dateTime);
    final timeStr = DateFormat('HH:mm').format(dateTime);
    
    final message = "Olá $customerName! ✨\n\nSeu agendamento no GlamTime foi confirmado:\n"
        "🌸 Serviço: $serviceName\n"
        "👤 Profissional: $professionalName\n"
        "📅 Data: $dateStr\n"
        "🕒 Horário: $timeStr\n"
        "💰 Valor: R\$ ${totalPrice.toStringAsFixed(2)}\n\n"
        "Estamos te esperando! Caso precise desmarcar, por favor nos avise com antecedência.";
    
    // Tenta enviar via API Automatizada primeiro
    bool sentAutomated = await WhatsAppApiService.sendAutomatedMessage(
      phone: phone,
      message: message,
    );

    // Se a API não estiver configurada ou falhar, volta para o método manual (wa.me)
    if (!sentAutomated) {
      String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      if (!cleanPhone.startsWith('55') && cleanPhone.length <= 11) {
        cleanPhone = '55$cleanPhone';
      }

      final url = "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}";
      
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    }
  }

  static Future<void> sendBookingConfirmation({
    required String phone,
    required String clientName,
    required String serviceName,
    required DateTime dateTime,
  }) async {
    final dateStr = DateFormat('dd/MM/yyyy').format(dateTime);
    final timeStr = DateFormat('HH:mm').format(dateTime);
    
    final message = "Olá $clientName! Seu agendamento de $serviceName para o dia $dateStr às $timeStr foi realizado com sucesso no GlamTime. Confirmamos sua presença?";
    
    // Formata o telefone: remove caracteres não numéricos e garante o código do país (55 para Brasil)
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (!cleanPhone.startsWith('55') && cleanPhone.length <= 11) {
      cleanPhone = '55$cleanPhone';
    }

    final url = "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}";
    
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      print('Não foi possível abrir o WhatsApp');
    }
  }

  static Future<void> sendCancellationNotice({
    required String phone,
    required String clientName,
    required String serviceName,
    required DateTime dateTime,
  }) async {
    final dateStr = DateFormat('dd/MM/yyyy').format(dateTime);
    final message = "Olá $clientName, infelizmente seu agendamento de $serviceName no dia $dateStr precisou ser cancelado. Por favor, entre em contato para reagendar.";
    
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (!cleanPhone.startsWith('55')) cleanPhone = '55$cleanPhone';

    final url = "https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
