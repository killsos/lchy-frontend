/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // 自定义暗黑模式颜色
        dark: {
          bg: '#0f172a',        // 主背景
          surface: '#1e293b',   // 卡片背景  
          border: '#334155',    // 边框颜色
          text: '#f1f5f9',      // 主文字
          'text-secondary': '#cbd5e1', // 次要文字
        },
        // 图表暗色主题
        chart: {
          dark: {
            bg: '#1e293b',
            grid: '#475569',
            text: '#e2e8f0',
            axis: '#64748b',
          }
        }
      },
      // 暗黑模式下的阴影
      boxShadow: {
        'dark-sm': '0 1px 2px 0 rgba(0, 0, 0, 0.5)',
        'dark-md': '0 4px 6px -1px rgba(0, 0, 0, 0.5), 0 2px 4px -1px rgba(0, 0, 0, 0.3)',
        'dark-lg': '0 10px 15px -3px rgba(0, 0, 0, 0.5), 0 4px 6px -2px rgba(0, 0, 0, 0.3)',
      }
    },
  },
  plugins: [],
}