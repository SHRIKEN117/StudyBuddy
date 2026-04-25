import React, { useState, useEffect } from 'react';
import { Plus, Upload, Trash2, FileText, X, Search } from "lucide-react";
import toast from "react-hot-toast";
import documentService from "../../services/documentService";
import Spinner from "../../components/common/Spinner";
import Button from "../../components/common/Button";
import DocumentCard from "../../components/documents/DocumentCard";

const DocumentListPage = () => {
  const [documents, setDocuments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');

  const [isUploadModalOpen, setIsUploadModalOpen] = useState(false);
  const [uploadFile, setUploadFile] = useState(null);
  const [uploadTitle, setUploadTitle] = useState("");
  const [uploading, setUploading] = useState(false);

  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [selectedDoc, setSelectedDoc] = useState(null);

  const fetchDocuments = async () => {
    try {
      const responseData = await documentService.getDocuments();
      if (responseData && Array.isArray(responseData.data)) {
        setDocuments(responseData.data);
      } else if (Array.isArray(responseData)) {
        setDocuments(responseData);
      } else {
        setDocuments([]);
      }
    } catch (error) {
      toast.error("Failed to fetch documents.");
      console.error(error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchDocuments();
  }, []);

  const handleFileChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setUploadFile(file);
      setUploadTitle(file.name.replace(/\.[^/.]+$/, ""));
    }
  };

  const handleUpload = async (e) => {
    e.preventDefault();
    if (!uploadFile || !uploadTitle) {
      toast.error("Please provide a title and select a file.");
      return;
    }
    setUploading(true);
    const formData = new FormData();
    formData.append("file", uploadFile);
    formData.append("title", uploadTitle);
    try {
      await documentService.uploadDocument(formData);
      toast.success("Document uploaded successfully!");
      setIsUploadModalOpen(false);
      setUploadFile(null);
      setUploadTitle('');
      setLoading(true);
      fetchDocuments();
    } catch (error) {
      toast.error(error.message || "Upload failed.");
    } finally {
      setUploading(false);
    }
  };

  const handleDeleteRequest = (doc) => {
    setSelectedDoc(doc);
    setIsDeleteModalOpen(true);
  };

  const handleConfirmDelete = async () => {
    if (!selectedDoc) return;
    setDeleting(true);
    try {
      await documentService.deleteDocument(selectedDoc._id);
      toast.success(`'${selectedDoc.title}' deleted.`);
      setIsDeleteModalOpen(false);
      setSelectedDoc(null);
      setDocuments(documents.filter((d) => d._id !== selectedDoc._id));
    } catch (error) {
      toast.error(error.message || "Failed to delete document.");
    } finally {
      setDeleting(false);
    }
  };

  const filteredDocuments = documents.filter(doc =>
    doc.title.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const renderContent = () => {
    if (loading) {
      return (
        <div className="flex justify-center items-center min-h-[400px]">
          <Spinner />
        </div>
      );
    }

    if (documents.length === 0) {
      return (
        <div className="flex items-center justify-center min-h-[400px]">
          <div className="text-center max-w-md">
            <div className="inline-flex items-center justify-center w-20 h-20 rounded-2xl bg-stone-100 shadow-sm mb-6">
              <FileText className="w-10 h-10 text-stone-400" strokeWidth={1.5} />
            </div>
            <h3 className="text-xl font-semibold text-stone-800 tracking-tight mb-2"
              style={{ fontFamily: 'var(--font-heading)' }}>
              No documents yet
            </h3>
            <p className="text-sm text-stone-500 mb-6">Get started by uploading your first document.</p>
            <button
              onClick={() => setIsUploadModalOpen(true)}
              className="inline-flex items-center gap-2 px-6 h-11 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold rounded-xl transition-all duration-200 shadow-lg shadow-indigo-500/20 hover:-translate-y-px active:scale-[0.98]"
            >
              <Plus className="w-4 h-4" strokeWidth={2.5} />
              Upload Document
            </button>
          </div>
        </div>
      );
    }

    if (filteredDocuments.length === 0) {
      return (
        <div className="flex flex-col items-center justify-center min-h-[300px] text-center">
          <Search className="w-10 h-10 text-stone-300 mb-3" strokeWidth={1.5} />
          <p className="text-sm font-medium text-stone-500">No documents match "{searchQuery}"</p>
          <button
            onClick={() => setSearchQuery('')}
            className="mt-3 text-xs font-semibold text-indigo-600 hover:text-indigo-700 transition-colors"
          >
            Clear search
          </button>
        </div>
      );
    }

    return (
      <div className="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        {filteredDocuments.map((doc) => (
          <DocumentCard
            key={doc._id}
            document={doc}
            onDelete={handleDeleteRequest}
          />
        ))}
      </div>
    );
  };

  return (
    <div>
      {/* Page header */}
      <div className="flex justify-between items-start mb-8">
        <div>
          <h1
            className="text-3xl font-bold text-stone-900 tracking-tight"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            My Documents
          </h1>
          <p className="mt-1 text-sm text-stone-500">
            Manage and organise your learning materials
          </p>
        </div>
        <div className="flex items-center gap-3">
          {documents.length > 0 && (
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-stone-400 pointer-events-none" strokeWidth={1.5} />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search documents..."
                className="h-10 pl-9 pr-4 w-52 border-2 border-stone-200 rounded-xl bg-white text-sm text-stone-800 placeholder-stone-400 focus:outline-none focus:border-indigo-500 transition-all duration-200"
              />
            </div>
          )}
          {documents.length > 0 && (
            <Button onClick={() => setIsUploadModalOpen(true)}>
              <Plus className="w-4 h-4" strokeWidth={2.5} />
              Upload Document
            </Button>
          )}
        </div>
      </div>

      {renderContent()}

      {/* Upload Modal */}
      {isUploadModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-stone-900/50 backdrop-blur-sm">
          <div className="relative w-full max-w-lg bg-white border border-stone-200 rounded-2xl shadow-2xl p-6">
            <button
              onClick={() => setIsUploadModalOpen(false)}
              className="absolute top-5 right-5 w-8 h-8 flex items-center justify-center rounded-lg text-stone-400 hover:text-stone-600 hover:bg-stone-100 transition-all duration-200"
            >
              <X className="w-5 h-5" strokeWidth={2} />
            </button>

            <div className="mb-6">
              <h2
                className="text-xl font-bold text-stone-900 tracking-tight"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                Upload Document
              </h2>
              <p className="text-sm text-stone-500 mt-1">Add a PDF to your learning library</p>
            </div>

            <form onSubmit={handleUpload} className="space-y-5">
              <div className="space-y-1.5">
                <label className="block text-xs font-semibold text-stone-600 uppercase tracking-wider">
                  Document Title
                </label>
                <input
                  type="text"
                  value={uploadTitle}
                  onChange={(e) => setUploadTitle(e.target.value)}
                  required
                  className="w-full h-11 px-4 border-2 border-stone-200 rounded-xl bg-stone-50 text-stone-900 placeholder-stone-400 text-sm font-medium transition-all duration-200 focus:outline-none focus:border-indigo-500 focus:bg-white"
                  placeholder="Enter document title"
                />
              </div>

              <div className="space-y-1.5">
                <label className="block text-xs font-semibold text-stone-600 uppercase tracking-wider">
                  PDF File
                </label>
                <div className="relative border-2 border-dashed border-stone-300 rounded-xl bg-stone-50 hover:border-indigo-400 hover:bg-indigo-50/30 transition-all duration-200">
                  <input
                    type="file"
                    id="file-upload"
                    className="absolute inset-0 w-full h-full opacity-0 cursor-pointer z-10"
                    onChange={handleFileChange}
                    accept=".pdf"
                  />
                  <div className="flex flex-col items-center justify-center py-8 px-6">
                    <div className="w-12 h-12 rounded-xl bg-indigo-50 flex items-center justify-center mb-3">
                      <Upload className="w-6 h-6 text-indigo-500" strokeWidth={2} />
                    </div>
                    <p className="text-sm font-medium text-stone-700 mb-1">
                      {uploadFile ? (
                        <span className="text-indigo-600">{uploadFile.name}</span>
                      ) : (
                        <>
                          <span className="text-indigo-600">Click to upload</span>{" "}
                          or drag and drop
                        </>
                      )}
                    </p>
                    <p className="text-xs text-stone-400">PDF up to 10 MB</p>
                  </div>
                </div>
              </div>

              <div className="flex gap-3 pt-1">
                <button
                  type="button"
                  onClick={() => setIsUploadModalOpen(false)}
                  disabled={uploading}
                  className="flex-1 h-11 border-2 border-stone-200 rounded-xl bg-white text-stone-700 text-sm font-semibold hover:bg-stone-50 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={uploading}
                  className="flex-1 h-11 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold rounded-xl transition-all duration-200 shadow-lg shadow-indigo-500/20 disabled:opacity-50 disabled:cursor-not-allowed active:scale-[0.98]"
                >
                  {uploading ? (
                    <span className="flex items-center justify-center gap-2">
                      <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                      Uploading...
                    </span>
                  ) : (
                    "Upload"
                  )}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Delete Modal */}
      {isDeleteModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-stone-900/50 backdrop-blur-sm">
          <div className="relative w-full max-w-md bg-white border border-stone-200 rounded-2xl shadow-2xl p-7">
            <button
              onClick={() => setIsDeleteModalOpen(false)}
              className="absolute top-5 right-5 w-8 h-8 flex items-center justify-center rounded-lg text-stone-400 hover:text-stone-600 hover:bg-stone-100 transition-all duration-200"
            >
              <X className="w-5 h-5" strokeWidth={2} />
            </button>

            <div className="mb-5">
              <div className="w-11 h-11 rounded-xl bg-rose-50 flex items-center justify-center mb-4">
                <Trash2 className="w-5 h-5 text-rose-600" strokeWidth={2} />
              </div>
              <h2
                className="text-lg font-bold text-stone-900 tracking-tight"
                style={{ fontFamily: 'var(--font-heading)' }}
              >
                Delete document
              </h2>
            </div>

            <p className="text-sm text-stone-600 mb-6">
              Are you sure you want to delete{" "}
              <span className="font-semibold text-stone-900">"{selectedDoc?.title}"</span>?
              This action cannot be undone.
            </p>

            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setIsDeleteModalOpen(false)}
                disabled={deleting}
                className="flex-1 h-11 border-2 border-stone-200 rounded-xl bg-white text-stone-700 text-sm font-semibold hover:bg-stone-50 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleConfirmDelete}
                disabled={deleting}
                className="flex-1 h-11 bg-rose-600 hover:bg-rose-700 text-white text-sm font-semibold rounded-xl transition-all duration-200 shadow-lg shadow-rose-500/20 disabled:opacity-50 disabled:cursor-not-allowed active:scale-[0.98]"
              >
                {deleting ? (
                  <span className="flex items-center justify-center gap-2">
                    <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                    Deleting...
                  </span>
                ) : (
                  "Delete"
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default DocumentListPage;
