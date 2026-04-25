import React, { useState, useEffect } from 'react'
import { useParams, useNavigate } from 'react-router-dom'
import quizService from '../../services/quizService'
import Spinner from '../../components/common/Spinner'
import toast from 'react-hot-toast'
import { ChevronLeft, ChevronRight, Send } from 'lucide-react'

const QuizTakePage = () => {
  const { quizId } = useParams()
  const navigate = useNavigate()
  const [quiz, setQuiz] = useState(null)
  const [loading, setLoading] = useState(true)
  const [currentIndex, setCurrentIndex] = useState(0)
  // selectedAnswers maps questionIndex → selected option INDEX (number)
  const [selectedAnswers, setSelectedAnswers] = useState({})
  const [submitting, setSubmitting] = useState(false)

  useEffect(() => {
    const fetchQuiz = async () => {
      try {
        const data = await quizService.getQuizById(quizId)
        const quizData = data.data
        if (quizData.completedAt) {
          navigate(`/quizzes/${quizId}/results`, { replace: true })
          return
        }
        setQuiz(quizData)
      } catch (error) {
        toast.error('Failed to load quiz.')
        navigate(-1)
      } finally {
        setLoading(false)
      }
    }
    fetchQuiz()
  }, [quizId, navigate])

  const handleSelectAnswer = (optionIndex) => {
    setSelectedAnswers(prev => ({ ...prev, [currentIndex]: optionIndex }))
  }

  const handleSubmit = async () => {
    // Use `== null` so index 0 (falsy) is not treated as unanswered
    const firstUnanswered = quiz.questions.findIndex((_, i) => selectedAnswers[i] == null)
    if (firstUnanswered !== -1) {
      toast.error(`Please answer question ${firstUnanswered + 1} before submitting.`)
      setCurrentIndex(firstUnanswered)
      return
    }
    setSubmitting(true)
    try {
      const answers = quiz.questions.map((q, i) => ({
        questionIndex: i,
        selectedAnswer: q.options[selectedAnswers[i]],
      }))
      await quizService.submitQuiz(quizId, answers)
      toast.success('Quiz submitted!')
      navigate(`/quizzes/${quizId}/results`)
    } catch (error) {
      toast.error(error.message || 'Failed to submit quiz.')
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) return <Spinner />
  if (!quiz) return null

  const question = quiz.questions[currentIndex]

  if (!question) {
    return (
      <div className="text-center p-8 text-stone-500">
        This quiz has no questions. Please generate a new quiz.
      </div>
    )
  }

  const isLast = currentIndex === quiz.questions.length - 1
  const answeredCount = quiz.questions.filter((_, i) => selectedAnswers[i] != null).length
  const progress = quiz.questions.length > 0 ? (answeredCount / quiz.questions.length) * 100 : 0

  return (
    <div className="max-w-2xl mx-auto">
      <div className="mb-8">
        <h1
          className="text-3xl font-bold text-stone-900 mb-1 tracking-tight"
          style={{ fontFamily: 'var(--font-heading)', letterSpacing: '-0.02em' }}
        >
          {quiz.title || 'Quiz'}
        </h1>
        <p className="text-sm text-stone-500">{quiz.questions.length} questions</p>
      </div>

      {/* Progress bar */}
      <div className="mb-6">
        <div className="flex justify-between text-xs text-stone-500 mb-1.5">
          <span>{answeredCount} of {quiz.questions.length} answered</span>
          <span>Question {currentIndex + 1} / {quiz.questions.length}</span>
        </div>
        <div className="h-1.5 bg-stone-100 rounded-full overflow-hidden">
          <div
            className="h-full bg-linear-to-r from-indigo-500 to-indigo-600 rounded-full transition-all duration-300"
            style={{ width: `${progress}%` }}
          />
        </div>
      </div>

      {/* Question card */}
      <div className="bg-white border border-stone-200 rounded-2xl p-6 shadow-[0_1px_2px_rgba(28,25,23,0.04)] mb-6">
        <p className="text-lg font-semibold text-stone-900 mb-6 leading-relaxed">
          {question.question}
        </p>

        {(!question.options || question.options.length === 0) ? (
          <p className="text-sm text-stone-400 italic">No options available for this question.</p>
        ) : (
          <div className="space-y-3">
            {question.options.map((option, i) => {
              const isSelected = selectedAnswers[currentIndex] === i
              return (
                <button
                  key={i}
                  type="button"
                  onClick={() => handleSelectAnswer(i)}
                  className={`w-full text-left px-4 py-3 rounded-xl border-2 text-sm font-medium transition-all duration-[180ms] ${
                    isSelected
                      ? 'border-indigo-500 bg-indigo-50 text-indigo-900'
                      : 'border-stone-200 bg-white text-stone-700 hover:border-stone-300 hover:bg-stone-50'
                  }`}
                >
                  <span className="inline-flex items-center gap-3">
                    <span className={`w-6 h-6 rounded-full border-2 flex items-center justify-center shrink-0 text-xs font-bold transition-all duration-[180ms] ${
                      isSelected
                        ? 'border-indigo-500 bg-indigo-600 text-white'
                        : 'border-stone-300 text-stone-400'
                    }`}
                    style={{ fontFamily: 'var(--font-mono)' }}
                    >
                      {String.fromCharCode(65 + i)}
                    </span>
                    {option}
                  </span>
                </button>
              )
            })}
          </div>
        )}
      </div>

      {/* Navigation */}
      <div className="flex items-center justify-between">
        <button
          type="button"
          onClick={() => setCurrentIndex(idx => Math.max(0, idx - 1))}
          disabled={currentIndex === 0}
          className="flex items-center gap-2 px-4 h-10 text-sm font-medium text-stone-600 bg-white border border-stone-200 rounded-[10px] hover:bg-stone-50 transition-all duration-[180ms] disabled:opacity-40 disabled:cursor-not-allowed"
        >
          <ChevronLeft className="w-4 h-4" strokeWidth={2} />
          Previous
        </button>

        {isLast ? (
          <button
            type="button"
            onClick={handleSubmit}
            disabled={submitting}
            className="flex items-center gap-2 px-6 h-10 text-sm font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-[10px] hover:shadow-[0_8px_24px_rgba(79,70,229,0.18)] transition-all duration-[180ms] hover:-translate-y-px active:scale-[0.98] active:translate-y-0 disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:translate-y-0"
          >
            <Send className="w-4 h-4" strokeWidth={2} />
            {submitting ? 'Submitting...' : 'Submit quiz'}
          </button>
        ) : (
          <button
            type="button"
            onClick={() => setCurrentIndex(idx => Math.min(quiz.questions.length - 1, idx + 1))}
            className="flex items-center gap-2 px-4 h-10 text-sm font-medium text-stone-600 bg-white border border-stone-200 rounded-[10px] hover:bg-stone-50 transition-all duration-[180ms]"
          >
            Next
            <ChevronRight className="w-4 h-4" strokeWidth={2} />
          </button>
        )}
      </div>

      {/* Dot navigation */}
      <div className="flex flex-wrap gap-2 mt-6 justify-center">
        {quiz.questions.map((_, i) => (
          <button
            key={i}
            type="button"
            onClick={() => setCurrentIndex(i)}
            className={`w-8 h-8 rounded-lg text-xs font-semibold transition-all duration-[180ms] ${
              i === currentIndex
                ? 'bg-indigo-600 text-white shadow-sm'
                : selectedAnswers[i] != null
                ? 'bg-indigo-100 text-indigo-700 border border-indigo-200'
                : 'bg-stone-100 text-stone-500 hover:bg-stone-200'
            }`}
          >
            {i + 1}
          </button>
        ))}
      </div>
    </div>
  )
}

export default QuizTakePage
