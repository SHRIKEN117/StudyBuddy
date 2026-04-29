import Document from "../models/Document.js";
import Flashcard from "../models/Flashcard.js";
import Quiz from "../models/Quiz.js";
import ChatHistory from "../models/ChatHistory.js";
import * as geminiService from "../utils/claudeService.js";
import { findRelevantChunks } from "../utils/textChunker.js";

// @desc Generate flashcards from document
// @route POST /api/ai/generate-flashcards
// @access Private
export const generateFlashcards = async (req, res, next) => {
  try {
    const { documentId, count = 10 } = req.body;
    if (!documentId) {
      return res.status(400).json({
        success: false,
        error: "Document ID is required",
        statusCode: 400,
      });
    }

    const document = await Document.findOne({
      _id: documentId,
      userId: req.user._id,
      status: "Ready",
    });

    if (!document) {
      return res.status(404).json({
        success: false,
        error: "Document not found or not ready",
        statusCode: 404,
      });
    }

    // Generate flashcards
    const cards = await geminiService.generateFlashcards(
      document.extractedText,
      parseInt(count),
    );

    // Save to database
    const flashcardSet = await Flashcard.create({
      userId: req.user._id,
      documentId: document._id,
      cards: cards.map((card) => ({
        question: card.question,
        answer: card.answer,
        difficulty: card.difficulty,
        reviewCount: 0,
        isStarred: false,
      })),
    });

    res.status(201).json({
      success: true,
      data: flashcardSet,
      message: "Flashcards generated successfully",
      statusCode: 200,
    });
  } catch (error) {
    next(error);
  }
};

// @desc Generate quiz from document
// @route POST /api/ai/generate-quiz
// @access Private
export const generateQuiz = async (req, res, next) => {
  try {
    const { documentId, numQuestions = 5, title } = req.body;

    if (!documentId) {
      return res.status(400).json({
        success: false,
        error: "Document ID is required",
        statusCode: 400,
      });
    }
    const document = await Document.findOne({
      _id: documentId,
      userId: req.user._id,
      status: "Ready",
    });

    if (!document) {
      return res.status(404).json({
        success: false,
        error: "Document not found or not ready",
        statusCode: 404,
      });
    }

    // Generate quiz using Gemini
    const questions = await geminiService.generateQuiz(
      document.extractedText,
      parseInt(numQuestions),
    );

    // Save to database
    const quiz = await Quiz.create({
      userId: req.user._id,
      documentId: document._id,
      title: title || `${document.title} - Quiz`,
      questions: questions,
      totalQuestions: questions.length,
      userAnswer: [],
      score: 0,
    });
    res.status(200).json({
      success: true,
      data: quiz,
      message: "Quiz generated successfully",
      statusCode: 200,
    });
  } catch (error) {
    next(error);
  }
};

// @desc Generate document summary
// @route POST /api/ai/generate-summary
// @access Private
export const generateSummary = async (req, res, next) => {
  try {
    const { documentId, length = 'standard' } = req.body;

    if (!documentId) {
      return res.status(400).json({
        success: false,
        error: "Document ID is required",
        statusCode: 400,
      });
    }

    const document = await Document.findOne({
      _id: documentId,
      userId: req.user._id,
      status: "Ready",
    });

    if (!document) {
      return res.status(404).json({
        success: false,
        error: "Document not found or not ready",
        statusCode: 404,
      });
    }

    const summary = await geminiService.generateSummary(document.extractedText, length);

    // Cache the generated summary on the document
    await Document.findByIdAndUpdate(document._id, { summary });

    res.status(200).json({
      success: true,
      data: {
        summary,
        documentId: document._id,
        title: document.title,
      },
      message: "Summary generated successfully",
      statusCode: 200,
    });
  } catch (error) {
    next(error);
  }
};

