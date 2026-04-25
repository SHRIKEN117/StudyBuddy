import fs from "fs/promises";
import { createRequire } from "module";

// pdf-parse is a CommonJS module; use createRequire for ESM compatibility
const require = createRequire(import.meta.url);
const pdfParse = require("pdf-parse");

/**
 * Extract text from PDF file
 * @param {string} filePath - Path to the PDF file
 * @returns {Promise<{text: string, numPages: number, info: object}>}
 */
export const extractTextFromPDF = async (filePath) => {
    try {
        const dataBuffer = await fs.readFile(filePath);
        const data = await pdfParse(dataBuffer);
        return {
            text: data.text,
            numPages: data.numpages,
            info: data.info,
        };
    } catch (error) {
        console.error("PDF parsing error:", error);
        throw new Error("Failed to extract text from PDF");
    }
};
