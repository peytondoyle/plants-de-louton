import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import Header from './Header';

describe('Header', () => {
  it('renders without crashing', () => {
    render(
      <BrowserRouter>
        <Header />
      </BrowserRouter>
    );
    expect(screen.getByTestId('header')).toBeInTheDocument();
  });

  it('renders brand name', () => {
    render(
      <BrowserRouter>
        <Header />
      </BrowserRouter>
    );
    expect(screen.getByText('Plants de Louton')).toBeInTheDocument();
  });

  it('renders navigation pills', () => {
    render(
      <BrowserRouter>
        <Header />
      </BrowserRouter>
    );
    expect(screen.getByText('Front yard')).toBeInTheDocument();
    expect(screen.getByText('Back yard')).toBeInTheDocument();
  });

  it('applies correct CSS classes', () => {
    render(
      <BrowserRouter>
        <Header />
      </BrowserRouter>
    );
    
    // Check header has correct class
    expect(screen.getByTestId('header')).toHaveClass('site-header');
    
    // Check brand has correct class
    expect(screen.getByText('Plants de Louton')).toHaveClass('brand');
    
    // Check navigation has correct class
    expect(screen.getByText('Front yard')).toHaveClass('ui-btn');
  });

  it('shows bed name when provided', () => {
    render(
      <BrowserRouter>
        <Header bedName="Test Bed" />
      </BrowserRouter>
    );
    expect(screen.getByText('Test Bed')).toBeInTheDocument();
  });

  it('does not show bed name when not provided', () => {
    render(
      <BrowserRouter>
        <Header />
      </BrowserRouter>
    );
    expect(screen.queryByTestId('bed-name')).not.toBeInTheDocument();
  });
});