// @desc Extract key concepts from document
// @route POST /api/ai/extract-concepts
// @access Private
export const extractConcepts = async (req, res, next) => {
  try {
    const { documentId } = req.body;

    if (!documentId) {
      return res.status(400).json({
        success: false,
        error: "Document ID is required",
        statusCode: 400,
      });
    }

    const document = await Document.findOne({
      _id: documentId,
      userId: req.user._id,
      status: "Ready",
    });

    if (!document) {
      return res.status(404).json({
        success: false,
        error: "Document not found or not ready",
        statusCode: 404,
      });
    }

    const concepts = await geminiService.extractConcepts(document.extractedText);

    res.status(200).json({
      success: true,
      data: {
        concepts,
        documentId: document._id,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc Get cached summary for a document
// @route GET /api/ai/summary/:documentId
// @access Private
export const getSummary = async (req, res, next) => {
  try {
    const document = await Document.findOne({
      _id: req.params.documentId,
      userId: req.user._id,
    }).select('summary title');

    if (!document) {
      return res.status(404).json({ success: false, error: "Document not found", statusCode: 404 });
    }

    res.status(200).json({
      success: true,
      data: {
        summary: document.summary || null,
        documentId: document._id,
        title: document.title,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc Chat with document
// @route POST /api/ai/chat
// @access Private
export const chat = async (req, res, next) => {
  try {
    const { documentId, question } = req.body;

    if (!documentId || !question) {
      return res.status(400).json({
        success: false,
        error: "Document ID and question are required",
        statusCode: 400,
      });
    }

    const document = await Document.findOne({
      _id: documentId,
      userId: req.user._id,
      status: "Ready",
    });

    if (!document) {
      return res.status(404).json({
        success: false,
        error: "Document not found or not ready",
        statusCode: 404,
      });
    }

    // Find relevant chunks
    const relevantChunks = findRelevantChunks(document.chunks, question, 3);
    const chunkIndices = relevantChunks.map((c) => c.chunkIndex);

    // Get or create chat history
    let chatHistory = await ChatHistory.findOne({
      documentId: document._id,
      userId: req.user._id,
    });

    if (!chatHistory) {
      chatHistory = await ChatHistory.create({
        documentId: document._id,
        userId: req.user._id,
        messages: [],
      });
    }

    // Generate response using Gemini
    const answer = await geminiService.chatWithContext(
      question,
      relevantChunks,
    );

    // Save conversation to chat history
    chatHistory.messages.push(
      {
        role: "user",
        content: question,
        timestamp: new Date(),
        relevantChunks: [],
      },
      {
        role: "assistant",
        content: answer,
        timestamp: new Date(),
        relevantChunks: chunkIndices,
      },
    );
    await chatHistory.save();

    res.status(200).json({
      success: true,
      data: {
        question,
        answer,
        relevantChunks: chunkIndices,
        chatHistory: chatHistory._id,
      },
      message: "Response generated successfully",
      statusCode: 200,
    });
  } catch (error) {
    next(error);
  }
};

// @desc Explain concept from document
// @route POST /api/ai/explain-concept
// @access Private
export const explainConcept = async (req, res, next) => {
  try {
    const { documentId, concept } = req.body;

    if (!documentId || !concept) {
      return res.status(400).json({
        success: false,
        error: "Document ID and concept are required",
        statusCode: 400,
      });
    }

    const document = await Document.findOne({
      _id: documentId,
      userId: req.user._id,
      status: "Ready",
    });

    if (!document) {
      return res.status(404).json({
        success: false,
        error: "Document not found or not ready",
        statusCode: 404,
      });
    }

    // Find relevant chunks
    const relevantChunks = findRelevantChunks(document.chunks, concept, 3);
    const context = relevantChunks.map(c => c.content).join("\n\n");

    // Generate explanation using Gemini
    const explanation = await geminiService.explainConcept(concept, context);

    res.status(200).json({
      success: true,
      data: {
        concept,
        explanation,
       relevantChunks: relevantChunks.map(c => c.chunkIndex),
      },
      message: "Explanation generated successfully",
      statusCode: 200,
    });
  } catch (error) {
    next(error);
  }
};

// @desc Get chat history for a document
// @route GET /api/ai/chat-history/:documentId
// @access Private
export const getChatHistory = async (req, res, next) => {
  try {
    const { documentId } = req.params;

    if (!documentId) {
      return res.status(400).json({
        success: false,
        error: "Document ID is required",
        statusCode: 400,
      });
    }

    const chatHistoryResult = await ChatHistory.findOne({
      userId: req.user._id,
      documentId: documentId,
    }).select('messages'); // Only retrieve message array

    if (!chatHistoryResult) {
      return res.status(200).json({
        success: true,
        data: [], // Return an empty array if no chat history found
        message: "No chat history found",
      });
    }

    res.status(200).json({
      success: true,
      data: chatHistoryResult.messages,
      message: "Chat history retrieved successfully",
      statusCode: 200,
    });
  } catch (error) {
    next(error);
  }
};