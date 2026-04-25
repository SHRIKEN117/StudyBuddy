import React, { useState, useEffect, useCallback } from 'react';
import { Star, RotateCcw } from "lucide-react";

const Flashcard = ({ flashcard, onToggleStar }) => {
    const [isFlipped, setIsFlipped] = useState(false);

    const handleFlip = useCallback(() => {
        setIsFlipped(prev => !prev);
    }, []);

    useEffect(() => {
        const handleKeyDown = (e) => {
            if (e.code === 'Space') {
                e.preventDefault();
                handleFlip();
            }
        };
        window.addEventListener('keydown', handleKeyDown);
        return () => window.removeEventListener('keydown', handleKeyDown);
    }, [handleFlip]);

    const StarButton = ({ className = '' }) => (
        <button
            onClick={(e) => { e.stopPropagation(); onToggleStar(flashcard._id); }}
            className={`w-8 h-8 flex items-center justify-center rounded-lg transition-all duration-200 ${
                flashcard.isStarred
                    ? 'bg-amber-400 text-white shadow-[0_4px_8px_rgba(245,158,11,0.35)]'
                    : 'bg-stone-100 text-stone-400 hover:bg-amber-50 hover:text-amber-500'
            } ${className}`}
        >
            <Star className='w-4 h-4' strokeWidth={2} fill={flashcard.isStarred ? 'currentColor' : 'none'} />
        </button>
    );

    return (
        <div className='relative w-full h-72' style={{ perspective: '1200px' }}>
            <div
                className='relative w-full h-64 cursor-pointer'
                style={{
                    transformStyle: 'preserve-3d',
                    transition: 'transform 600ms cubic-bezier(0.4, 0, 0.2, 1)',
                    transform: isFlipped ? 'rotateY(180deg)' : 'rotateY(0deg)',
                }}
                onClick={handleFlip}
            >
                {/* Front — Question */}
                <div
                    className='absolute inset-0 w-full h-full bg-white border border-stone-200 rounded-2xl shadow-[0_4px_12px_rgba(28,25,23,0.06),0_1px_3px_rgba(28,25,23,0.04)] p-6 flex flex-col'
                    style={{ backfaceVisibility: 'hidden', WebkitBackfaceVisibility: 'hidden' }}
                >
                    <div className='flex items-start justify-between mb-4'>
                        {/* Amber pin */}
                        <div className='flex items-center gap-2'>
                            <span className='inline-flex items-center px-2.5 py-1 rounded-md bg-amber-50 border border-amber-200 text-[11px] font-semibold text-amber-700 uppercase tracking-wide'>
                                {flashcard?.difficulty || 'medium'}
                            </span>
                        </div>
                        <StarButton />
                    </div>

                    <div className='flex-1 flex items-center justify-center px-2 py-4'>
                        <p className='text-xl font-semibold text-stone-900 text-center leading-relaxed'>
                            {flashcard.question}
                        </p>
                    </div>

                    <div className='flex items-center gap-2 justify-center text-xs text-stone-400 font-medium'>
                        <RotateCcw className='w-3.5 h-3.5' strokeWidth={2} />
                        <span>Click or press space to reveal answer</span>
                    </div>
                </div>

                {/* Back — Answer */}
                <div
                    className='absolute inset-0 w-full h-full bg-amber-50 border border-amber-200 rounded-2xl shadow-[0_4px_12px_rgba(245,158,11,0.12),0_1px_3px_rgba(245,158,11,0.08)] p-6 flex flex-col'
                    style={{
                        backfaceVisibility: 'hidden',
                        WebkitBackfaceVisibility: 'hidden',
                        transform: 'rotateY(180deg)',
                    }}
                >
                    <div className='flex items-start justify-between mb-4'>
                        <span className='inline-flex items-center px-2.5 py-1 rounded-md bg-indigo-100 border border-indigo-200 text-[11px] font-semibold text-indigo-700 uppercase tracking-wide'>
                            Answer
                        </span>
                        <StarButton />
                    </div>

                    <div className='flex-1 flex items-center justify-center px-2 py-4'>
                        <p className='text-lg font-medium text-stone-800 text-center leading-relaxed'>
                            {flashcard.answer}
                        </p>
                    </div>

                    <div className='flex items-center gap-2 justify-center text-xs text-amber-600/70 font-medium'>
                        <RotateCcw className='w-3.5 h-3.5' strokeWidth={2} />
                        <span>Click or press space to see question</span>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Flashcard;
