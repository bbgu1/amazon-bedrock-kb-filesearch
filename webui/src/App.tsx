import React, { useEffect, useState } from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import { Layout } from './components/Layout';
import { ErrorMessage } from './components/ErrorMessage';
import { StoresPage } from './pages/StoresPage';
import { UploadPage } from './pages/UploadPage';
import { SearchPage } from './pages/SearchPage';
import { StoreProvider } from './context/StoreContext';
import { validateConfig } from './config/aws';

const App: React.FC = () => {
  const [configErrors, setConfigErrors] = useState<string[]>([]);

  useEffect(() => {
    const errors = validateConfig();
    setConfigErrors(errors);
  }, []);

  return (
    <StoreProvider>
      <Router>
        <Layout>
          {configErrors.length > 0 && (
            <div style={{ marginBottom: '2rem' }}>
              <h3 style={{ color: '#c00' }}>Configuration Errors</h3>
              {configErrors.map((error, index) => (
                <ErrorMessage key={index} message={error} />
              ))}
              <p>Please check your .env file and ensure all required AWS resources are configured.</p>
            </div>
          )}
          <Routes>
            <Route path="/" element={<StoresPage />} />
            <Route path="/upload" element={<UploadPage />} />
            <Route path="/search" element={<SearchPage />} />
          </Routes>
        </Layout>
      </Router>
    </StoreProvider>
  );
};

export default App;
