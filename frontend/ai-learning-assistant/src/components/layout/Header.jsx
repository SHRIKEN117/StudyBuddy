import React from "react";
import { useAuth } from "../../context/AuthContext";
import { Bell, Menu, Search } from "lucide-react";

const Header = ({ toggleSidebar }) => {
    const { user } = useAuth();

    return (
        <header className="sticky top-0 z-50 w-full h-14 bg-stone-50/85 backdrop-blur-[8px] border-b border-stone-200">
            <div className="flex items-center justify-between h-full px-4">
                {/* Mobile menu button */}
                <button
                    onClick={toggleSidebar}
                    className="md:hidden inline-flex items-center justify-center w-9 h-9 text-stone-500 hover:text-stone-900 hover:bg-stone-100 rounded-lg transition-all duration-200"
                    aria-label="Toggle sidebar"
                >
                    <Menu size={20} strokeWidth={1.5} />
                </button>
                <div className="hidden md:block" />

                <div className="flex items-center gap-1">
                    {/* Search */}
                    <button className="inline-flex items-center justify-center w-9 h-9 text-stone-500 hover:text-stone-900 hover:bg-stone-100 rounded-lg transition-all duration-200">
                        <Search size={18} strokeWidth={1.5} />
                    </button>

                    {/* Bell with amber dot */}
                    <button className="relative inline-flex items-center justify-center w-9 h-9 text-stone-500 hover:text-stone-900 hover:bg-stone-100 rounded-lg transition-all duration-200">
                        <Bell size={18} strokeWidth={1.5} />
                        <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-amber-500 rounded-full ring-2 ring-stone-50" />
                    </button>

                    {/* User chip */}
                    <div className="flex items-center gap-2 pl-2 ml-1 border-l border-stone-200">
                        <div className="flex items-center gap-2 px-2 py-1.5 rounded-lg hover:bg-stone-100 transition-all duration-200 cursor-pointer">
                            <div className="w-7 h-7 flex items-center justify-center rounded-lg bg-indigo-600 text-white text-xs font-bold shrink-0">
                                {user?.username?.charAt(0).toUpperCase() || 'U'}
                            </div>
                            <div className="hidden sm:block">
                                <p className="text-xs font-semibold text-stone-800 leading-none">{user?.username || 'User'}</p>
                                <p className="text-[11px] text-stone-400 mt-0.5 leading-none truncate max-w-[120px]">{user?.email || ''}</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </header>
    );
};

export default Header;
