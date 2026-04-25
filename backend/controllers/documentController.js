import path from "path";
import { fileURLToPath } from "url";
import Document from "../models/Document.js";
import Flashcard from "../models/Flashcard.js";
import Quiz from "../models/Quiz.js";
import { extractTextFromPDF } from "../utils/pdfParser.js";
import { chunkText } from "../utils/textChunker.js";
import fs from "fs/promises";
import mongoose from "mongoose";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// @desc Upload document
// @route POST /api/documents/upload
// @access Private
export const uploadDocument = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        error: "No file uploaded",
        statusCode: 400,
      });
    }

    const { title } = req.body;
    if (!title) {
      await fs.unlink(req.file.path);
      return res.status(400).json({
        success: false,
        error: "Title is required",
        statusCode: 400,
      });
    }

    // Store the actual filesystem path; derive URL for client responses
    const document = await Document.create({
      userId: req.user._id,
      title,
      fileName: req.file.originalname,
      filePath: req.file.path,  // actual filesystem path for server operations
      fileSize: req.file.size,
      status: "Processing",
    });

    processPDF(document._id, req.file.path).catch((err) => {
      console.error("PDF processing error:", err);
    });

    const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 8000}`;
    const fileUrl = `${baseUrl}/uploads/documents/${req.file.filename}`;

    res.status(201).json({
      success: true,
      data: { ...document.toObject(), fileUrl },
      message: "Document uploaded successfully",
    });
  } catch (error) {
    if (req.file) {
      await fs.unlink(req.file.path).catch(() => {});
    }
    next(error);
  }
};

const processPDF = async (documentId, filePath) => {
  try {
    const { text } = await extractTextFromPDF(filePath);
    const chunks = chunkText(text, 500, 50);
    const wordCount = text.split(/\s+/).filter(w => w.length > 0).length;

    await Document.findByIdAndUpdate(documentId, {
      extractedText: text,
      chunks,
      wordCount,
      status: "Ready",
    });

    console.log(`Document ${documentId} processed successfully`);  // fixed: was double-quoted string
  } catch (error) {
    console.error(`Error processing document ${documentId}:`, error);  // fixed: was double-quoted string

    await Document.findByIdAndUpdate(documentId, {
      status: "Failed",
    });
  }
};

// @desc Get all user documents
// @route GET /api/documents
// @access Private
export const getDocuments = async (req, res, next) => {
  try {
    const documents = await Document.aggregate([
      {
        $match: { userId: new mongoose.Types.ObjectId(req.user.id) },
      },
      {
        $lookup: {
          from: "flashcards",
          localField: "_id",
          foreignField: "documentId",
          as: "flashcardSets",
        },
      },
      {
        $lookup: {
          from: "quizzes",
          localField: "_id",
          foreignField: "documentId",
          as: "quizzes",
        },
      },
      {
        $addFields: {
          flashcardCount: { $size: "$flashcardSets" },
          quizCount: { $size: "$quizzes" },
        },
      },
      {
        $project: {
          extractedText: 0,
          chunks: 0,
          summary: 0,
          flashcardSets: 0,
          quizzes: 0,
        },
      },
      {
        $sort: { uploadDate: -1 },
      },
    ]);

    const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 8000}`;
    const docsWithUrl = documents.map((doc) => ({
      ...doc,
      fileUrl: doc.filePath
        ? `${baseUrl}/uploads/documents/${path.basename(doc.filePath)}`
        : null,
    }));

    res.status(200).json({
      success: true,
      count: docsWithUrl.length,
      data: docsWithUrl,
    });
  } catch (error) {
    next(error);
  }
};

// @desc Get single document
// @route GET /api/documents/:id
// @access Private
export const getDocument = async (req, res, next) => {
  try {
    const document = await Document.findById(req.params.id);
    if (!document) {
      return res.status(404).json({
        success: false,
        error: "Document not found",
        statusCode: 404,
      });
    }

    const flashcardCount = await Flashcard.countDocuments({ documentId: document._id });
    const quizCount = await Quiz.countDocuments({ documentId: document._id });

    await Document.findByIdAndUpdate(req.params.id, { lastAccessedAt: Date.now() });

    const documentData = document.toObject();
    documentData.flashcardCount = flashcardCount;
    documentData.quizCount = quizCount;

    const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 8000}`;
    documentData.fileUrl = documentData.filePath
      ? `${baseUrl}/uploads/documents/${path.basename(documentData.filePath)}`
      : null;

    res.status(200).json({
      success: true,
      data: documentData,
    });
  } catch (error) {
    next(error);
  }
};

// @desc Delete document
// @route DELETE /api/documents/:id
// @access Private
export const deleteDocument = async (req, res, next) => {
  try {
    const document = await Document.findById(req.params.id);
    if (!document) {
      return res.status(404).json({
        success: false,
        error: "Document not found",
        statusCode: 404,
      });
    }

    // filePath is the actual filesystem path, so unlink works directly
    if (document.filePath) {
      await fs.unlink(document.filePath).catch(() => {});
    }

    await document.deleteOne();

    res.status(200).json({
      success: true,
      message: "Document deleted successfully",
    });
  } catch (error) {
    next(error);
  }
};
