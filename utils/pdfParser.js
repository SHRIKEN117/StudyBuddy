import { pathToFileURL } from "url";
import { PDFParse } from "pdf-parse";

/**
 * Extract text from a PDF given either a Buffer or a filesystem path.
 */
export const extractTextFromPDF = async (input) => {
  try {
    let parser;
    if (Buffer.isBuffer(input)) {
      parser = new PDFParse({ buffer: input });
    } else {
      const url = pathToFileURL(input).href;
      parser = new PDFParse({ url });
    }
    const data = await parser.getText();
    return {
      text: data.text ?? "",
      numPages: data.total ?? data.pages?.length ?? 0,
      info: {},
    };
  } catch (error) {
    console.error("PDF parsing error:", error);
    throw new Error(`Failed to extract text from PDF: ${error.message}`);
  }
};
