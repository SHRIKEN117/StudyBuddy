import React from 'react'

const Tabs = ({ tabs, activeTab, setActiveTab }) => {
    return (
        <div className='w-full'>
            <div className='relative border-b border-stone-200'>
                <nav className='flex gap-1'>
                    {tabs.map((tab) => (
                        <button
                            key={tab.name}
                            className={`relative pb-3 px-4 text-sm font-semibold transition-colors duration-200 ${
                                activeTab === tab.name
                                    ? 'text-indigo-600'
                                    : 'text-stone-500 hover:text-stone-800'
                            }`}
                            onClick={() => setActiveTab(tab.name)}
                        >
                            <span className='flex items-center gap-2'>
                                {tab.label}
                                {tab.count != null && (
                                    <span className={`inline-flex items-center justify-center min-w-[20px] h-5 px-1.5 rounded-full text-[11px] font-semibold ${
                                        activeTab === tab.name
                                            ? 'bg-indigo-100 text-indigo-700'
                                            : 'bg-stone-100 text-stone-500'
                                    }`}>
                                        {tab.count}
                                    </span>
                                )}
                            </span>
                            {activeTab === tab.name && (
                                <span className='absolute bottom-0 left-0 right-0 h-0.5 bg-indigo-600 rounded-full' />
                            )}
                        </button>
                    ))}
                </nav>
            </div>
            <div className='py-6'>
                {tabs.map((tab) =>
                    tab.name === activeTab ? (
                        <div key={tab.name} className='animate-in fade-in duration-300'>
                            {tab.content}
                        </div>
                    ) : null
                )}
            </div>
        </div>
    );
};

export default Tabs;
