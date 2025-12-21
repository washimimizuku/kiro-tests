# Work Tracker Frontend

React TypeScript frontend for the Work Tracker application.

## Tech Stack

- **React 18** with TypeScript
- **Vite** for build tooling
- **Tailwind CSS** for styling
- **React Router** for navigation
- **React Query** for data fetching
- **React Hook Form** with Zod validation
- **Vitest** for testing
- **fast-check** for property-based testing

## Development

1. **Install dependencies**
   ```bash
   npm install
   ```

2. **Start development server**
   ```bash
   npm run dev
   ```

3. **Run tests**
   ```bash
   npm test
   ```

4. **Build for production**
   ```bash
   npm run build
   ```

## Project Structure

```
src/
├── components/         # Reusable UI components
├── pages/             # Route-based page components
├── types/             # TypeScript type definitions
├── utils/             # Utility functions and API client
├── test/              # Test setup and utilities
├── App.tsx            # Main application component
├── main.tsx           # Application entry point
└── index.css          # Global styles
```

## Environment Variables

Create a `.env` file in the frontend directory:

```env
VITE_API_URL=http://localhost:8000/api/v1
```

## Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run preview` - Preview production build
- `npm run lint` - Run ESLint
- `npm run lint:fix` - Fix ESLint errors
- `npm run type-check` - Run TypeScript type checking
- `npm test` - Run tests once
- `npm run test:watch` - Run tests in watch mode
- `npm run test:coverage` - Run tests with coverage

## Deployment

The frontend is designed to be deployed as a static site to:
- AWS S3 + CloudFront
- Vercel
- Netlify
- Any static hosting service

Build the application with `npm run build` and deploy the `dist` directory.