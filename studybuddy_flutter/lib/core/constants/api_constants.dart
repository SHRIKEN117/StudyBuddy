class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://studybuddy-l06n.onrender.com/api',
  );

  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String profile = '/auth/profile';
  static const String changePassword = '/auth/change-password';

  static const String documents = '/documents';
  static const String uploadDocument = '/documents/upload';

  static const String flashcards = '/flashcards';
  static const String generateFlashcards = '/ai/generate-flashcards';
  static const String quizzes = '/quizzes';
  static const String generateQuiz = '/ai/generate-quiz';
  static const String generateSummary = '/ai/generate-summary';
  static const String chat = '/ai/chat';
  static const String explainConcept = '/ai/explain-concept';
  static const String extractConcepts = '/ai/extract-concepts';

  static const String dashboard = '/progress/dashboard';
}
