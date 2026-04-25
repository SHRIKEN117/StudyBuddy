import React, { useState, useEffect } from "react";
import {
    Plus,
    ChevronLeft,
    ChevronRight,
    Trash2,
    ArrowLeft,
    Sparkles,
    Brain,
    Star,
} from "lucide-react";
import toast from "react-hot-toast";
import moment from "moment";
import flashcardService from "../../services/flashcardService";
import aiService from "../../services/aiService";
import Spinner from "../common/Spinner";
import Modal from "../common/Modal";
import Flashcard from "./Flashcard";


const FlashcardManager = ({ documentId }) => {
    const [flashcardSets, setFlashcardSets] = useState([]);
    const [selectedSet, setSelectedSet] = useState(null);
    const [loading, setLoading] = useState(true);
    const [generating, setGenerating] = useState(false);
    const [currentCardIndex, setCurrentCardIndex] = useState(0);
    const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
    const [deleting, setDeleting] = useState(false);
    const [setToDelete, setSetToDelete] = useState(null);
    const [starredOnly, setStarredOnly] = useState(false);

    const fetchFlashcardSets = async () => {
        setLoading(true);
        try {
            const response = await flashcardService.getFlashcardsForDocument(documentId);
            setFlashcardSets(response.data);
        } catch (error) {
            toast.error("Failed to fetch flashcard sets.");
            console.error(error);
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        if (documentId) {
            fetchFlashcardSets();
        }
    }, [documentId]);

    const handleGenerateFlashcards = async () => {
        setGenerating(true);
        try {
            await aiService.generateFlashcards(documentId);
            toast.success("Flashcards generated successfully.");
            fetchFlashcardSets();
        } catch (error) {
            toast.error(error.message || "Failed to generate flashcards.");
            console.error(error);
        } finally {
            setGenerating(false);
        }
    };

    // Derive the filtered card list based on the starred toggle
    const visibleCards = selectedSet
        ? starredOnly
            ? selectedSet.cards.filter(c => c.isStarred)
            : selectedSet.cards
        : [];

    const handleNextCard = () => {
        if (visibleCards.length > 0) {
            handleReview(currentCardIndex);
            setCurrentCardIndex(prev => (prev + 1) % visibleCards.length);
        }
    };

    const handlePrevCard = () => {
        if (visibleCards.length > 0) {
            handleReview(currentCardIndex);
            setCurrentCardIndex(prev => (prev - 1 + visibleCards.length) % visibleCards.length);
        }
    };

    const handleReview = async (index) => {
        const currentCard = visibleCards[index];
        if (!currentCard) return;
        try {
            await flashcardService.reviewFlashcard(currentCard._id, index);
        } catch {
            // silently ignore review tracking errors
        }
    };

    const handleToggleStar = async (cardId) => {
        try {
            await flashcardService.toggleStar(cardId);
            const updatedSets = flashcardSets.map((set) => {
                if (set._id === selectedSet._id) {
                    const updatedCards = set.cards.map((card) =>
                        card._id === cardId
                            ? { ...card, isStarred: !card.isStarred }
                            : card
                    );
                    return { ...set, cards: updatedCards };
                }
                return set;
            });
            setFlashcardSets(updatedSets);
            const updatedSet = updatedSets.find(s => s._id === selectedSet._id);
            setSelectedSet(updatedSet);

            // If in starred-only mode and the current card was just unstarred,
            // clamp the index so we don't land on an undefined card
            if (starredOnly) {
                const newVisible = updatedSet.cards.filter(c => c.isStarred);
                if (currentCardIndex >= newVisible.length) {
                    setCurrentCardIndex(Math.max(0, newVisible.length - 1));
                }
            }
        } catch {
            toast.error("Failed to update starred status.");
        }
    };

    const handleDeleteRequest = (e, set) => {
        e.stopPropagation();
        setSetToDelete(set);
        setIsDeleteModalOpen(true);
    };

    const handleConfirmDelete = async () => {
        if (!setToDelete) return;
        setIsDeleteModalOpen(false);
        setDeleting(true);
        try {
            await flashcardService.deleteFlashcardSet(setToDelete._id);
            toast.success("Flashcard set deleted successfully.");
            fetchFlashcardSets();
        } catch (error) {
            toast.error("Failed to delete flashcard set.");
            console.error(error);
        } finally {
            setDeleting(false);
        }
    };

    const handleSelectedSet = (set) => {
        setSelectedSet(set);
        setCurrentCardIndex(0);
        setStarredOnly(false);
    };

    const handleToggleStarFilter = () => {
        setStarredOnly(prev => !prev);
        setCurrentCardIndex(0);
    };

    const renderFlashcardViewer = () => {
        const currentCard = visibleCards[currentCardIndex];
        const starredCount = selectedSet?.cards.filter(c => c.isStarred).length ?? 0;

        return (
            <div className="space-y-6">
                {/* Top bar */}
                <div className="flex items-center justify-between">
                    <button
                        onClick={() => setSelectedSet(null)}
                        className="group inline-flex items-center gap-2 text-sm font-medium text-stone-500 hover:text-indigo-700 transition-colors duration-200"
                    >
                        <ArrowLeft className="w-4 h-4 group-hover:-translate-x-1 transition-transform duration-200" strokeWidth={2} />
                        Back to Sets
                    </button>

                    {/* Starred-only toggle */}
                    <button
                        onClick={handleToggleStarFilter}
                        disabled={starredCount === 0}
                        className={`inline-flex items-center gap-1.5 px-3 h-8 text-xs font-semibold rounded-lg border transition-all duration-200 disabled:opacity-40 disabled:cursor-not-allowed ${
                            starredOnly
                                ? 'bg-amber-50 border-amber-300 text-amber-700'
                                : 'bg-white border-stone-200 text-stone-500 hover:border-amber-300 hover:text-amber-600'
                        }`}
                    >
                        <Star className={`w-3.5 h-3.5 ${starredOnly ? 'fill-amber-500 text-amber-500' : ''}`} strokeWidth={2} />
                        {starredOnly ? `Starred (${starredCount})` : `Show starred (${starredCount})`}
                    </button>
                </div>

                {/* Empty state for starred filter */}
                {visibleCards.length === 0 ? (
                    <div className="flex flex-col items-center justify-center py-16 text-center">
                        <Star className="w-10 h-10 text-stone-300 mb-3" strokeWidth={1.5} />
                        <p className="text-sm font-medium text-stone-500">No starred cards yet.</p>
                        <p className="text-xs text-stone-400 mt-1">Star cards while reviewing to see them here.</p>
                    </div>
                ) : (
                    <div className="flex items-center flex-col space-y-8">
                        <div className="w-full max-w-2xl">
                            <Flashcard
                                flashcard={currentCard}
                                onToggleStar={handleToggleStar}
                            />
                        </div>

                        {/* Navigation Controls */}
                        <div className="flex items-center gap-6">
                            <button
                                onClick={handlePrevCard}
                                disabled={visibleCards.length <= 1}
                                className="group flex items-center gap-2 px-5 h-11 bg-stone-50 hover:bg-stone-100 text-stone-600 font-medium text-sm rounded-xl border border-stone-200 transition-all duration-200 disabled:opacity-40 disabled:cursor-not-allowed"
                            >
                                <ChevronLeft className="w-4 h-4 group-hover:-translate-x-0.5 transition-transform duration-200" strokeWidth={2.5} />
                                Previous
                            </button>

                            <div className="px-4 py-2 bg-stone-50 rounded-lg border border-stone-200">
                                <span className="text-sm font-medium text-stone-600">
                                    {currentCardIndex + 1}{" "}
                                    <span className="text-stone-400 font-normal">/</span>{" "}
                                    {visibleCards.length}
                                </span>
                            </div>

                            <button
                                onClick={handleNextCard}
                                disabled={visibleCards.length <= 1}
                                className="group flex items-center gap-2 px-5 h-11 bg-stone-50 hover:bg-stone-100 text-stone-600 font-medium text-sm rounded-xl border border-stone-200 transition-all duration-200 disabled:opacity-40 disabled:cursor-not-allowed"
                            >
                                Next
                                <ChevronRight className="w-4 h-4 group-hover:translate-x-0.5 transition-transform duration-200" strokeWidth={2.5} />
                            </button>
                        </div>
                    </div>
                )}
            </div>
        );
    };

    const renderSetList = () => {
        if (loading) {
            return (
                <div className="flex items-center justify-center py-20">
                    <Spinner />
                </div>
            );
        }

        if (flashcardSets.length === 0) {
            return (
                <div className="flex flex-col items-center justify-center py-16 px-6">
                    <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-indigo-50 mb-5">
                        <Brain className="w-8 h-8 text-indigo-500" strokeWidth={1.5} />
                    </div>
                    <h3 className="text-xl font-semibold text-stone-800 mb-2" style={{ fontFamily: 'var(--font-heading)' }}>No Flashcards Yet</h3>
                    <p className="text-sm text-stone-500 mb-8 text-center max-w-sm">
                        Generate flashcards to start learning.
                    </p>
                    <button
                        onClick={handleGenerateFlashcards}
                        disabled={generating}
                        className="group inline-flex items-center gap-2 px-6 h-12 bg-linear-to-r from-amber-400 to-amber-500 hover:from-amber-500 hover:to-amber-600 text-white font-semibold text-sm rounded-[10px] transition-all duration-[180ms] ease-out hover:-translate-y-px hover:shadow-[0_8px_24px_rgba(245,158,11,0.25)] active:scale-[0.98] active:translate-y-0 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:translate-y-0"
                    >
                        {generating ? (
                            <>
                                <div className="w-4 h-4 rounded-full border-2 border-white/30 border-t-white animate-spin" />
                                Generating...
                            </>
                        ) : (
                            <>
                                <Sparkles className="w-4 h-4" strokeWidth={2} />
                                Generate Flashcards
                            </>
                        )}
                    </button>
                </div>
            );
        }

        return (
            <div className="space-y-6">
                {/* Header with Generate Button */}
                <div className="flex items-center justify-between">
                    <div>
                        <h3 className="text-xl font-semibold text-stone-900" style={{ fontFamily: 'var(--font-heading)' }}>Your Flashcard Sets</h3>
                        <p className="text-sm text-stone-500 mt-1">
                            {flashcardSets.length}{" "}
                            {flashcardSets.length === 1 ? "Set" : "Sets"} available
                        </p>
                    </div>
                    <button
                        onClick={handleGenerateFlashcards}
                        disabled={generating}
                        className="group inline-flex items-center gap-2 px-6 h-12 bg-linear-to-r from-amber-400 to-amber-500 hover:from-amber-500 hover:to-amber-600 text-white font-semibold text-sm rounded-[10px] transition-all duration-[180ms] ease-out hover:-translate-y-px hover:shadow-[0_8px_24px_rgba(245,158,11,0.25)] active:scale-[0.98] active:translate-y-0 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:translate-y-0"
                    >
                        {generating ? (
                            <>
                                <div className="w-4 h-4 rounded-full border-2 border-white/30 border-t-white animate-spin" />
                                Generating...
                            </>
                        ) : (
                            <>
                                <Plus className="w-4 h-4" strokeWidth={2.5} />
                                Generate New Set
                            </>
                        )}
                    </button>
                </div>

                {/* Flashcard Sets List */}
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                    {flashcardSets.map((set) => (
                        <div
                            key={set._id}
                            className="group relative bg-white border border-stone-200 rounded-2xl p-5 cursor-pointer transition-all duration-200 hover:border-indigo-200 hover:shadow-[0_4px_12px_rgba(28,25,23,0.06)] hover:-translate-y-px"
                            onClick={() => handleSelectedSet(set)}
                        >
                            <button
                                onClick={(e) => handleDeleteRequest(e, set)}
                                className="absolute top-4 right-4 p-1.5 text-stone-400 hover:text-rose-500 hover:bg-rose-50 rounded-lg opacity-0 group-hover:opacity-100 transition-all duration-200"
                            >
                                <Trash2 className="w-4 h-4" strokeWidth={2} />
                            </button>

                            <div className="space-y-3">
                                <div className="inline-flex items-center justify-center w-10 h-10 rounded-xl bg-indigo-50">
                                    <Brain className="w-5 h-5 text-indigo-600" strokeWidth={1.5} />
                                </div>
                                <div>
                                    <h4 className="text-sm font-semibold text-stone-900 mb-0.5">Flashcard Set</h4>
                                    <p className="text-xs text-stone-400">
                                        Created {moment(set.createdAt).format("MMM D, YYYY")}
                                    </p>
                                </div>

                                <div className="flex items-center gap-2 pt-2 border-t border-stone-100">
                                    <div className="px-2.5 py-1 bg-indigo-50 rounded-md">
                                        <span className="text-xs font-semibold text-indigo-700">
                                            {set.cards.length}{" "}
                                            {set.cards.length === 1 ? "Card" : "Cards"}
                                        </span>
                                    </div>
                                    {set.cards.filter(c => c.isStarred).length > 0 && (
                                        <div className="px-2.5 py-1 bg-amber-50 rounded-md flex items-center gap-1">
                                            <Star className="w-3 h-3 fill-amber-500 text-amber-500" strokeWidth={2} />
                                            <span className="text-xs font-semibold text-amber-700">
                                                {set.cards.filter(c => c.isStarred).length}
                                            </span>
                                        </div>
                                    )}
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            </div>
        );
    };

    return (
        <>
            <div>
                {selectedSet ? renderFlashcardViewer() : renderSetList()}
            </div>

            <Modal
                isOpen={isDeleteModalOpen}
                onClose={() => setIsDeleteModalOpen(false)}
                title="Delete Flashcard Set"
            >
                <div className="space-y-6">
                    <p className="text-sm text-stone-600">
                        Are you sure you want to delete this flashcard set? This action cannot be undone.
                    </p>
                    <div className="flex items-center gap-3 pt-2 justify-end">
                        <button
                            type="button"
                            onClick={() => setIsDeleteModalOpen(false)}
                            disabled={deleting}
                            className="px-5 h-11 bg-white border-2 border-stone-200 rounded-xl text-stone-700 font-semibold text-sm transition-all duration-200 hover:bg-stone-50 disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            Cancel
                        </button>
                        <button
                            type="button"
                            onClick={handleConfirmDelete}
                            disabled={deleting}
                            className="px-5 h-11 bg-rose-600 hover:bg-rose-700 text-white font-semibold text-sm rounded-xl transition-all duration-200 shadow-sm shadow-rose-500/20 disabled:opacity-50 disabled:cursor-not-allowed"
                        >
                            {deleting ? (
                                <span className="inline-flex items-center gap-2">
                                    <div className="w-4 h-4 rounded-full border-2 border-white/30 border-t-white animate-spin" />
                                    Deleting...
                                </span>
                            ) : (
                                "Delete Set"
                            )}
                        </button>
                    </div>
                </div>
            </Modal>
        </>
    );
};

export default FlashcardManager;
