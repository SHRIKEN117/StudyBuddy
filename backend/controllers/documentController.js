import path from "path";
import Document from "../models/Document.js";
import Flashcard from "../models/Flashcard.js";
import Quiz from "../models/Quiz.js";
import { extractTextFromPDF } from "../utils/pdfParser.js";
import { chunkText } from "../utils/textChunker.js";
import mongoose from "mongoose";
import cloudinary from "../config/cloudinary.js";

const uploadToCloudinary = (buffer, publicId) =>
  new Promise((resolve, reject) => {
    cloudinary.uploader
      .upload_stream(
        {
          resource_type: "raw",
          public_id: publicId,
          folder: "studybuddy/documents",
        },
        (error, result) => {
          if (error) reject(error);
          else resolve(result);
        }
      )
      .end(buffer);
  });

// @desc Upload document
// @route POST /api/documents/upload
// @access Private
export const uploadDocument = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, error: "No file uploaded" });
    }

    const { title } = req.body;
    if (!title) {
      return res.status(400).json({ success: false, error: "Title is required" });
    }

    const publicId = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    const cloudResult = await uploadToCloudinary(req.file.buffer, publicId);

    const document = await Document.create({
      userId: req.user._id,
      title,
      fileName: req.file.originalname,
      fileUrl: cloudResult.secure_url,
      cloudinaryPublicId: cloudResult.public_id,
      fileSize: req.file.size,
      status: "Processing",
    });

    processPDF(document._id, req.file.buffer).catch((err) => {
      console.error("PDF processing error:", err);
    });

    res.status(201).json({
      success: true,
      data: document,
      message: "Document uploaded successfully",
    });
  } catch (error) {
    next(error);
  }
};

const processPDF = async (documentId, buffer) => {
  try {
    const { text } = await extractTextFromPDF(buffer);
    const chunks = chunkText(text, 500, 50);
    const wordCount = text.split(/\s+/).filter((w) => w.length > 0).length;

    await Document.findByIdAndUpdate(documentId, {
      extractedText: text,
      chunks,
      wordCount,
      status: "Ready",
    });

    console.log(`Document ${documentId} processed successfully`);
  } catch (error) {
    console.error(`Error processing document ${documentId}:`, error);
    await Document.findByIdAndUpdate(documentId, { status: "Failed" });
  }
};

// @desc Get all user documents
// @route GET /api/documents
// @access Private
export const getDocuments = async (req, res, next) => {
  try {
    const documents = await Document.aggregate([
      { $match: { userId: new mongoose.Types.ObjectId(req.user.id) } },
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
      { $sort: { uploadDate: -1 } },
    ]);

    // Back-compat: if fileUrl is missing, construct it from filePath (local dev only)
    const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 8000}`;
    const docsWithUrl = documents.map((doc) => ({
      ...doc,
      fileUrl:
        doc.fileUrl ||
        (doc.filePath
          ? `${baseUrl}/uploads/documents/${path.basename(doc.filePath)}`
          : null),
    }));

    res.status(200).json({ success: true, count: docsWithUrl.length, data: docsWithUrl });
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
      return res.status(404).json({ success: false, error: "Document not found" });
    }

    const flashcardCount = await Flashcard.countDocuments({ documentId: document._id });
    const quizCount = await Quiz.countDocuments({ documentId: document._id });

    await Document.findByIdAndUpdate(req.params.id, { lastAccessedAt: Date.now() });

    const documentData = document.toObject();
    documentData.flashcardCount = flashcardCount;
    documentData.quizCount = quizCount;

    // Back-compat: construct fileUrl from filePath if not stored
    if (!documentData.fileUrl && documentData.filePath) {
      const baseUrl = process.env.BASE_URL || `http://localhost:${process.env.PORT || 8000}`;
      documentData.fileUrl = `${baseUrl}/uploads/documents/${path.basename(documentData.filePath)}`;
    }

    res.status(200).json({ success: true, data: documentData });
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
      return res.status(404).json({ success: false, error: "Document not found" });
    }

    if (document.cloudinaryPublicId) {
      await cloudinary
        .uploader
        .destroy(document.cloudinaryPublicId, { resource_type: "raw" })
        .catch(() => {});
    }

    await document.deleteOne();

    res.status(200).json({ success: true, message: "Document deleted successfully" });
  } catch (error) {
    next(error);
  }
};
