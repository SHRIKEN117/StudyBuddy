import express from "express";
import {
    getAllQuizzes,
    getQuizzes,
    getQuizById,
    submitQuiz,
    getQuizResults,
    retakeQuiz,
    deleteQuiz,
} from "../controllers/quizController.js";
import protect from "../middleware/auth.js";

const router = express.Router();

router.get("/", protect, getAllQuizzes);
router.get("/quiz/:id", protect, getQuizById);
router.get("/:documentId", protect, getQuizzes);
router.post("/:id/submit", protect, submitQuiz);
router.get("/:id/results", protect, getQuizResults);
router.post("/:id/retake", protect, retakeQuiz);
router.delete("/:id", protect, deleteQuiz);

export default router;
