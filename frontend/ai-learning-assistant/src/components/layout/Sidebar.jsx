import React from "react";
import { NavLink, useNavigate } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";
import { LayoutDashboard, FileText, User, LogOut, Sparkles, X, Zap } from "lucide-react";

const Sidebar = ({ isSidebarOpen, toggleSidebar }) => {
    const { logout } = useAuth();
    const navigate = useNavigate();

    const handleLogout = () => {
        logout();
        navigate("/login");
    };

    const navLinks = [
        { to: '/dashboard', icon: LayoutDashboard, text: 'Dashboard' },
        { to: '/documents', icon: FileText, text: 'Documents' },
        { to: '/profile', icon: User, text: 'Profile' },
    ];

    return (
        <>
            {/* Mobile backdrop */}
            <div
                className={`fixed inset-0 bg-black/40 z-40 md:hidden transition-opacity duration-300 ${isSidebarOpen ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}
                onClick={toggleSidebar}
                aria-hidden="true"
            />

            <aside
                className={`fixed top-0 left-0 h-full w-64 bg-[#1E1B4B] z-50 flex flex-col md:relative md:translate-x-0 transition-transform duration-300 ease-in-out ${isSidebarOpen ? 'translate-x-0' : '-translate-x-full'}`}
            >
                {/* Brand */}
                <div className="flex items-center justify-between h-16 px-5 border-b border-white/10 shrink-0">
                    <div className="flex items-center gap-2.5">
                        <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-linear-to-br from-amber-400 to-amber-500 shadow-[0_4px_12px_rgba(245,158,11,0.35)]">
                            <Sparkles size={16} strokeWidth={2} className="text-white" />
                        </div>
                        <span className="text-white font-bold text-base tracking-tight" style={{ fontFamily: 'var(--font-heading)' }}>
                            studybuddy
                        </span>
                    </div>
                    <button
                        onClick={toggleSidebar}
                        className="md:hidden text-indigo-300 hover:text-white transition-colors duration-200"
                        aria-label="Close sidebar"
                    >
                        <X size={20} strokeWidth={1.5} />
                    </button>
                </div>

                {/* Navigation */}
                <nav className="flex-1 px-3 py-4 space-y-0.5 overflow-y-auto">
                    {navLinks.map((link) => (
                        <NavLink
                            key={link.to}
                            to={link.to}
                            onClick={() => { if (isSidebarOpen) toggleSidebar(); }}
                            className={({ isActive }) =>
                                `flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 border ${
                                    isActive
                                        ? 'bg-amber-500/15 border-amber-500/30 text-amber-300 shadow-[0_0_16px_rgba(245,158,11,0.12)]'
                                        : 'text-indigo-200 border-transparent hover:bg-white/[0.08] hover:text-white'
                                }`
                            }
                        >
                            <link.icon size={18} strokeWidth={1.5} />
                            {link.text}
                        </NavLink>
                    ))}

                    {/* Account section */}
                    <div className="pt-5">
                        <p className="px-3 mb-1 text-[10px] font-semibold uppercase tracking-wider text-indigo-200/60">
                            Account
                        </p>
                        <button
                            onClick={handleLogout}
                            className="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-indigo-200 border border-transparent hover:bg-rose-500/10 hover:text-rose-300 transition-all duration-200"
                        >
                            <LogOut size={18} strokeWidth={1.5} />
                            Logout
                        </button>
                    </div>
                </nav>

                {/* Pro upsell card */}
                <div className="p-3 border-t border-white/10 shrink-0">
                    <div className="rounded-xl bg-amber-500/10 border border-amber-500/20 p-4">
                        <div className="flex items-center gap-2 mb-2">
                            <Zap size={15} strokeWidth={2} className="text-amber-400" />
                            <span className="text-sm font-semibold text-amber-300" style={{ fontFamily: 'var(--font-heading)' }}>
                                StudyBuddy Pro
                            </span>
                        </div>
                        <p className="text-xs text-indigo-200/70 mb-3 leading-relaxed">
                            Unlimited AI generations and advanced analytics.
                        </p>
                        <button className="w-full h-8 rounded-lg bg-linear-to-r from-amber-400 to-amber-500 text-white text-xs font-semibold hover:from-amber-500 hover:to-amber-600 transition-all duration-[180ms] shadow-[0_4px_12px_rgba(245,158,11,0.3)] hover:-translate-y-px active:scale-[0.98]">
                            Upgrade now
                        </button>
                    </div>
                </div>
            </aside>
        </>
    );
};

export default Sidebar;
