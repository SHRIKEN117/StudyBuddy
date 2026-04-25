import Document from "../models/Document.js";
import Flashcard from "../models/Flashcard.js";
import Quiz from "../models/Quiz.js";

// @desc Get user learning statistics
// @route GET /api/progress/dashboard
// @access Private
export const getDashboard = async (req, res, next) => {
    try {
        const userId = req.user._id;

        // All counts scoped to the current user
        const totalDocuments = await Document.countDocuments({ userId });
        const totalFlashcardSets = await Flashcard.countDocuments({ userId });
        const totalQuizzes = await Quiz.countDocuments({ userId });
        const completedQuizzes = await Quiz.countDocuments({ userId, completedAt: { $ne: null } });

        // Flashcard statistics for this user only
        const flashcardSets = await Flashcard.find({ userId });
        let totalFlashcards = 0;
        let reviewedFlashcards = 0;
        let starredFlashcards = 0;

        flashcardSets.forEach((set) => {
            totalFlashcards += set.cards.length;
            reviewedFlashcards += set.cards.filter((c) => c.reviewCount > 0).length;
            starredFlashcards += set.cards.filter((c) => c.isStarred).length;
        });

        // Quiz statistics for this user only
        const quizzes = await Quiz.find({ userId, completedAt: { $ne: null } });
        const averageScore =
            quizzes.length > 0
                ? Math.round(quizzes.reduce((sum, q) => sum + q.score, 0) / quizzes.length)
                : 0;

        // Recent activity scoped to this user
        const recentDocuments = await Document.find({ userId })
            .sort({ lastAccessedAt: -1 })
            .limit(5)
            .select("title fileName lastAccessedAt status");

        const recentQuizzes = await Quiz.find({ userId })
            .sort({ createdAt: -1 })
            .limit(5)
            .populate("documentId", "title")
            .select("title score totalQuestions completedAt");

        res.status(200).json({
            success: true,
            data: {
                overview: {
                    totalDocuments,
                    totalFlashcardSets,
                    totalQuizzes,
                    completedQuizzes,
                    totalFlashcards,
                    reviewedFlashcards,
                    starredFlashcards,
                    averageScore,
                },
                recentActivity: {
                    documents: recentDocuments,
                    quizzes: recentQuizzes,
                },
            },
            message: "User learning statistics retrieved successfully",
            statusCode: 200,
        });
    } catch (error) {
        next(error);
    }
};
