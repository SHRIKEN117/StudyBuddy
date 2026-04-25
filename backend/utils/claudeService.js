import Anthropic from "@anthropic-ai/sdk";
import dotenv from "dotenv";

dotenv.config();

if (!process.env.ANTHROPIC_API_KEY) {
  console.error("FATAL ERROR: ANTHROPIC_API_KEY is not set in the environment variables.");
  process.exit(1);
}

const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

const MODEL = "claude-haiku-4-5-20251001";

const ask = async (prompt, maxTokens = 4096) => {
  const message = await client.messages.create({
    model: MODEL,
    max_tokens: maxTokens,
    messages: [{ role: "user", content: prompt }],
  });
  return message.content[0].text;
};

export const generateFlashcards = async (text, count = 10) => {
  const prompt = `Generate exactly ${count} educational flashcards from the following text.
Format each flashcard as:
Q: [Clear, specific question]
A: [Concise, accurate answer]
D: [Difficulty level: easy, medium, or hard]

Separate each flashcard with "---"

Text:
${text.substring(0, 15000)}`;

  try {
    const generatedText = await ask(prompt);
    const flashcards = [];
    const cards = generatedText.split("---").filter((c) => c.trim());

    for (const card of cards) {
      const lines = card.trim().split("\n");
      let question = "", answer = "", difficulty = "medium";

      for (const line of lines) {
        const trimmed = line.trim();
        if (trimmed.startsWith("Q:")) {
          question = trimmed.substring(2).trim();
        } else if (trimmed.startsWith("A:")) {
          answer = trimmed.substring(2).trim();
        } else if (trimmed.startsWith("D:")) {
          const diff = trimmed.substring(2).trim().toLowerCase();
          if (["easy", "medium", "hard"].includes(diff)) {
            difficulty = diff;
          }
        }
      }

      if (question && answer) {
        flashcards.push({ question, answer, difficulty });
      }
    }

    return flashcards.slice(0, count);
  } catch (error) {
    console.error("Claude API error (generateFlashcards):", error);
    throw new Error("Failed to generate flashcards");
  }
};

export const generateQuiz = async (text, numQuestions = 5) => {
  const prompt = `Generate exactly ${numQuestions} multiple choice questions from the following text.
Format each question as:
Q: [Question]
1. [Option 1]
2. [Option 2]
3. [Option 3]
4. [Option 4]
C: [Correct option text - exactly as written above]
E: [Brief explanation]
D: [Difficulty: easy, medium or hard]

Separate questions with "---"

Text:
${text.substring(0, 15000)}`;

  try {
    const generatedText = await ask(prompt);
    const questions = [];
    const questionBlocks = generatedText.split("---").filter((q) => q.trim());

    for (const block of questionBlocks) {
      const lines = block.trim().split("\n");
      let question = "", options = [], correctAnswer = "", explanation = "", difficulty = "medium";

      for (const line of lines) {
        const trimmed = line.trim();
        if (trimmed.startsWith("Q:")) {
          question = trimmed.substring(2).trim();
        } else if (trimmed.match(/^[1-4]\./)) {
          options.push(trimmed.replace(/^[1-4]\.\s*/, "").trim());
        } else if (trimmed.startsWith("C:")) {
          correctAnswer = trimmed.substring(2).trim();
        } else if (trimmed.startsWith("E:")) {
          explanation = trimmed.substring(2).trim();
        } else if (trimmed.startsWith("D:")) {
          const diff = trimmed.substring(2).trim().toLowerCase();
          if (["easy", "medium", "hard"].includes(diff)) {
            difficulty = diff;
          }
        }
      }

      if (question && options.length === 4 && correctAnswer) {
        questions.push({ question, options, correctAnswer, explanation, difficulty });
      }
    }

    return questions.slice(0, numQuestions);
  } catch (error) {
    console.error("Claude API error (generateQuiz):", error);
    throw new Error("Failed to generate quiz");
  }
};

export const generateSummary = async (text) => {
  const prompt = `Analyze the following document and produce a structured study summary in Markdown.

Use exactly this structure:

## Overview
2-3 sentences describing what this document covers.

## Key Concepts
Bullet-point list of the most important ideas and topics.

## Main Takeaways
Numbered list of the most important points to remember.

## Important Terms
A short glossary: each entry as **term** — definition.

Document:
${text.substring(0, 20000)}`;

  try {
    return await ask(prompt);
  } catch (error) {
    console.error("Claude API error (generateSummary):", error);
    throw new Error("Failed to generate summary");
  }
};

export const chatWithContext = async (question, chunks) => {
  const context = chunks
    .map((c, i) => `[Chunk ${i + 1}]\n${c.content}`)
    .join("\n\n");

  const prompt = `You are an expert study assistant AI specializing in answering questions based strictly on provided document context.

Context:
${context}

Question: ${question}

Answer:`;

  try {
    return await ask(prompt);
  } catch (error) {
    console.error("Claude API error (chatWithContext):", error);
    throw new Error("Failed to process chat request");
  }
};

export const explainConcept = async (concept, context) => {
  const prompt = `Explain the concept of "${concept}" based on the following context.
Provide a clear, educational explanation that is easy to understand.
Include examples if relevant.

Context:
${context.substring(0, 10000)}`;

  try {
    return await ask(prompt);
  } catch (error) {
    console.error("Claude API error (explainConcept):", error);
    throw new Error("Failed to explain concept");
  }
};
