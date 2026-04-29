import express from "express";
import { 
    uploadDocument,
    getDocuments,
    getDocument,
    deleteDocument,
} from "../controllers/documentController.js";
import upload from '../config/multer.js';
import protect from '../middleware/auth.js';

const router = express.Router();


// Document routes
router.post("/upload", protect, upload.single("file"), uploadDocument);
router.get("/", protect, getDocuments);
router.get("/:id", protect, getDocument);
router.delete("/:id", protect, deleteDocument);

export default router;