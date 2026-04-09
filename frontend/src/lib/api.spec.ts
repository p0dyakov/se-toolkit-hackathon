import { describe, expect, it } from 'vitest';
import { absoluteBackendUrl } from './api';

describe('absoluteBackendUrl', () => {
	it('prefixes relative paths with the backend origin', () => {
		expect(absoluteBackendUrl('/api/v1/me')).toContain('/api/v1/me');
	});

	it('leaves absolute urls untouched', () => {
		expect(absoluteBackendUrl('https://example.com/file.csv')).toBe('https://example.com/file.csv');
	});
});
