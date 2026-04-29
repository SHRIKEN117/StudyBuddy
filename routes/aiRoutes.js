import express from "express";
import {
  generateFlashcards,
  generateQuiz,
  generateSummary,
  getSummary,
  chat,
  explainConcept,
  getChatHistory,
  extractConcepts,
} from "../controllers/aiController.js";
import protect from "../middleware/auth.js";

const router = express.Router();

router.post("/generate-flashcards", protect, generateFlashcards);
router.post("/generate-quiz", protect, generateQuiz);
router.post("/generate-summary", protect, generateSummary);
router.get("/summary/:documentId", protect, getSummary);
router.post("/chat", protect, chat);
router.post("/explain-concept", protect, explainConcept);
router.get("/chat-history/:documentId", protect, getChatHistory);
router.post("/extract-concepts", protect, extractConcepts);

export default router;
