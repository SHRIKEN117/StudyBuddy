import React, { useState, useEffect } from 'react';
import { Sparkles, RefreshCw, BookOpen } from 'lucide-react';
import aiService from '../../services/aiService';
import MarkdownRenderer from '../common/MarkdownRenderer';
import Spinner from '../common/Spinner';
import toast from 'react-hot-toast';

const SummaryTab = ({ documentId }) => {
    const [summary, setSummary] = useState(null);
    const [loading, setLoading] = useState(true);
    const [generating, setGenerating] = useState(false);

    useEffect(() => {
        const loadCached = async () => {
            try {
                const data = await aiService.getSummary(documentId);
                if (data?.summary) setSummary(data.summary);
            } catch {
                // No cached summary — that's fine, show empty state
            } finally {
                setLoading(false);
            }
        };
        loadCached();
    }, [documentId]);

    const handleGenerate = async () => {
        setGenerating(true);
        try {
            const data = await aiService.generateSummary(documentId);
            setSummary(data?.summary);
            toast.success('Summary generated!');
        } catch (error) {
            toast.error(error.message || 'Failed to generate summary.');
        } finally {
            setGenerating(false);
        }
    };

    if (loading) {
        return (
            <div className="flex items-center justify-center py-20">
                <Spinner />
            </div>
        );
    }

    if (!summary) {
        return (
            <div className="flex flex-col items-center justify-center py-16 px-6 text-center bg-stone-50 border-2 border-dashed border-stone-200 rounded-2xl">
                <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-amber-50 mb-4">
                    <BookOpen className="w-8 h-8 text-amber-500" strokeWidth={1.5} />
                </div>
                <h3 className="text-base font-semibold text-stone-800 mb-2">No summary yet</h3>
                <p className="text-sm text-stone-500 mb-8 max-w-sm leading-relaxed">
                    Generate an AI-powered summary with an overview, key concepts, main takeaways, and important terms.
                </p>
                <button
                    onClick={handleGenerate}
                    disabled={generating}
                    className="inline-flex items-center gap-2 px-6 h-11 bg-linear-to-r from-amber-400 to-amber-500 hover:from-amber-500 hover:to-amber-600 text-white text-sm font-semibold rounded-xl transition-all duration-200 shadow-lg shadow-amber-500/20 hover:-translate-y-px active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:translate-y-0"
                >
                    {generating ? (
                        <>
                            <div className="w-4 h-4 rounded-full border-2 border-white/30 border-t-white animate-spin" />
                            Generating...
                        </>
                    ) : (
                        <>
                            <Sparkles className="w-4 h-4" strokeWidth={2} />
                            Generate Summary
                        </>
                    )}
                </button>
            </div>
        );
    }

    return (
        <div className="bg-white border border-stone-200 rounded-2xl p-6 shadow-sm">
            <div className="flex items-center justify-between mb-5">
                <div className="flex items-center gap-2.5">
                    <div className="w-8 h-8 rounded-lg bg-amber-50 flex items-center justify-center">
                        <Sparkles className="w-4 h-4 text-amber-500" strokeWidth={2} />
                    </div>
                    <h3
                        className="text-base font-semibold text-stone-900"
                        style={{ fontFamily: 'var(--font-heading)' }}
                    >
                        AI Summary
                    </h3>
                </div>
                <button
                    onClick={handleGenerate}
                    disabled={generating}
                    className="inline-flex items-center gap-1.5 px-3 h-8 text-xs font-semibold text-stone-600 bg-stone-100 hover:bg-stone-200 rounded-lg transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                    <RefreshCw className={`w-3.5 h-3.5 ${generating ? 'animate-spin' : ''}`} strokeWidth={2} />
                    {generating ? 'Regenerating...' : 'Regenerate'}
                </button>
            </div>
            <div className="prose prose-sm max-w-none prose-stone">
                <MarkdownRenderer content={summary} />
            </div>
        </div>
    );
};

export default SummaryTab;
