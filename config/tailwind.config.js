const defaultTheme = require('tailwindcss/defaultTheme')

module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  safelist: [
    "bg-red-100", "bg-emerald-100", "bg-cyan-100",
    "border-red-500", "border-emerald-500", "border-cyan-500", "rounded",
    "text-red-900", "text-emerald-900", "text-cyan-900",
    "text-xs", "font-bold",
    "list-disc",
    "ml-3", "w-10", "mb-4"
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Inter var', ...defaultTheme.fontFamily.sans],
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
    require('@tailwindcss/container-queries'),
  ]
}
