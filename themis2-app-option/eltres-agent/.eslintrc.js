module.exports = {
  root: true,
  env: {
      node: true,
      jest: true,
  },
  parser: '@typescript-eslint/parser',
  parserOptions: {
      project: 'tsconfig.json',
      tsconfigRootDir: __dirname,
      sourceType: 'module',
  },
  plugins: [
      '@typescript-eslint/eslint-plugin',
      'import'
  ],
  extends: [
      'plugin:@typescript-eslint/recommended',
      'plugin:prettier/recommended',
  ],
  ignorePatterns: ['.eslintrc.js'],
  rules: {
      '@typescript-eslint/interface-name-prefix': 'off',
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/explicit-module-boundary-types': 'off',
      '@typescript-eslint/consistent-type-imports': 'error',
      '@typescript-eslint/naming-convention': [
      'error',
      { selector: 'variableLike', format: ['camelCase', 'UPPER_CASE'] },
      { selector: 'typeLike', format: ['PascalCase'] },
      { selector: 'method', format: ['camelCase'] },
      { selector: 'property', format: ['camelCase'] },
      ],

      'import/no-duplicates': 'error',
      'import/order': [
      'error',
      {
          groups: ['builtin', 'external', 'parent', 'sibling', 'index', 'object', 'type'],
          'newlines-between': 'always',
          'alphabetize': {
          order: 'asc',
          caseInsensitive: true,
          },
      }
      ],
  },
}