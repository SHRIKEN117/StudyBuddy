import React from 'react';
import { useNavigate } from 'react-router-dom';
import { FileText, Trash2, BookOpen, BrainCircuit, Clock } from 'lucide-react';
import moment from 'moment';

const formatFileSize = (bytes) => {
    if (bytes == null) return 'N/A';
    const units = ['B', 'KB', 'MB', 'GB'];
    let size = bytes;
    let i = 0;
    while (size >= 1024 && i < units.length - 1) { size /= 1024; i++; }
    return `${size.toFixed(1)} ${units[i]}`;
};

const formatReadTime = (wordCount) => {
    if (!wordCount) return null;
    const minutes = Math.ceil(wordCount / 200);
    return minutes < 60
        ? `~${minutes} min read`
        : `~${Math.round(minutes / 60)}h read`;
};

const DocumentCard = ({ document, onDelete }) => {
    const navigate = useNavigate();
    const readTime = formatReadTime(document.wordCount);

    return (
        <div
            className="group relative bg-white border border-stone-200 rounded-2xl p-5 hover:border-indigo-200 hover:shadow-[0_4px_12px_rgba(28,25,23,0.06),0_1px_3px_rgba(28,25,23,0.04)] transition-all duration-[240ms] ease-out hover:-translate-y-px flex flex-col justify-between cursor-pointer"
            onClick={() => navigate(`/documents/${document._id}`)}
        >
            {/* Header row */}
            <div>
                <div className="flex items-start justify-between gap-3 mb-4">
                    <div className="shrink-0 w-11 h-11 bg-indigo-600 rounded-xl flex items-center justify-center shadow-sm group-hover:shadow-[0_4px_12px_rgba(79,70,229,0.25)] transition-shadow duration-300">
                        <FileText className="w-5 h-5 text-white" strokeWidth={2} />
                    </div>
                    <button
                        onClick={(e) => { e.stopPropagation(); onDelete(document); }}
                        className="opacity-0 group-hover:opacity-100 w-8 h-8 flex items-center justify-center text-stone-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-all duration-200"
                    >
                        <Trash2 className="w-4 h-4" strokeWidth={2} />
                    </button>
                </div>

                {/* Title */}
                <h3 className="text-sm font-semibold text-stone-900 truncate mb-1" title={document.title}>
                    {document.title}
                </h3>

                {/* File size + read time */}
                <div className="flex items-center gap-2 mb-3">
                    {document.fileSize != null && (
                        <span className="text-xs text-stone-400">{formatFileSize(document.fileSize)}</span>
                    )}
                    {readTime && (
                        <>
                            <span className="text-stone-300 text-xs">·</span>
                            <span className="text-xs text-stone-400">{readTime}</span>
                        </>
                    )}
                </div>

                {/* Badges */}
                <div className='flex flex-wrap items-center gap-2'>
                    {document.flashcardCount != null && (
                        <div className='flex items-center gap-1.5 px-2.5 py-1 bg-indigo-50 rounded-md'>
                            <BookOpen className="w-3.5 h-3.5 text-indigo-500" strokeWidth={2} />
                            <span className='text-xs font-semibold text-indigo-700'>
                                {document.flashcardCount} {document.flashcardCount === 1 ? 'Set' : 'Sets'}
                            </span>
                        </div>
                    )}
                    {document.quizCount != null && document.quizCount > 0 && (
                        <div className='flex items-center gap-1.5 px-2.5 py-1 bg-amber-50 rounded-md'>
                            <BrainCircuit className="w-3.5 h-3.5 text-amber-500" strokeWidth={2} />
                            <span className='text-xs font-semibold text-amber-700'>
                                {document.quizCount} {document.quizCount === 1 ? 'Quiz' : 'Quizzes'}
                            </span>
                        </div>
                    )}
                </div>

                {/* Footer */}
                <div className='mt-4 pt-4 border-t border-stone-100'>
                    <div className="flex items-center gap-1.5 text-xs text-stone-400">
                        <Clock className="w-3.5 h-3.5" strokeWidth={2} />
                        <span>Uploaded {moment(document.createdAt).fromNow()}</span>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default DocumentCard;
