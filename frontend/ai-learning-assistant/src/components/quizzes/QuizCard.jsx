import React from 'react'
import { Link } from 'react-router-dom'
import { Play, BarChart2, Award, Trash2 } from 'lucide-react'
import moment from 'moment'

const QuizCard = ({ quiz, onDelete }) => {
    return (
        <div className="group relative bg-white border border-stone-200 hover:border-indigo-200 rounded-2xl p-5 transition-all duration-[240ms] ease-out hover:shadow-[0_4px_12px_rgba(79,70,229,0.08),0_1px_3px_rgba(28,25,23,0.04)] hover:-translate-y-px flex flex-col justify-between">
            <button
                type="button"
                onClick={(e) => { e.stopPropagation(); onDelete(quiz); }}
                className='absolute top-4 right-4 w-8 h-8 flex items-center justify-center text-stone-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-all duration-200 opacity-0 group-hover:opacity-100'
            >
                <Trash2 className='w-4 h-4' strokeWidth={2} />
            </button>

            <div className='flex flex-col h-full'>
                {/* Status badge */}
                <div className='mb-4'>
                    <div className={`inline-flex items-center gap-2 px-3 py-1.5 rounded-lg border ${
                        quiz.completedAt
                            ? 'bg-emerald-50 border-emerald-200'
                            : 'bg-indigo-50 border-indigo-200'
                    }`}>
                        <Award className={`w-4 h-4 ${quiz.completedAt ? 'text-emerald-600' : 'text-indigo-500'}`} strokeWidth={2} />
                        <span className={`text-xs font-bold uppercase tracking-wider ${
                            quiz.completedAt ? 'text-emerald-800' : 'text-indigo-700'
                        }`}>
                            {quiz.completedAt ? `Score: ${quiz.score}%` : 'Not attempted'}
                        </span>
                    </div>
                </div>

                <div className='flex-grow mb-4'>
                    <h3
                        className='text-sm font-semibold text-stone-900 truncate mb-1'
                        title={quiz.title}
                        style={{ fontFamily: 'var(--font-heading)' }}
                    >
                        {quiz.title || `Quiz — ${moment(quiz.createdAt).format('MMM D, YYYY')}`}
                    </h3>
                    <p className='text-xs text-stone-400'>
                        Created {moment(quiz.createdAt).format('MMM D, YYYY')}
                    </p>
                </div>

                {/* Question count */}
                <div className='mb-5'>
                    <div className='inline-flex items-center gap-2 px-3 py-1.5 bg-stone-100 rounded-lg'>
                        <span className='text-xs font-semibold text-stone-600'>
                            {quiz.questions.length}{' '}
                            {quiz.questions.length === 1 ? 'Question' : 'Questions'}
                        </span>
                    </div>
                </div>

                {/* Action button */}
                <div className="mt-auto pt-4 border-t border-stone-100">
                    {quiz.completedAt ? (
                        <Link
                            to={`/quizzes/${quiz._id}/results`}
                            className="w-full h-10 flex items-center justify-center gap-2 text-sm font-semibold text-stone-600 bg-stone-100 hover:bg-stone-200 rounded-[10px] transition-all duration-[180ms] active:scale-[0.98]"
                        >
                            <BarChart2 className="w-4 h-4" strokeWidth={2} />
                            View results
                        </Link>
                    ) : (
                        <Link
                            to={`/quizzes/${quiz._id}`}
                            className="w-full h-10 flex items-center justify-center gap-2 text-sm font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-[10px] transition-all duration-[180ms] hover:-translate-y-px hover:shadow-[0_8px_24px_rgba(79,70,229,0.18)] active:scale-[0.98] active:translate-y-0"
                        >
                            <Play className="w-4 h-4" strokeWidth={2.5} />
                            Start quiz
                        </Link>
                    )}
                </div>
            </div>
        </div>
    )
}

export default QuizCard
