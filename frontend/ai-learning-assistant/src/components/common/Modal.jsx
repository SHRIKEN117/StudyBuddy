import React from 'react'
import { X } from 'lucide-react'

const Modal = ({ isOpen, onClose, title, children }) => {
    if (!isOpen) return null;

    return (
        <div className='fixed inset-0 z-50 overflow-y-auto'>
            <div className='flex items-center justify-center min-h-screen px-4 py-8'>
                <div
                    className='fixed inset-0 bg-stone-900/50 backdrop-blur-sm transition-opacity'
                    onClick={onClose}
                />
                <div className='relative w-full max-w-lg bg-white border border-stone-200 rounded-[24px] shadow-[0_12px_32px_rgba(28,25,23,0.08),0_4px_8px_rgba(28,25,23,0.04)] p-8 z-10 animate-in fade-in slide-in-from-bottom-4 duration-300'>
                    <button
                        onClick={onClose}
                        className='absolute top-6 right-6 w-8 h-8 flex items-center justify-center rounded-lg text-stone-400 hover:text-stone-700 hover:bg-stone-100 transition-all duration-200'
                    >
                        <X className='w-5 h-5' strokeWidth={1.5} />
                    </button>
                    <div className='mb-6 pr-8'>
                        <h3 className='text-lg font-semibold text-stone-900 tracking-tight' style={{ fontFamily: 'var(--font-heading)' }}>
                            {title}
                        </h3>
                    </div>
                    <div>
                        {children}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Modal;
