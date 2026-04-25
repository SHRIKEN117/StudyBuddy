import React, { useState, useEffect } from 'react'
import flashcardService from '../../services/flashcardService'
import PageHeader from '../../components/common/PageHeader'
import Spinner from '../../components/common/Spinner'
import EmptyState from '../../components/common/EmptyState'
import FlashcardsetCard from '../../components/flashcards/FlashcardsetCard'
import toast from 'react-hot-toast'

const FlashcardsListPage = () => {
  const [flashcardSets, setFlashcardSets] = useState([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchFlashcardSets = async () => {
      try {
        const response = await flashcardService.getAllFlashcardSets()
        setFlashcardSets(response.data)
      } catch (error) {
        toast.error(error.message || 'Failed to fetch flashcard sets')
        console.error('Error fetching flashcard sets:', error)
      } finally {
        setLoading(false)
      }
    }
    fetchFlashcardSets()
  }, [])

  const renderContent = () => {
    if (loading) return <Spinner />

    if (flashcardSets.length === 0) {
      return (
        <EmptyState
          title="No flashcard sets found"
          description="Go to a document and generate flashcards to get started."
        />
      )
    }

    return (
      <div className="space-y-3">
        {flashcardSets.map((set) => (
          <FlashcardsetCard key={set._id} flashcardSet={set} />
        ))}
      </div>
    )
  }

  return (
    <div>
      <PageHeader title="Flashcard Sets" />
      {renderContent()}
    </div>
  )
}

export default FlashcardsListPage
