import React, { useState, useEffect } from "react";
import { Link } from "react-router-dom";
import Spinner from '../../components/common/Spinner';
import progressService from '../../services/progressService';
import { useAuth } from '../../context/AuthContext';
import toast from 'react-hot-toast';
import { FileText, BookOpen, BrainCircuit, Clock, Flame, ArrowRight } from 'lucide-react';
import moment from 'moment';

const getGreeting = () => {
  const h = new Date().getHours();
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
};

const DashboardPage = () => {
  const [dashboardData, setDashboardData] = useState(null);
  const [loading, setLoading] = useState(true);
  const { user } = useAuth();

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        const data = await progressService.getDashboardData();
        setDashboardData(data.data);
      } catch (error) {
        toast.error('Failed to fetch dashboard data.');
        console.error(error);
      } finally {
        setLoading(false);
      }
    };
    fetchDashboardData();
  }, []);

  if (loading) return <Spinner />;

  if (!dashboardData || !dashboardData.overview) {
    return (
      <div className="flex items-center justify-center h-full text-stone-500">
        <div className="flex flex-col items-center gap-4">
          <div className="p-4 bg-stone-100 rounded-2xl">
            <BrainCircuit className="w-8 h-8 text-stone-400" strokeWidth={1.5} />
          </div>
          <p className="text-base font-semibold text-stone-700">No data available yet.</p>
          <p className="text-sm text-stone-400">Upload a document to get started.</p>
        </div>
      </div>
    );
  }

  const stats = [
    {
      label: 'Documents',
      value: dashboardData.overview.totalDocuments || 0,
      icon: FileText,
      iconBg: 'bg-indigo-50',
      iconColor: 'text-indigo-600',
      link: '/documents',
    },
    {
      label: 'Flashcards',
      value: dashboardData.overview.totalFlashcards || 0,
      icon: BookOpen,
      iconBg: 'bg-amber-50',
      iconColor: 'text-amber-600',
      link: '/documents',
    },
    {
      label: 'Quizzes',
      value: dashboardData.overview.totalQuizzes || 0,
      icon: BrainCircuit,
      iconBg: 'bg-emerald-50',
      iconColor: 'text-emerald-600',
      link: '/documents',
    },
    {
      label: 'Day streak',
      value: dashboardData.overview.streak || 0,
      icon: Flame,
      iconBg: 'bg-rose-50',
      iconColor: 'text-rose-500',
      link: null,
    },
  ];

  const docs = dashboardData.recentActivity?.documents || [];
  const quizAttempts = dashboardData.recentActivity?.quizzes || [];

  const recentItems = [
    ...docs.map(doc => ({
      id: doc._id,
      description: doc.title,
      timestamp: doc.lastAccessed,
      link: `/documents/${doc._id}`,
      type: 'document',
    })),
    ...quizAttempts.map(quiz => ({
      id: quiz._id,
      description: quiz.title,
      timestamp: quiz.lastAttempted,
      link: `/quizzes/${quiz._id}/results`,
      type: 'quiz',
    })),
  ].sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));

  return (
    <div className="space-y-7">
      {/* Welcome header */}
      <div className="flex items-start justify-between">
        <div>
          <p className="text-xs font-semibold text-stone-400 uppercase tracking-widest mb-1">
            {moment().format('dddd, MMMM D')}
          </p>
          <h1
            className="text-4xl font-bold text-stone-900 tracking-tight"
            style={{ fontFamily: 'var(--font-heading)', letterSpacing: '-0.02em' }}
          >
            {getGreeting()}, {user?.username || 'there'}
          </h1>
          <p className="mt-1 text-sm text-stone-400">
            Here's an overview of your learning progress.
          </p>
        </div>
        <Link
          to="/documents"
          className="hidden sm:inline-flex items-center gap-2 px-4 h-9 text-sm font-semibold text-indigo-600 bg-indigo-50 hover:bg-indigo-100 rounded-xl transition-all duration-200"
        >
          View documents
          <ArrowRight className="w-3.5 h-3.5" strokeWidth={2.5} />
        </Link>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        {stats.map((stat, index) => (
          <div
            key={index}
            className="bg-white border border-stone-200 rounded-2xl p-5 hover:border-stone-300 hover:shadow-[0_4px_12px_rgba(28,25,23,0.06)] transition-all duration-[240ms]"
          >
            <div className="flex items-start justify-between mb-4">
              <div className={`w-10 h-10 rounded-xl ${stat.iconBg} flex items-center justify-center`}>
                <stat.icon className={`w-5 h-5 ${stat.iconColor}`} strokeWidth={1.5} />
              </div>
            </div>
            <p
              className="text-3xl font-bold text-stone-900 mb-1 tracking-tight"
              style={{ fontFamily: 'var(--font-heading)' }}
            >
              {stat.value.toLocaleString()}
            </p>
            <p className="text-sm text-stone-500 font-medium">{stat.label}</p>
          </div>
        ))}
      </div>

      {/* Recent Activity */}
      <div className="bg-white border border-stone-200 rounded-2xl shadow-[0_1px_2px_rgba(28,25,23,0.04)]">
        <div className="flex items-center justify-between px-6 py-4 border-b border-stone-100">
          <div className="flex items-center gap-2.5">
            <div className="w-7 h-7 rounded-lg bg-stone-100 flex items-center justify-center">
              <Clock className="w-3.5 h-3.5 text-stone-500" strokeWidth={2} />
            </div>
            <h3
              className="text-base font-semibold text-stone-900"
              style={{ fontFamily: 'var(--font-heading)' }}
            >
              Recent activity
            </h3>
          </div>
          {recentItems.length > 0 && (
            <span className="text-xs font-medium text-stone-400">{recentItems.length} item{recentItems.length !== 1 ? 's' : ''}</span>
          )}
        </div>

        {recentItems.length > 0 ? (
          <div className="divide-y divide-stone-50">
            {recentItems.slice(0, 8).map((activity, index) => (
              <div
                key={activity.id || index}
                className="flex items-center justify-between px-6 py-3 hover:bg-stone-50/60 transition-colors duration-150"
              >
                <div className="flex items-center gap-3 min-w-0">
                  <div className={`w-1.5 h-1.5 rounded-full shrink-0 ${
                    activity.type === 'document' ? 'bg-indigo-500' : 'bg-emerald-500'
                  }`} />
                  <div className="min-w-0">
                    <p className="text-sm text-stone-800 font-medium truncate">{activity.description}</p>
                    <p className="text-xs text-stone-400 mt-0.5">
                      {activity.type === 'document' ? 'Document accessed' : 'Quiz attempted'} · {moment(activity.timestamp).fromNow()}
                    </p>
                  </div>
                </div>
                {activity.link && (
                  <Link
                    to={activity.link}
                    className="shrink-0 ml-4 text-xs font-semibold text-indigo-600 hover:text-indigo-700 transition-colors flex items-center gap-1"
                  >
                    View
                    <ArrowRight className="w-3 h-3" strokeWidth={2.5} />
                  </Link>
                )}
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-14">
            <div className="flex items-center justify-center w-12 h-12 bg-stone-100 rounded-2xl mx-auto mb-3">
              <Clock className="w-6 h-6 text-stone-400" strokeWidth={1.5} />
            </div>
            <p className="text-sm font-semibold text-stone-700 mb-1">No recent activity yet</p>
            <p className="text-xs text-stone-400 mb-5">Upload a document to get started.</p>
            <Link
              to="/documents"
              className="inline-flex items-center gap-2 px-5 h-9 text-sm font-semibold text-indigo-600 bg-indigo-50 hover:bg-indigo-100 rounded-xl transition-all duration-200"
            >
              Go to documents
              <ArrowRight className="w-3.5 h-3.5" strokeWidth={2.5} />
            </Link>
          </div>
        )}
      </div>
    </div>
  );
};

export default DashboardPage;
