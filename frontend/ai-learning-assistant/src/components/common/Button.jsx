import React from 'react';

const Button = ({
    children,
    onClick,
    type = "button",
    disabled = false,
    className = '',
    variant = "primary",
    size = "md",
}) => {
    const baseStyles = 'inline-flex items-center justify-center gap-2 font-semibold rounded-[10px] transition-all duration-[180ms] ease-out hover:-translate-y-px active:scale-[0.98] active:translate-y-0 disabled:opacity-50 disabled:cursor-not-allowed disabled:active:scale-100 disabled:hover:translate-y-0 whitespace-nowrap';

    const variantStyles = {
        primary: 'bg-indigo-600 text-white shadow-sm hover:bg-indigo-700 hover:shadow-[0_8px_24px_rgba(79,70,229,0.18)]',
        ai: 'bg-linear-to-r from-amber-400 to-amber-500 text-white shadow-sm hover:from-amber-500 hover:to-amber-600 hover:shadow-[0_8px_24px_rgba(245,158,11,0.25)]',
        secondary: 'bg-stone-100 text-stone-700 hover:bg-stone-200',
        outline: 'bg-white border border-stone-200 text-stone-700 hover:bg-stone-50 hover:border-stone-300',
        danger: 'bg-linear-to-r from-red-500 to-rose-500 text-white shadow-sm shadow-red-500/25 hover:from-red-600 hover:to-rose-600',
    };

    const sizeStyles = {
        sm: 'h-9 px-4 text-xs',
        md: 'h-11 px-5 text-sm',
    };

    return (
        <button
            type={type}
            onClick={onClick}
            disabled={disabled}
            className={[baseStyles, variantStyles[variant] ?? variantStyles.primary, sizeStyles[size], className].join(' ')}
        >
            {children}
        </button>
    );
};

export default Button;
