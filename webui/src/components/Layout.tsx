import React from 'react';
import { Link, useLocation } from 'react-router-dom';

interface LayoutProps {
  children: React.ReactNode;
}

export const Layout: React.FC<LayoutProps> = ({ children }) => {
  const location = useLocation();

  const isActive = (path: string) => location.pathname === path;

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      <nav style={{
        backgroundColor: '#232f3e',
        color: 'white',
        padding: '1rem 2rem',
        display: 'flex',
        alignItems: 'center',
        gap: '2rem'
      }}>
        <h1 style={{ margin: 0, fontSize: '1.5rem' }}>Bedrock File Search</h1>
        <div style={{ display: 'flex', gap: '1.5rem' }}>
          <Link
            to="/"
            style={{
              color: isActive('/') ? '#ff9900' : 'white',
              textDecoration: 'none',
              fontWeight: isActive('/') ? 'bold' : 'normal'
            }}
          >
            Stores
          </Link>
          <Link
            to="/upload"
            style={{
              color: isActive('/upload') ? '#ff9900' : 'white',
              textDecoration: 'none',
              fontWeight: isActive('/upload') ? 'bold' : 'normal'
            }}
          >
            Upload
          </Link>
          <Link
            to="/search"
            style={{
              color: isActive('/search') ? '#ff9900' : 'white',
              textDecoration: 'none',
              fontWeight: isActive('/search') ? 'bold' : 'normal'
            }}
          >
            Search
          </Link>
        </div>
      </nav>
      <main style={{ flex: 1, padding: '2rem', maxWidth: '1200px', width: '100%', margin: '0 auto' }}>
        {children}
      </main>
      <footer style={{
        backgroundColor: '#f5f5f5',
        padding: '1rem 2rem',
        textAlign: 'center',
        color: '#666'
      }}>
        <p style={{ margin: 0 }}>Bedrock File Search - Multi-tenant Document Management</p>
      </footer>
    </div>
  );
};
