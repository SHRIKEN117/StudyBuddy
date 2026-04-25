class ApiConstants {
  // Use 10.0.2.2 for Android emulator, localhost for iOS simulator / real device on same network
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String profile = '/auth/profile';
  static const String changePassword = '/auth/change-password';

  static const String documents = '/documents';
  static const String uploadDocument = '/documents/upload';

  static const String flashcards = '/flashcards';
  static const String generateFlashcards = '/ai/generate-flashcards';
  static const String generateQuiz = '/ai/generate-quiz';
  static const String generateSummary = '/ai/generate-summary';
  static const String chat = '/ai/chat';
  static const String explainConcept = '/ai/explain-concept';

  static const String dashboard = '/progress/dashboard';
}
