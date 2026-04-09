export type User = {
	id: number;
	name: string;
	email: string;
	avatar_url: string | null;
	api_key?: string | null;
	api_key_configured?: boolean;
};

export type Conversion = {
	id: number;
	status: 'pending' | 'processing' | 'completed' | 'failed';
	original_filename: string;
	content_type: string;
	error_message: string | null;
	csv_filename: string | null;
	created_at: string;
	updated_at: string;
	download_url: string | null;
	json_download_url: string | null;
	source_download_url: string | null;
};

export type ConversionDetails = Conversion & {
	preview_headers: string[];
	preview_rows: string[][];
};

export type CodeSamples = Record<string, string>;
