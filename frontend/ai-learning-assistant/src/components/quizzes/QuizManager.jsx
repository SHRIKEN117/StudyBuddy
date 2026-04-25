import React, { useState, useEffect } from 'react';
import { Plus } from 'lucide-react';
import toast from 'react-hot-toast';
import quizService from '../../services/quizService';
import aiService from '../../services/aiService';
import Spinner from '../common/Spinner';
import Button from '../common/Button';
import Modal from '../common/Modal';
import QuizCard from './QuizCard';
import EmptyState from '../common/EmptyState';

const QuizManager = ({ documentId }) => {
    const [quizzes, setQuizzes] = useState([]);
    const [loading, setLoading] = useState(true);
    const [generating, setGenerating] = useState(false);
    const [isGenerateModalOpen, setIsGenerateModalOpen] = useState(false);
    const [numQuestions, setNumQuestions] = useState(5);

    const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
    const [deleting, setDeleting] = useState(false);
    const [selectedQuiz, setSelectedQuiz] = useState(null);

    useEffect(() => {
        const fetchQuizzes = async () => {
            setLoading(true);
            try {
                const data = await quizService.getQuizzesForDocument(documentId);
                setQuizzes(data.data);
            } catch (error) {
                toast.error('Failed to fetch quizzes.');
                console.error(error);
            } finally {
                setLoading(false);
            }
        };

        if (documentId) {
            fetchQuizzes();
        }
    }, [documentId]);

    const handleGenerateQuiz = async (e) => {
        e.preventDefault();
        setGenerating(true);
        try {
            const response = await aiService.generateQuiz(documentId, { numQuestions });
            setQuizzes(prev => [...prev, response.data]);
            toast.success('Quiz generated successfully.');
            setIsGenerateModalOpen(false);
        } catch (error) {
            toast.error(error.message || 'Failed to generate quiz.');
            console.error(error);
        } finally {
            setGenerating(false);
        }
    };

    const handleDeleteRequest = (quiz) => {
        setSelectedQuiz(quiz);
        setIsDeleteModalOpen(true);
    };

    const handleConfirmDelete = async () => {
        if (!selectedQuiz) return;
        setDeleting(true);
        try {
            await quizService.deleteQuiz(selectedQuiz._id);
            setQuizzes(prev => prev.filter(q => q._id !== selectedQuiz._id));
            toast.success('Quiz deleted successfully.');
            setIsDeleteModalOpen(false);
            setSelectedQuiz(null);
        } catch (error) {
            toast.error(error.message || 'Failed to delete quiz.');
            console.error(error);
        } finally {
            setDeleting(false);
        }
    };

    const renderQuizContent = () => {
        if (loading) return <Spinner />;

        if (quizzes.length === 0) {
            return (
                <EmptyState
                    title="No Quizzes yet"
                    description="Generate a quiz to get started."
                    buttonText="Generate Quiz"
                    onActionClick={() => setIsGenerateModalOpen(true)}
                />
            );
        }

        return (
            <div className='grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4'>
                {quizzes.map((quiz) => (
                    <QuizCard
                        key={quiz._id}
                        quiz={quiz}
                        onDelete={handleDeleteRequest}
                    />
                ))}
            </div>
        );
    };

    return (
        <div>
            <div className='flex justify-end gap-2 mb-4'>
                <Button onClick={() => setIsGenerateModalOpen(true)} variant="ai">
                    <Plus size={16} />
                    Generate quiz
                </Button>
            </div>
            {renderQuizContent()}

            {/* Generate Quiz Modal */}
            <Modal
                isOpen={isGenerateModalOpen}
                onClose={() => setIsGenerateModalOpen(false)}
                title="Generate New Quiz"
            >
                <form onSubmit={handleGenerateQuiz} className='space-y-6'>
                    <div className='space-y-2'>
                        <label className='block text-xs font-semibold text-stone-600 uppercase tracking-wider'>Number of Questions</label>
                        <input
                            type='number'
                            value={numQuestions}
                            onChange={(e) => setNumQuestions(Math.max(1, parseInt(e.target.value) || 1))}
                            min={1}
                            required
                            className='w-full h-11 px-4 border-2 border-stone-200 rounded-xl bg-stone-50 text-stone-900 text-sm font-medium transition-all duration-200 focus:outline-none focus:border-indigo-500 focus:bg-white'
                        />
                    </div>
                    <div className='flex justify-end gap-3 pt-4'>
                        <Button
                            type='button'
                            variant='secondary'
                            onClick={() => setIsGenerateModalOpen(false)}
                            disabled={generating}
                        >
                            Cancel
                        </Button>
                        <Button type='submit' variant='ai' disabled={generating}>
                            {generating ? 'Generating...' : 'Generate'}
                        </Button>
                    </div>
                </form>
            </Modal>

            {/* Delete Quiz Modal */}
            <Modal
                isOpen={isDeleteModalOpen}
                onClose={() => setIsDeleteModalOpen(false)}
                title="Delete Quiz"
            >
                <p className='text-sm text-stone-600 mb-6'>Are you sure you want to delete this quiz? This action cannot be undone.</p>
                <div className='flex justify-end gap-3'>
                    <Button
                        type='button'
                        variant='secondary'
                        onClick={() => setIsDeleteModalOpen(false)}
                        disabled={deleting}
                    >
                        Cancel
                    </Button>
                    <Button
                        type='button'
                        variant='danger'
                        onClick={handleConfirmDelete}
                        disabled={deleting}
                    >
                        {deleting ? 'Deleting...' : 'Delete'}
                    </Button>
                </div>
            </Modal>
        </div>
    );
};

export default QuizManager;
