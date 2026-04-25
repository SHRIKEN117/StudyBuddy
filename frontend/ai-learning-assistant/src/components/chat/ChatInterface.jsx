import React, { useState, useEffect, useRef } from 'react';
import { Send, MessageSquare, Sparkles } from 'lucide-react';
import { useParams } from 'react-router-dom';
import aiService from '../../services/aiService';
import { useAuth } from '../../context/AuthContext';
import Spinner from '../common/Spinner';
import MarkdownRenderer from "../common/MarkdownRenderer";

const ChatInterface = () => {
    const { id: documentId } = useParams();
    const { user } = useAuth();
    const [history, setHistory] = useState([]);
    const [message, setMessage] = useState('');
    const [loading, setLoading] = useState(false);
    const [initialLoading, setInitialLoading] = useState(true);
    const messagesEndRef = useRef(null);

    const scrollToBottom = () => {
        messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
    };

    useEffect(() => {
        const fetchChatHistory = async () => {
            try {
                setInitialLoading(true);
                const response = await aiService.getChatHistory(documentId);
                setHistory(response.data);
            } catch (error) {
                console.error('Failed to fetch chat history:', error);
            } finally {
                setInitialLoading(false);
            }
        };
        fetchChatHistory();
    }, [documentId]);

    useEffect(() => {
        scrollToBottom();
    }, [history]);

    const handleSendMessage = async (e) => {
        e.preventDefault();
        if (!message.trim()) return;

        const userMessage = { role: 'user', content: message, timestamp: new Date() };
        setHistory(prev => [...prev, userMessage]);
        setMessage('');
        setLoading(true);

        try {
            const response = await aiService.chat(documentId, userMessage.content);
            const assistantMessage = {
                role: 'assistant',
                content: response.data.answer,
                timestamp: new Date(),
                relevantChunks: response.data.relevantChunks
            };
            setHistory(prev => [...prev, assistantMessage]);
        } catch (error) {
            console.error('Chat error:', error);
            const errorMessage = {
                role: 'assistant',
                content: 'Sorry, I encountered an error. Please try again later.',
                timestamp: new Date(),
            };
            setHistory(prev => [...prev, errorMessage]);
        } finally {
            setLoading(false);
        }
    };

    const renderMessage = (msg, index) => {
        const isUser = msg.role === "user";
        return (
            <div key={index} className={`flex items-start gap-3 my-3 ${isUser ? 'justify-end' : ''}`}>
                {!isUser && (
                    <div className="w-8 h-8 rounded-xl bg-linear-to-br from-amber-400 to-amber-500 shadow-[0_4px_8px_rgba(245,158,11,0.25)] flex items-center justify-center shrink-0 mt-0.5">
                        <Sparkles className="w-4 h-4 text-white" strokeWidth={2} />
                    </div>
                )}

                <div
                    className={`max-w-[72%] px-4 py-3 text-[15px] leading-relaxed ${
                        isUser
                            ? 'bg-indigo-600 text-white shadow-[0_4px_12px_rgba(79,70,229,0.18)]'
                            : 'bg-white border border-stone-200 text-stone-900 shadow-[0_1px_2px_rgba(28,25,23,0.04)]'
                    }`}
                    style={{ borderRadius: isUser ? '18px 18px 4px 18px' : '4px 18px 18px 18px' }}
                >
                    {isUser ? (
                        <p>{msg.content}</p>
                    ) : (
                        <div className="prose prose-sm max-w-none prose-stone">
                            <MarkdownRenderer content={msg.content} />
                        </div>
                    )}
                </div>

                {isUser && (
                    <div className="w-8 h-8 rounded-xl bg-indigo-100 flex items-center justify-center text-indigo-700 font-bold text-sm shrink-0 mt-0.5">
                        {user?.username?.charAt(0).toUpperCase() || 'U'}
                    </div>
                )}
            </div>
        );
    };

    if (initialLoading) {
        return (
            <div className="flex flex-col h-[70vh] bg-white border border-stone-200 rounded-2xl items-center justify-center shadow-sm">
                <div className="w-12 h-12 rounded-xl bg-amber-50 flex items-center justify-center mb-4">
                    <MessageSquare className="w-6 h-6 text-amber-500" strokeWidth={1.5} />
                </div>
                <Spinner />
                <p className="text-sm text-stone-500 mt-3 font-medium">Loading chat history...</p>
            </div>
        );
    }

    return (
        <div className="flex flex-col h-[70vh] bg-white border border-stone-200 rounded-2xl shadow-sm overflow-hidden">
            {/* Messages Area */}
            <div className="flex-1 p-5 overflow-y-auto bg-stone-50/40">
                {history.length === 0 ? (
                    <div className="flex flex-col items-center justify-center h-full text-center">
                        <div className="w-14 h-14 rounded-2xl bg-amber-50 flex items-center justify-center mb-4">
                            <MessageSquare className="w-7 h-7 text-amber-500" strokeWidth={1.5} />
                        </div>
                        <h3 className="text-base font-semibold text-stone-800 mb-1.5" style={{ fontFamily: 'var(--font-heading)' }}>
                            Start a conversation
                        </h3>
                        <p className="text-sm text-stone-500 max-w-xs">Ask me anything about this document and I'll help you understand it.</p>
                    </div>
                ) : (
                    history.map(renderMessage)
                )}
                <div ref={messagesEndRef} />
                {loading && (
                    <div className="flex items-center gap-3 my-3">
                        <div className="w-8 h-8 rounded-xl bg-linear-to-br from-amber-400 to-amber-500 shadow-[0_4px_8px_rgba(245,158,11,0.25)] flex items-center justify-center shrink-0">
                            <Sparkles className="w-4 h-4 text-white" strokeWidth={2} />
                        </div>
                        <div className="flex items-center gap-2 px-4 py-3 rounded-[4px_18px_18px_18px] bg-white border border-stone-200">
                            <div className="flex gap-1">
                                <span className="w-2 h-2 bg-stone-400 rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
                                <span className="w-2 h-2 bg-stone-400 rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
                                <span className="w-2 h-2 bg-stone-400 rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
                            </div>
                        </div>
                    </div>
                )}
            </div>

            {/* Input Area */}
            <div className="p-4 border-t border-stone-200 bg-white">
                <form onSubmit={handleSendMessage} className="flex items-center gap-3">
                    <input
                        type="text"
                        value={message}
                        onChange={(e) => setMessage(e.target.value)}
                        placeholder="Ask a question about this document..."
                        className="flex-1 h-11 px-4 border-2 border-stone-200 rounded-xl bg-stone-50 text-stone-900 placeholder-stone-400 text-sm font-medium transition-all duration-200 focus:outline-none focus:border-indigo-500 focus:bg-white"
                        disabled={loading}
                    />
                    <button
                        type="submit"
                        disabled={loading || !message.trim()}
                        className="shrink-0 w-11 h-11 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl transition-all duration-200 shadow-sm shadow-indigo-500/20 disabled:opacity-50 disabled:cursor-not-allowed active:scale-95 flex items-center justify-center"
                    >
                        <Send className="w-4 h-4" strokeWidth={2} />
                    </button>
                </form>
            </div>
        </div>
    );
};

export default ChatInterface;
