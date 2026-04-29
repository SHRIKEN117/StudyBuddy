import express from "express";
import {
    getFlashcards,
    getAllFlashcardSets,
    reviewFlashcard,
    toggleStarFlashcard,
    deleteFlashcardSet,
} from "../controllers/flashcardController.js";
import protect from "../middleware/auth.js";

const router = express.Router();

router.get("/", protect, getAllFlashcardSets);           // fixed: was missing protect
router.get("/:documentId", protect, getFlashcards);
router.post("/:cardId/review", protect, reviewFlashcard);
router.put("/:cardId/star", protect, toggleStarFlashcard);
router.delete("/:id", protect, deleteFlashcardSet);

export default router;
