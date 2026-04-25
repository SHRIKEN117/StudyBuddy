import React from 'react'

const PageHeader = ({ title, subtitle, children }) => {
  return (
    <div className='flex items-center justify-between mb-6'>
      <div>
        <h1
          className='text-3xl font-bold text-stone-900 tracking-tight'
          style={{ fontFamily: 'var(--font-heading)' }}
        >
          {title}
        </h1>
        {subtitle && (
          <p className='mt-1 text-sm text-stone-500'>{subtitle}</p>
        )}
      </div>
      {children}
    </div>
  )
}

export default PageHeader
