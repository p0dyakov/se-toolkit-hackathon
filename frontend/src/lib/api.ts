import { env } from '$env/dynamic/public';
import type { CodeSamples, Conversion, ConversionDetails, User } from '$lib/types';

const API_BASE_URL = env.PUBLIC_API_BASE_URL || 'http://localhost:3000';

type ApiOptions = RequestInit & {
	expectNoContent?: boolean;
};

export class ApiError extends Error {
	status: number;

	constructor(message: string, status: number) {
		super(message);
		this.status = status;
	}
}

export function absoluteBackendUrl(path: string) {
	return path.startsWith('http') ? path : `${API_BASE_URL}${path}`;
}

export const googleAuthUrl = absoluteBackendUrl('/auth/google_oauth2');
export const apiDocsUrl = absoluteBackendUrl('/api-docs');

async function request<T>(path: string, options: ApiOptions = {}): Promise<T> {
	const response = await fetch(absoluteBackendUrl(path), {
		credentials: 'include',
		...options
	});

	if (options.expectNoContent && response.status === 204) {
		return null as T;
	}

	const isJson = response.headers.get('content-type')?.includes('application/json');
	const payload = isJson ? await response.json() : null;

	if (!response.ok) {
		throw new ApiError(payload?.error || 'Request failed', response.status);
	}

	return payload as T;
}

export async function fetchCurrentUser() {
	try {
		const payload = await request<{ user: User; code_samples: CodeSamples }>('/api/v1/me');
		return payload;
	} catch (error) {
		if (error instanceof ApiError && error.status === 401) {
			return null;
		}

		throw error;
	}
}

export async function fetchProfile() {
	return request<{ user: User; code_samples: CodeSamples }>('/api/v1/me');
}

export async function deleteSession() {
	await request('/api/v1/session', { method: 'DELETE', expectNoContent: true });
}

export async function deleteAccount() {
	await request('/api/v1/me', { method: 'DELETE', expectNoContent: true });
}

export async function fetchConversions() {
	const payload = await request<{ conversions: Conversion[] }>('/api/v1/conversions');
	return payload.conversions;
}

export async function fetchConversionDetails(id: number) {
	const payload = await request<{ conversion: ConversionDetails }>(`/api/v1/conversions/${id}`);
	return payload.conversion;
}

export async function createConversion(file: File) {
	const formData = new FormData();
	formData.append('file', file);

	const payload = await request<{ conversion: Conversion }>('/api/v1/conversions', {
		method: 'POST',
		body: formData
	});

	return payload.conversion;
}

export async function updateConversionPreview(
	id: number,
	previewHeaders: string[],
	previewRows: string[][]
) {
	const payload = await request<{ conversion: ConversionDetails }>(`/api/v1/conversions/${id}`, {
		method: 'PATCH',
		headers: {
			'Content-Type': 'application/json'
		},
		body: JSON.stringify({
			preview_headers: previewHeaders,
			preview_rows: previewRows
		})
	});

	return payload.conversion;
}

export async function deleteConversion(id: number) {
	await request(`/api/v1/conversions/${id}`, { method: 'DELETE', expectNoContent: true });
}

export async function rotateApiKey() {
	return request<{ api_key: string; code_samples: CodeSamples }>('/api/v1/me/api-key', {
		method: 'POST'
	});
}
