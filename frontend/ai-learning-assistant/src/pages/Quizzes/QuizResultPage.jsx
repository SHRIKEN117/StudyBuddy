import React, { useState, useEffect } from 'react'
import { useParams, Link, useNavigate } from 'react-router-dom'
import quizService from '../../services/quizService'
import Spinner from '../../components/common/Spinner'
import toast from 'react-hot-toast'
import { CheckCircle, XCircle, Trophy, ArrowLeft, RotateCcw } from 'lucide-react'
import moment from 'moment'

const QuizResultPage = () => {
  const { quizId } = useParams()
  const navigate = useNavigate()
  const [resultData, setResultData] = useState(null)
  const [loading, setLoading] = useState(true)
  const [retaking, setRetaking] = useState(false)

  useEffect(() => {
    const fetchResults = async () => {
      try {
        const data = await quizService.getQuizResults(quizId)
        setResultData(data.data)
      } catch (error) {
        toast.error('Failed to load quiz results.')
      } finally {
        setLoading(false)
      }
    }
    fetchResults()
  }, [quizId])

  const handleRetake = async () => {
    setRetaking(true)
    try {
      await quizService.retakeQuiz(quizId)
      toast.success('Quiz reset — good luck!')
      navigate(`/quizzes/${quizId}`)
    } catch (error) {
      toast.error(error.message || 'Failed to reset quiz.')
      setRetaking(false)
    }
  }

  if (loading) return <Spinner />
  if (!resultData) return <div className="text-center p-8 text-stone-500">Results not found.</div>

  const { quiz, results } = resultData
  const passed = quiz.score >= 70
  const correctCount = results.filter(r => r.isCorrect).length

  return (
    <div className="max-w-2xl mx-auto">
      {quiz.document && (
        <Link
          to={`/documents/${quiz.document._id}`}
          className="inline-flex items-center gap-1.5 text-sm font-medium text-stone-500 hover:text-stone-900 mb-6 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" strokeWidth={1.5} />
          Back to document
        </Link>
      )}

      {/* Score summary */}
      <div className={`rounded-2xl p-8 mb-6 text-center border ${
        passed
          ? 'bg-linear-to-br from-emerald-50 to-teal-50 border-emerald-200'
          : 'bg-linear-to-br from-rose-50 to-red-50 border-rose-200'
      }`}>
        <div className={`inline-flex items-center justify-center w-16 h-16 rounded-2xl mb-4 ${
          passed ? 'bg-emerald-100' : 'bg-rose-100'
        }`}>
          <Trophy className={`w-8 h-8 ${passed ? 'text-emerald-600' : 'text-rose-500'}`} strokeWidth={1.5} />
        </div>
        <h1
          className="text-5xl font-extrabold text-stone-900 mb-1 tracking-tight"
          style={{ fontFamily: 'var(--font-heading)' }}
        >
          {quiz.score}%
        </h1>
        <p className={`text-base font-semibold mb-2 ${passed ? 'text-emerald-700' : 'text-rose-600'}`}>
          {passed ? 'Great job! You passed.' : 'Keep practicing!'}
        </p>
        <p className="text-sm text-stone-500 mb-6">
          {correctCount} of {quiz.totalQuestions} correct &middot; Completed {moment(quiz.completedAt).format('MMM D, YYYY')}
        </p>

        {/* Retake button */}
        <button
          onClick={handleRetake}
          disabled={retaking}
          className="inline-flex items-center gap-2 px-5 h-10 bg-white border border-stone-200 text-stone-700 text-sm font-semibold rounded-xl hover:bg-stone-50 transition-all duration-200 shadow-sm disabled:opacity-50 disabled:cursor-not-allowed active:scale-[0.98]"
        >
          <RotateCcw className={`w-4 h-4 ${retaking ? 'animate-spin' : ''}`} strokeWidth={2} />
          {retaking ? 'Resetting...' : 'Retake Quiz'}
        </button>
      </div>

      {/* Question breakdown */}
      <h2
        className="text-xl font-semibold text-stone-900 mb-4"
        style={{ fontFamily: 'var(--font-heading)' }}
      >
        Question breakdown
      </h2>
      <div className="space-y-4">
        {results.map((result, index) => (
          <div
            key={index}
            className={`bg-white border rounded-2xl p-5 shadow-[0_1px_2px_rgba(28,25,23,0.04)] ${
              result.isCorrect ? 'border-emerald-200' : 'border-rose-200'
            }`}
          >
            <div className="flex items-start gap-3 mb-4">
              {result.isCorrect ? (
                <CheckCircle className="w-5 h-5 text-emerald-500 shrink-0 mt-0.5" strokeWidth={1.5} />
              ) : (
                <XCircle className="w-5 h-5 text-rose-500 shrink-0 mt-0.5" strokeWidth={1.5} />
              )}
              <p className="text-base font-semibold text-stone-800 leading-relaxed">
                Q{index + 1}. {result.question}
              </p>
            </div>

            <div className="space-y-2 ml-8">
              {result.options.map((option, i) => {
                const isCorrectAnswer = option === result.correctAnswer
                const isWrongSelection = option === result.selectedAnswer && !isCorrectAnswer
                return (
                  <div
                    key={i}
                    className={`px-3 py-2 rounded-lg text-sm flex items-center gap-2 ${
                      isCorrectAnswer
                        ? 'bg-emerald-50 border border-emerald-200 text-emerald-800 font-medium'
                        : isWrongSelection
                        ? 'bg-rose-50 border border-rose-200 text-rose-800'
                        : 'bg-stone-50 text-stone-600'
                    }`}
                  >
                    <span className="flex-1">{option}</span>
                    {isCorrectAnswer && <CheckCircle className="w-4 h-4 text-emerald-500 shrink-0" strokeWidth={1.5} />}
                    {isWrongSelection && <XCircle className="w-4 h-4 text-rose-500 shrink-0" strokeWidth={1.5} />}
                  </div>
                )
              })}
            </div>

            {result.explanation && (
              <div className="mt-3 ml-8 p-3 bg-indigo-50 border border-indigo-100 rounded-lg">
                <p className="text-xs text-indigo-700 leading-relaxed">
                  <span className="font-semibold">Explanation: </span>
                  {result.explanation}
                </p>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}

export default QuizResultPage
