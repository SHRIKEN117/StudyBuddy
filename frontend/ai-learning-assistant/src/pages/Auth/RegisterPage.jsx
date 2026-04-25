import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import authService from '../../services/authService';
import { Sparkles, Mail, Lock, ArrowRight, User, Star } from 'lucide-react';
import toast from 'react-hot-toast';

const RegisterPage = () => {
  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [focusedField, setFocusedField] = useState(null);

  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (password.length < 6) {
      setError('Password must be at least 6 characters long.');
      return;
    }
    setError('');
    setLoading(true);
    try {
      await authService.register(username, email, password);
      toast.success('Account created! Please sign in.');
      navigate('/login');
    } catch (err) {
      setError(err.message || 'Failed to register. Please try again.');
      toast.error(err.message || 'Failed to register.');
    } finally {
      setLoading(false);
    }
  };

  const inputClass = (field) =>
    `w-full h-11 pl-10 pr-4 text-sm text-stone-900 placeholder-stone-400 border border-stone-200 rounded-[10px] bg-white transition-all duration-200 focus:outline-none focus:border-indigo-500 focus:ring-2 focus:ring-indigo-500/20 ${
      focusedField === field ? 'border-indigo-500 ring-2 ring-indigo-500/20' : ''
    }`;

  const iconClass = (field) =>
    `absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none transition-colors duration-200 ${
      focusedField === field ? 'text-indigo-500' : 'text-stone-400'
    }`;

  return (
    <div className="flex min-h-screen">
      {/* Left panel */}
      <div className="hidden lg:flex lg:flex-[5] flex-col justify-between p-10 bg-[#1E1B4B] relative overflow-hidden">
        <div className="absolute top-0 right-0 w-96 h-96 bg-amber-500/10 rounded-full blur-3xl pointer-events-none" />
        <div className="absolute bottom-0 left-0 w-80 h-80 bg-indigo-500/20 rounded-full blur-3xl pointer-events-none" />

        {/* Brand */}
        <div className="relative flex items-center gap-2.5 z-10">
          <div className="flex items-center justify-center w-9 h-9 rounded-xl bg-linear-to-br from-amber-400 to-amber-500 shadow-[0_4px_12px_rgba(245,158,11,0.35)]">
            <Sparkles size={18} strokeWidth={2} className="text-white" />
          </div>
          <span className="text-white font-bold text-lg tracking-tight" style={{ fontFamily: 'var(--font-heading)' }}>
            studybuddy
          </span>
        </div>

        {/* Pitch */}
        <div className="relative z-10 space-y-4">
          <h2 className="text-4xl font-bold text-white leading-tight" style={{ fontFamily: 'var(--font-heading)', letterSpacing: '-0.02em' }}>
            Study smarter,<br />not{' '}
            <span className="text-amber-300">harder.</span>
          </h2>
          <p className="text-indigo-200/80 text-base leading-relaxed max-w-xs">
            Upload a PDF and get instant flashcards, quizzes, and an AI tutor to quiz you on it.
          </p>
        </div>

        {/* Testimonial */}
        <div className="relative z-10 bg-white/[0.08] border border-white/10 rounded-2xl p-5 backdrop-blur-sm">
          <div className="flex gap-1 mb-3">
            {[...Array(5)].map((_, i) => (
              <Star key={i} size={13} strokeWidth={0} className="fill-amber-400 text-amber-400" />
            ))}
          </div>
          <p className="text-indigo-100 text-sm leading-relaxed mb-4">
            "StudyBuddy turned my 80-page textbook into a focused study session. My GPA jumped a whole point."
          </p>
          <div className="flex items-center gap-2.5">
            <div className="w-8 h-8 rounded-full bg-indigo-400/30 flex items-center justify-center text-white text-xs font-bold">M</div>
            <div>
              <p className="text-white text-xs font-semibold">Maya L.</p>
              <p className="text-indigo-300/70 text-[11px]">Pre-Med, UCLA</p>
            </div>
          </div>
        </div>
      </div>

      {/* Right panel */}
      <div
        className="flex-[6] flex items-center justify-center bg-stone-50 px-6 py-12 relative"
        style={{
          backgroundImage: 'radial-gradient(at 70% 10%, rgba(79,70,229,0.05) 0, transparent 50%), radial-gradient(at 30% 90%, rgba(245,158,11,0.04) 0, transparent 50%)',
        }}
      >
        <div className="w-full max-w-[380px]">
          {/* Mobile brand */}
          <div className="lg:hidden flex items-center gap-2 mb-8">
            <div className="w-8 h-8 rounded-lg bg-linear-to-br from-amber-400 to-amber-500 flex items-center justify-center">
              <Sparkles size={15} strokeWidth={2} className="text-white" />
            </div>
            <span className="font-bold text-stone-900" style={{ fontFamily: 'var(--font-heading)' }}>studybuddy</span>
          </div>

          <div className="mb-8">
            <h1 className="text-4xl font-bold text-stone-900 tracking-tight mb-1.5" style={{ fontFamily: 'var(--font-heading)', letterSpacing: '-0.02em' }}>
              Create an account
            </h1>
            <p className="text-stone-500 text-sm">Start your AI-powered learning experience.</p>
          </div>

          <form onSubmit={handleSubmit} className="space-y-4">
            {/* Username */}
            <div className="space-y-1.5">
              <label className="block text-xs font-semibold text-stone-700 uppercase tracking-wide">Username</label>
              <div className="relative">
                <div className={iconClass('username')}>
                  <User size={16} strokeWidth={2} />
                </div>
                <input
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  onFocus={() => setFocusedField('username')}
                  onBlur={() => setFocusedField(null)}
                  required
                  className={inputClass('username')}
                  placeholder="Your name"
                />
              </div>
            </div>

            {/* Email */}
            <div className="space-y-1.5">
              <label className="block text-xs font-semibold text-stone-700 uppercase tracking-wide">Email</label>
              <div className="relative">
                <div className={iconClass('email')}>
                  <Mail size={16} strokeWidth={2} />
                </div>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  onFocus={() => setFocusedField('email')}
                  onBlur={() => setFocusedField(null)}
                  required
                  className={inputClass('email')}
                  placeholder="you@example.com"
                />
              </div>
            </div>

            {/* Password */}
            <div className="space-y-1.5">
              <label className="block text-xs font-semibold text-stone-700 uppercase tracking-wide">Password</label>
              <div className="relative">
                <div className={iconClass('password')}>
                  <Lock size={16} strokeWidth={2} />
                </div>
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  onFocus={() => setFocusedField('password')}
                  onBlur={() => setFocusedField(null)}
                  required
                  className={inputClass('password')}
                  placeholder="Min. 6 characters"
                />
              </div>
            </div>

            {error && (
              <div className="rounded-lg bg-red-50 border border-red-200 px-3 py-2.5">
                <p className="text-xs text-red-600 font-medium">{error}</p>
              </div>
            )}

            {/* Submit */}
            <button
              type="submit"
              disabled={loading}
              className="group w-full h-11 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold rounded-[10px] transition-all duration-[180ms] ease-out hover:-translate-y-px hover:shadow-[0_8px_24px_rgba(79,70,229,0.18)] active:scale-[0.98] active:translate-y-0 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:translate-y-0 focus:outline-none focus:ring-2 focus:ring-indigo-500/30 flex items-center justify-center gap-2 mt-2"
            >
              {loading ? (
                <>
                  <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  Creating account...
                </>
              ) : (
                <>
                  Create account
                  <ArrowRight size={16} strokeWidth={2.5} className="group-hover:translate-x-0.5 transition-transform duration-200" />
                </>
              )}
            </button>
          </form>

          <p className="mt-6 text-sm text-center text-stone-500">
            Already have an account?{' '}
            <Link to="/login" className="font-semibold text-indigo-600 hover:text-indigo-700 transition-colors">
              Sign in
            </Link>
          </p>

          <p className="text-[11px] text-center text-stone-400 mt-8">
            By continuing you agree to our Terms &amp; Privacy Policy
          </p>
        </div>
      </div>
    </div>
  );
};

export default RegisterPage;
