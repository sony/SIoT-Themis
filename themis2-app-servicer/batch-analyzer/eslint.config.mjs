import eslint from '@eslint/js';
import tseslint from 'typescript-eslint';
import importPlugin from 'eslint-plugin-import';

export default tseslint.config({
    extends: [
        eslint.configs.recommended,
        ...tseslint.configs.recommended,
    ],
    plugins: { import: importPlugin },
    ignores: ['.gitignore'],
    rules: {
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
});