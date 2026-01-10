import React, { createContext, useContext, useState, ReactNode } from 'react';

interface StoreContextType {
  selectedStoreId: string | null;
  setSelectedStoreId: (storeId: string | null) => void;
}

const StoreContext = createContext<StoreContextType | undefined>(undefined);

export const StoreProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [selectedStoreId, setSelectedStoreId] = useState<string | null>(
    localStorage.getItem('selectedStoreId')
  );

  const handleSetSelectedStoreId = (storeId: string | null) => {
    setSelectedStoreId(storeId);
    if (storeId) {
      localStorage.setItem('selectedStoreId', storeId);
    } else {
      localStorage.removeItem('selectedStoreId');
    }
  };

  return (
    <StoreContext.Provider value={{ selectedStoreId, setSelectedStoreId: handleSetSelectedStoreId }}>
      {children}
    </StoreContext.Provider>
  );
};

export const useStore = (): StoreContextType => {
  const context = useContext(StoreContext);
  if (!context) {
    throw new Error('useStore must be used within a StoreProvider');
  }
  return context;
};
