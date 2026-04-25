import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import documentService from '../../services/documentService';
import Spinner from '../../components/common/Spinner';
import toast from 'react-hot-toast';
import { ArrowLeft, ExternalLink } from 'lucide-react';
import PageHeader from '../../components/common/PageHeader';
import Tabs from '../../components/common/Tabs';
import ChatInterface from '../../components/chat/ChatInterface';
import FlashcardManager from '../../components/flashcards/FlashcardManager';
import QuizManager from '../../components/quizzes/QuizManager';
import SummaryTab from '../../components/documents/SummaryTab';

const DocumentDetailPage = () => {
  const { id } = useParams();
  const [document, setDocument] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('Content');

  useEffect(() => {
    const fetchDocumentDetails = async () => {
      try {
        const data = await documentService.getDocumentById(id);
        setDocument(data);
      } catch (error) {
        toast.error("Failed to fetch document.");
        console.error(error);
      } finally {
        setLoading(false);
      }
    };
    fetchDocumentDetails();
  }, [id]);

  const getPdfUrl = () => {
    if (!document?.data) return null;
    if (document.data.fileUrl) return document.data.fileUrl;
    const filePath = document.data.filePath;
    if (filePath && (filePath.startsWith('http://') || filePath.startsWith('https://'))) {
      return filePath;
    }
    return null;
  };

  const renderContent = () => {
    if (loading) return <Spinner />;
    if (!document || !document.data) {
      return <div className='text-center py-8 text-stone-500'>Document not found.</div>;
    }
    const pdfUrl = getPdfUrl();
    if (!pdfUrl) {
      return <div className='text-center py-8 text-stone-500'>Document content is not available.</div>;
    }
    return (
      <div className='bg-white border border-stone-200 rounded-2xl overflow-hidden shadow-sm'>
        <div className='flex items-center justify-between px-5 py-3 border-b border-stone-200'>
          <span className='text-sm font-medium text-stone-600'>Document Viewer</span>
          <a
            href={pdfUrl}
            target="_blank"
            rel="noopener noreferrer"
            className='inline-flex items-center gap-1.5 text-sm font-semibold text-indigo-600 hover:text-indigo-700 transition-colors'
          >
            <ExternalLink size={15} strokeWidth={2} />
            Open in new tab
          </a>
        </div>
        <div className='bg-stone-50 p-2'>
          <iframe
            src={pdfUrl}
            allow='fullscreen'
            frameBorder="0"
            className='w-full h-[70vh] bg-white rounded-xl border border-stone-200'
            title='PDF Viewer'
            style={{ colorScheme: 'light' }}
          />
        </div>
      </div>
    );
  };

  const tabs = [
    { name: 'Content', label: 'Content', content: renderContent() },
    { name: 'Summary', label: 'Summary', content: <SummaryTab documentId={id} /> },
    { name: 'Chat', label: 'Chat', content: <ChatInterface /> },
    { name: 'Flashcards', label: 'Flashcards', content: <FlashcardManager documentId={id} /> },
    { name: 'Quizzes', label: 'Quizzes', content: <QuizManager documentId={id} /> },
  ];

  if (loading) return <Spinner />;

  if (!document) {
    return <div className='text-center py-8 text-stone-500'>Document not found.</div>;
  }

  return (
    <div>
      <div className='mb-4'>
        <Link
          to="/documents"
          className="inline-flex items-center gap-1.5 text-sm font-medium text-stone-500 hover:text-stone-900 transition-colors"
        >
          <ArrowLeft size={15} strokeWidth={2} />
          Back to Documents
        </Link>
      </div>
      <PageHeader title={document.data.title} />
      <Tabs tabs={tabs} activeTab={activeTab} setActiveTab={setActiveTab} />
    </div>
  );
};

export default DocumentDetailPage;
