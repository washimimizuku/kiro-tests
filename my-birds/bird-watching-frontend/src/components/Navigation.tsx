import React from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import './Navigation.css';

const Navigation: React.FC = () => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <nav className="navigation">
      <div className="nav-container">
        <div className="nav-brand">
          <span className="brand-icon">🦅</span>
          <span className="brand-text">Bird Watching</span>
        </div>

        <div className="nav-links">
          <NavLink to="/dashboard" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
            Dashboard
          </NavLink>
          <NavLink to="/observations" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
            My Observations
          </NavLink>
          <NavLink to="/trips" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
            My Trips
          </NavLink>
          <NavLink to="/shared" className={({ isActive }) => isActive ? 'nav-link active' : 'nav-link'}>
            Shared
          </NavLink>
        </div>

        <div className="nav-user">
          <span className="user-name">{user?.username}</span>
          <button onClick={handleLogout} className="logout-btn">
            Logout
          </button>
        </div>
      </div>
    </nav>
  );
};

export default Navigation;
