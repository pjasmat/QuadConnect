import 'package:flutter_test/flutter_test.dart';
import 'package:quadconnect/utils/error_messages.dart';

void main() {
  group('ErrorMessages Tests', () {
    test('should return user-friendly message for network errors', () {
      final error = Exception('Network error: Failed to connect');
      final message = ErrorMessages.getUserFriendlyError(error);
      
      expect(message, contains('internet connection'));
    });

    test('should return user-friendly message for authentication errors', () {
      final error = Exception('User not logged in');
      final message = ErrorMessages.getUserFriendlyError(error);
      
      expect(message, contains('log in'));
    });

    test('should return user-friendly message for capacity errors', () {
      final error = Exception('Event is at full capacity');
      final message = ErrorMessages.getUserFriendlyError(error);
      
      expect(message, contains('full capacity'));
    });

    test('should return user-friendly message for permission errors', () {
      final error = Exception('Permission denied');
      final message = ErrorMessages.getUserFriendlyError(error);
      
      expect(message, contains('permission'));
    });

    test('should return default message for unknown errors', () {
      final error = Exception('Unknown error xyz123');
      final message = ErrorMessages.getUserFriendlyError(error);
      
      expect(message, contains('Something went wrong'));
    });

    test('should return appropriate error title', () {
      expect(ErrorMessages.getErrorTitle(Exception('Network error')), 
          equals('Connection Error'));
      expect(ErrorMessages.getErrorTitle(Exception('Permission denied')), 
          equals('Permission Denied'));
      expect(ErrorMessages.getErrorTitle(Exception('Unknown')), 
          equals('Error'));
    });
  });
}

