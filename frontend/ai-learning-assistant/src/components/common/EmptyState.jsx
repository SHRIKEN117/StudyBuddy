import React from 'react';
import { FileText, Plus } from 'lucide-react';

const EmptyState = ({ onActionClick, title, description, buttonText }) => {
    return (
        <div className="flex flex-col items-center justify-center py-16 px-6 text-center bg-stone-50 border-2 border-dashed border-stone-200 rounded-2xl">
            <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-stone-100 mb-4">
                <FileText className="w-8 h-8 text-stone-400" strokeWidth={1.5} />
            </div>
            <h3 className="text-base font-semibold text-stone-800 mb-2">{title}</h3>
            <p className='text-sm text-stone-500 mb-8 max-w-sm leading-relaxed'>{description}</p>
            {buttonText && onActionClick && (
                <button
                    onClick={onActionClick}
                    className="inline-flex items-center gap-2 px-6 h-11 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold rounded-xl transition-all duration-200 shadow-lg shadow-indigo-500/20 hover:-translate-y-px active:scale-[0.98]"
                >
                    <Plus className="w-4 h-4" strokeWidth={2.5} />
                    {buttonText}
                </button>
            )}
        </div>
    )
}

export default EmptyState
