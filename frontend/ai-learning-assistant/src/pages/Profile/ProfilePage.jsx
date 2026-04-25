import React, { useState, useEffect } from "react";
import PageHeader from "../../components/common/PageHeader";
import Button from "../../components/common/Button";
import Spinner from "../../components/common/Spinner";
import authService from "../../services/authService";
import toast from "react-hot-toast";
import { User, Mail, Lock } from "lucide-react";

const ProfilePage = () => {
  const [loading, setLoading] = useState(true);
  const [passwordLoading, setPasswordLoading] = useState(false);

  const [username, setUsername] = useState('');
  const [email, setEmail] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmNewPassword, setConfirmNewPassword] = useState('');
  const [currentPassword, setCurrentPassword] = useState('');

  useEffect(() => {
    const fetchProfile = async () => {
      try {
        const { data } = await authService.getProfile();
        setUsername(data.username);
        setEmail(data.email);
      } catch (error) {
        toast.error(error.message || 'Failed to fetch user profile');
        console.error('Error fetching user profile:', error);
      } finally {
        setLoading(false);
      }
    };
    fetchProfile();
  }, []);

  const handleChangePassword = async (e) => {
    e.preventDefault();
    if (newPassword !== confirmNewPassword) {
      toast.error('Passwords do not match');
      return;
    }
    if (newPassword.length < 6) {
      toast.error('Password must be at least 6 characters long');
      return;
    }
    setPasswordLoading(true);
    try {
      await authService.changePassword({ currentPassword, newPassword });
      toast.success('Password changed successfully');
      setCurrentPassword('');
      setNewPassword('');
      setConfirmNewPassword('');
    } catch (error) {
      toast.error(error.message || 'Failed to change password');
    } finally {
      setPasswordLoading(false);
    }
  };

  if (loading) return <Spinner />;

  const inputClass = "block w-full rounded-xl border-2 border-stone-200 bg-stone-50 py-3 pl-11 pr-4 text-stone-800 placeholder-stone-400 text-sm transition-all duration-200 focus:outline-none focus:border-indigo-500 focus:bg-white";
  const readonlyClass = "block w-full rounded-xl border-2 border-transparent bg-stone-100 py-3 pl-11 pr-4 text-stone-700 text-sm";
  const labelClass = "block text-xs font-semibold text-stone-600 uppercase tracking-wider mb-1.5";

  return (
    <div>
      <PageHeader title="Profile settings" subtitle="Manage your account information and security" />

      <div className="space-y-6 max-w-3xl">
        {/* User Information */}
        <div className="bg-white border border-stone-200 rounded-2xl shadow-sm p-6">
          <h3
            className="text-base font-semibold text-stone-900 mb-5"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Account information
          </h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <div>
              <label className={labelClass}>Username</label>
              <div className="relative">
                <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-4">
                  <User className="h-4 w-4 text-stone-400" />
                </div>
                <p className={readonlyClass}>{username}</p>
              </div>
            </div>
            <div>
              <label className={labelClass}>Email address</label>
              <div className="relative">
                <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-4">
                  <Mail className="h-4 w-4 text-stone-400" />
                </div>
                <p className={readonlyClass}>{email}</p>
              </div>
            </div>
          </div>
        </div>

        {/* Change Password */}
        <div className="bg-white border border-stone-200 rounded-2xl shadow-sm p-6">
          <h3
            className="text-base font-semibold text-stone-900 mb-5"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Change password
          </h3>
          <form onSubmit={handleChangePassword} className="space-y-5">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              <div>
                <label className={labelClass}>Current password</label>
                <div className="relative">
                  <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-4">
                    <Lock className="h-4 w-4 text-stone-400" />
                  </div>
                  <input
                    type="password"
                    value={currentPassword}
                    onChange={(e) => setCurrentPassword(e.target.value)}
                    className={inputClass}
                    placeholder="Enter current password"
                    required
                  />
                </div>
              </div>
              <div>
                <label className={labelClass}>New password</label>
                <div className="relative">
                  <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-4">
                    <Lock className="h-4 w-4 text-stone-400" />
                  </div>
                  <input
                    type="password"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    className={inputClass}
                    placeholder="Enter new password"
                    required
                  />
                </div>
              </div>
              <div>
                <label className={labelClass}>Confirm new password</label>
                <div className="relative">
                  <div className="pointer-events-none absolute inset-y-0 left-0 flex items-center pl-4">
                    <Lock className="h-4 w-4 text-stone-400" />
                  </div>
                  <input
                    type="password"
                    value={confirmNewPassword}
                    onChange={(e) => setConfirmNewPassword(e.target.value)}
                    className={inputClass}
                    placeholder="Confirm new password"
                  />
                </div>
              </div>
            </div>
            <div className="flex justify-end pt-1">
              <Button type="submit" disabled={passwordLoading}>
                {passwordLoading ? "Saving..." : "Change Password"}
              </Button>
            </div>
          </form>
        </div>
      </div>
    </div>
  );
};

export default ProfilePage;
