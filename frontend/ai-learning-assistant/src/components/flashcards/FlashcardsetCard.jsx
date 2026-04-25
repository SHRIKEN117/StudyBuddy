import React from 'react'
import { Link } from 'react-router-dom'
import { BookOpen, ChevronRight } from 'lucide-react'
import moment from 'moment'

const FlashcardsetCard = ({ flashcardSet }) => {
  const documentId = flashcardSet.documentId?._id || flashcardSet.documentId
  const documentTitle = flashcardSet.documentId?.title || 'Flashcard Set'

  return (
    <Link
      to={`/documents/${documentId}/flashcards`}
      className="group flex items-center justify-between p-5 bg-white border border-stone-200 rounded-2xl hover:border-indigo-200 hover:shadow-[0_4px_12px_rgba(79,70,229,0.07)] hover:-translate-y-px transition-all duration-[240ms] ease-out"
    >
      <div className="flex items-center gap-4">
        <div className="w-11 h-11 rounded-xl bg-indigo-50 flex items-center justify-center flex-shrink-0 group-hover:shadow-[0_4px_10px_rgba(79,70,229,0.2)] transition-shadow duration-300">
          <BookOpen className="w-5 h-5 text-indigo-600" strokeWidth={1.5} />
        </div>
        <div>
          <h3 className="text-sm font-semibold text-stone-900 mb-0.5">{documentTitle}</h3>
          <div className="flex items-center gap-2 text-xs text-stone-400">
            <span>{flashcardSet.cards?.length || 0} cards</span>
            <span>&middot;</span>
            <span>Created {moment(flashcardSet.createdAt).format('MMM D, YYYY')}</span>
          </div>
        </div>
      </div>
      <ChevronRight className="w-4 h-4 text-stone-300 group-hover:text-indigo-500 group-hover:translate-x-0.5 transition-all duration-200 flex-shrink-0" strokeWidth={2} />
    </Link>
  )
}

export default FlashcardsetCard
