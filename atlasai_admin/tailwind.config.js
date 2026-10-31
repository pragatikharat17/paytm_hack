/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        navy: {
          950: '#060B18',
          900: '#0A1128',
          850: '#0F1A3A',
          800: '#14224D',
          700: '#1F3160',
          600: '#2C427B',
        },
        teal: {
          400: '#00E5FF',
          500: '#00B4D8',
          600: '#0096C7',
          700: '#0077B6',
        },
        amber: {
          400: '#FBBF24',
          500: '#F59E0B',
          600: '#D97706',
        },
        emerald: {
          400: '#34D399',
          500: '#10B981',
          600: '#059669',
        },
        rose: {
          400: '#F87171',
          500: '#EF4444',
          600: '#DC2626',
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'sans-serif'],
      }
    },
  },
  plugins: [],
}
