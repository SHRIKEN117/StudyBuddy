import React from 'react'
import { useParams, Link } from 'react-router-dom'
import { ArrowLeft } from 'lucide-react'
import FlashcardManager from '../../components/flashcards/FlashcardManager'
import PageHeader from '../../components/common/PageHeader'

const FlashcardPage = () => {
  const { id } = useParams()

  return (
    <div>
      <div className='mb-4'>
        <Link
          to={`/documents/${id}`}
          className="inline-flex items-center gap-1.5 text-sm font-medium text-stone-500 hover:text-stone-900 transition-colors"
        >
          <ArrowLeft size={16} />
          Back to Document
        </Link>
      </div>
      <PageHeader title="Flashcards" />
      <FlashcardManager documentId={id} />
    </div>
  )
}

export default FlashcardPage
