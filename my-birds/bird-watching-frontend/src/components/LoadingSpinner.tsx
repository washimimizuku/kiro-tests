import React from 'react';
import './LoadingSpinner.css';

interface LoadingSpinnerProps {
  size?: 'small' | 'medium' | 'large';
  fullScreen?: boolean;
  message?: string;
}

const LoadingSpinner: React.FC<LoadingSpinnerProps> = ({ 
  size = 'medium', 
  fullScreen = false,
  message 
}) => {
  const sizeMap = {
    small: '20px',
    medium: '40px',
    large: '60px',
  };

  const spinner = (
    <div className={`loading-spinner-container ${fullScreen ? 'fullscreen' : ''}`}>
      <div 
        className="loading-spinner" 
        style={{ 
          width: sizeMap[size], 
          height: sizeMap[size] 
        }}
      />
      {message && <p className="loading-message">{message}</p>}
    </div>
  );

  return spinner;
};

export default LoadingSpinner;
