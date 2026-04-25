import express from "express";
import { getDashboard } from "../controllers/progressController.js";
import protect from "../middleware/auth.js";

const router = express.Router();

router.get("/dashboard", protect, getDashboard);  // fixed: was missing protect

export default router;
