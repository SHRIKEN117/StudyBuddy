const errorHandler = (err, req, res, next) => {
    let statusCode = err.statusCode || 500;
    let message = err.message || "Server Error";

    // Mongoose bad ObjectId
    if (err.name === 'CastError') {
        statusCode = 404;
        message = "Resource not found";
    }

    // Mongoose duplicate key
    if (err.code === 11000) {
        const field = Object.keys(err.keyValue)[0];
        statusCode = 400;
        message = `${field} already exists`;
    }

    // Mongoose validation error
    if (err.name === "ValidationError") {
        statusCode = 400;
        message = Object.values(err.errors).map(val => val.message).join(", ");
    }

    // Multer file upload error
    if (err.name === "LIMIT_FILE_SIZE") {
        statusCode = 400;
        message = 'File size exceeds the maximum limit of 10MB';
    }

    // JWT errors
    if (err.name === "JsonWebTokenError") {
        statusCode = 401;
        message = "Invalid token";
    }

    if (err.name === "TokenExpiredError") {
        statusCode = 401;
        message = "Token expired";
    }

    console.error('Error:', {
        message: err.message,
        stack: process.env.NODE_ENV === "development" ? err.stack : undefined,
    });

    res.status(statusCode).json({ 
        success: false,
        error: message,
        statusCode,
        ...(process.env.NODE_ENV === "development" && { stack: err.stack })
    });
};

export default errorHandler;