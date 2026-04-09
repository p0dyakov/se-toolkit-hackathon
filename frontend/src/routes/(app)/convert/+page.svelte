<script lang="ts">
	import EyeIcon from '@lucide/svelte/icons/eye';
	import Loader2Icon from '@lucide/svelte/icons/loader-2';
	import PlusIcon from '@lucide/svelte/icons/plus';
	import SearchIcon from '@lucide/svelte/icons/search';
	import Trash2Icon from '@lucide/svelte/icons/trash-2';
	import UploadCloudIcon from '@lucide/svelte/icons/upload-cloud';
	import { onMount } from 'svelte';
	import { toast } from 'svelte-sonner';
	import {
		absoluteBackendUrl,
		createConversion,
		deleteConversion,
		fetchConversionDetails,
		fetchConversions,
		updateConversionPreview
	} from '$lib/api';
	import type { Conversion, ConversionDetails } from '$lib/types';
	import * as AlertDialog from '$lib/components/ui/alert-dialog';
	import { Badge } from '$lib/components/ui/badge';
	import { Button } from '$lib/components/ui/button';
	import * as Card from '$lib/components/ui/card';
	import * as Dialog from '$lib/components/ui/dialog';
	import { Input } from '$lib/components/ui/input';
	import * as Select from '$lib/components/ui/select';
	import * as Table from '$lib/components/ui/table';

	const MAX_FILE_SIZE = 15 * 1024 * 1024;

	let conversions = $state<Conversion[]>([]);
	let isLoading = $state(true);
	let uploadInputRef = $state<HTMLInputElement | null>(null);
	let uploadFiles = $state<FileList | undefined>(undefined);
	let searchQuery = $state('');
	let statusFilter = $state<'all' | Conversion['status']>('all');
	let sortOrder = $state<'newest' | 'oldest'>('newest');
	let previewDialogOpen = $state(false);
	let previewLoading = $state(false);
	let previewSaving = $state(false);
	let previewConversion = $state<ConversionDetails | null>(null);
	let editableRows = $state<string[][]>([]);
	let previewSaveTimeout = $state<ReturnType<typeof setTimeout> | null>(null);
	let deleteDialogOpen = $state(false);
	let conversionPendingDelete = $state<Conversion | null>(null);

	const filteredConversions = $derived.by(() => {
		const query = searchQuery.trim().toLowerCase();
		const filtered = conversions.filter((conversion) => {
			const matchesQuery = conversion.original_filename.toLowerCase().includes(query);
			const matchesStatus = statusFilter === 'all' || conversion.status === statusFilter;
			return matchesQuery && matchesStatus;
		});

		return filtered.sort((left, right) => {
			const leftTime = new Date(left.created_at).getTime();
			const rightTime = new Date(right.created_at).getTime();
			return sortOrder === 'newest' ? rightTime - leftTime : leftTime - rightTime;
		});
	});

	onMount(() => {
		void loadConversions();
	});

	async function loadConversions() {
		try {
			conversions = await fetchConversions();
		} catch (error) {
			console.error(error);
			toast.error('Unable to load conversions.');
		} finally {
			isLoading = false;
		}
	}

	function statusVariant(status: Conversion['status']) {
		if (status === 'completed') return 'default';
		if (status === 'failed') return 'destructive';
		return 'secondary';
	}

	function formatStatusLabel(status: 'all' | Conversion['status']) {
		if (status === 'all') return 'All statuses';
		return `${status.charAt(0).toUpperCase()}${status.slice(1)}`;
	}

	function formatDate(value: string) {
		return new Intl.DateTimeFormat('en', {
			dateStyle: 'medium',
			timeStyle: 'short'
		}).format(new Date(value));
	}

	function previewColumnClass(index: number, totalColumns: number) {
		const isLastDataColumn = index === totalColumns - 1;
		const isMiddleTextColumn = index === 1;

		if (isMiddleTextColumn) {
			return 'sticky top-0 z-10 w-[24%] border-b bg-background/95 px-1.5 py-2 text-xs backdrop-blur supports-[backdrop-filter]:bg-background/85 sm:px-2 sm:text-sm';
		}
		if (isLastDataColumn) {
			return 'sticky top-0 z-10 w-[18%] border-b bg-background/95 px-1.5 py-2 text-xs backdrop-blur supports-[backdrop-filter]:bg-background/85 sm:px-2 sm:text-sm';
		}
		return 'sticky top-0 z-10 w-[16%] border-b bg-background/95 px-1.5 py-2 text-xs backdrop-blur supports-[backdrop-filter]:bg-background/85 sm:px-2 sm:text-sm';
	}

	function previewCellClass(index: number) {
		return index === 1 ? 'p-1 sm:p-1.5' : 'p-1 sm:p-1.5';
	}

	function previewInputClass(index: number) {
		if (index === 1) {
			return 'h-7 w-full min-w-0 text-xs sm:h-8 sm:text-sm';
		}

		return 'h-7 w-full min-w-0 text-xs sm:h-8 sm:text-sm';
	}

	function validateFile(file: File) {
		if (file.type !== 'application/pdf') return 'Only PDF files are allowed.';
		if (file.size > MAX_FILE_SIZE) return 'Maximum file size is 15 MB.';
		return null;
	}

	function buildOptimisticConversion(file: File): Conversion {
		return {
			id: -Date.now() - Math.floor(Math.random() * 1000),
			status: 'pending',
			original_filename: file.name,
			content_type: file.type || 'application/pdf',
			error_message: null,
			csv_filename: null,
			created_at: new Date().toISOString(),
			updated_at: new Date().toISOString(),
			download_url: null,
			json_download_url: null,
			source_download_url: null
		};
	}

	async function enqueueFiles(files: File[]) {
		const validEntries = files.flatMap((file) => {
			const validationError = validateFile(file);
			if (validationError) {
				toast.error(`${file.name}: ${validationError}`);
				return [];
			}

			return [{ file, optimisticConversion: buildOptimisticConversion(file) }];
		});

		if (validEntries.length === 0) return;

		conversions = [
			...validEntries.map(({ optimisticConversion }) => optimisticConversion),
			...conversions
		];

		await Promise.all(
			validEntries.map(async ({ file, optimisticConversion }) => {
				conversions = conversions.map((current) =>
					current.id === optimisticConversion.id
						? { ...current, status: 'processing', updated_at: new Date().toISOString() }
						: current
				);

				try {
					const conversion = await createConversion(file);
					conversions = conversions.map((current) =>
						current.id === optimisticConversion.id ? conversion : current
					);
				} catch (error) {
					console.error(error);
					const message = error instanceof Error ? error.message : 'Conversion failed.';
					conversions = conversions.map((current) =>
						current.id === optimisticConversion.id
							? {
									...current,
									status: 'failed',
									error_message: message,
									updated_at: new Date().toISOString()
								}
							: current
					);
					toast.error(`${file.name}: ${message}`);
				}
			})
		);
	}

	function handleFileSelection() {
		void enqueueFiles(Array.from(uploadFiles ?? []));
		uploadFiles = undefined;

		if (uploadInputRef) {
			uploadInputRef.value = '';
		}
	}

	function handleDrop(event: DragEvent) {
		event.preventDefault();
		void enqueueFiles(Array.from(event.dataTransfer?.files ?? []));
	}

	function openDownload(path: string | null) {
		if (!path) {
			toast.error('The requested file is not available.');
			return;
		}

		window.location.assign(absoluteBackendUrl(path));
	}

	async function openPreview(conversion: Conversion) {
		previewDialogOpen = true;
		previewLoading = true;

		try {
			const details = await fetchConversionDetails(conversion.id);
			previewConversion = details;
			editableRows = details.preview_rows.map((row) => row.map((cell) => String(cell ?? '')));
		} catch (error) {
			console.error(error);
			toast.error('Could not load preview data.');
			previewDialogOpen = false;
		} finally {
			previewLoading = false;
		}
	}

	function updateCell(rowIndex: number, cellIndex: number, value: string) {
		editableRows = editableRows.map((row, currentRowIndex) =>
			currentRowIndex === rowIndex
				? row.map((cell, currentCellIndex) => (currentCellIndex === cellIndex ? value : cell))
				: row
		);
		schedulePreviewSave();
	}

	function removePreviewRow(index: number) {
		editableRows = editableRows.filter((_, currentIndex) => currentIndex !== index);
		schedulePreviewSave();
	}

	function schedulePreviewSave() {
		if (previewSaveTimeout) {
			clearTimeout(previewSaveTimeout);
		}

		previewSaveTimeout = setTimeout(() => {
			void savePreviewChanges();
		}, 500);
	}

	async function savePreviewChanges() {
		if (!previewConversion || previewSaving) return;

		if (previewSaveTimeout) {
			clearTimeout(previewSaveTimeout);
			previewSaveTimeout = null;
		}

		previewSaving = true;

		try {
			const updated = await updateConversionPreview(
				previewConversion.id,
				previewConversion.preview_headers,
				editableRows
			);
			previewConversion = updated;
			editableRows = updated.preview_rows.map((row) => row.map((cell) => String(cell ?? '')));
			conversions = conversions.map((conversion) =>
				conversion.id === updated.id ? updated : conversion
			);
		} catch (error) {
			console.error(error);
			toast.error('Could not save preview changes.');
		} finally {
			previewSaving = false;
		}
	}

	async function confirmDeleteConversion() {
		if (!conversionPendingDelete) return;

		try {
			await deleteConversion(conversionPendingDelete.id);
			conversions = conversions.filter(
				(conversion) => conversion.id !== conversionPendingDelete?.id
			);
			deleteDialogOpen = false;
			conversionPendingDelete = null;
			toast.success('Conversion deleted.');
		} catch (error) {
			console.error(error);
			toast.error('Could not delete the conversion.');
		}
	}
</script>

<div class="space-y-6 sm:space-y-8">
	<div
		role="presentation"
		class="rounded-lg border border-dashed p-5 sm:p-8"
		ondragover={(event) => event.preventDefault()}
		ondrop={handleDrop}
	>
		<div class="flex flex-col items-center gap-4 text-center">
			<div class="rounded-full border p-3">
				<UploadCloudIcon class="size-5" />
			</div>
			<div class="space-y-1">
				<p class="text-sm font-medium">Drag and drop PDFs here</p>
				<p class="text-sm text-muted-foreground">PDF only, up to 15 MB each.</p>
			</div>
			<div class="flex flex-col gap-2 sm:flex-row">
				<Input
					bind:ref={uploadInputRef}
					bind:files={uploadFiles}
					type="file"
					multiple
					accept=".pdf,application/pdf"
					class="hidden"
					onchange={handleFileSelection}
				/>
				<Button onclick={() => uploadInputRef?.click()}>
					<PlusIcon class="size-4" />
					Add PDFs
				</Button>
			</div>
		</div>
	</div>

	<Card.Root class="gap-0 py-0">
		<Card.Header class="gap-3 px-4 pt-4 pb-0 sm:px-6 sm:pt-6">
			<div
				class="flex w-full flex-col gap-2 sm:grid sm:grid-cols-[minmax(0,1fr)_auto] sm:items-center sm:gap-3"
			>
				<div class="relative w-full min-w-0">
					<SearchIcon
						class="absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground"
					/>
					<Input class="!h-10 !py-0 pl-9" placeholder="Search files" bind:value={searchQuery} />
				</div>
				<div class="flex w-full flex-col gap-2 sm:w-auto sm:flex-row sm:justify-self-end">
					<Select.Root type="single" bind:value={statusFilter}>
						<Select.Trigger size="input" class="w-full sm:w-40">
							{formatStatusLabel(statusFilter)}
						</Select.Trigger>
						<Select.Content class="rounded-xl p-1.5">
							<Select.Item class="min-h-10 rounded-lg px-3" value="all" label="All statuses"
								>All statuses</Select.Item
							>
							<Select.Item class="min-h-10 rounded-lg px-3" value="pending" label="Pending"
								>Pending</Select.Item
							>
							<Select.Item class="min-h-10 rounded-lg px-3" value="processing" label="Processing"
								>Processing</Select.Item
							>
							<Select.Item class="min-h-10 rounded-lg px-3" value="completed" label="Completed"
								>Completed</Select.Item
							>
							<Select.Item class="min-h-10 rounded-lg px-3" value="failed" label="Failed"
								>Failed</Select.Item
							>
						</Select.Content>
					</Select.Root>
					<Select.Root type="single" bind:value={sortOrder}>
						<Select.Trigger size="input" class="w-full sm:w-36">
							{sortOrder === 'newest' ? 'Newest first' : 'Oldest first'}
						</Select.Trigger>
						<Select.Content class="rounded-xl p-1.5">
							<Select.Item class="min-h-10 rounded-lg px-3" value="newest" label="Newest first"
								>Newest first</Select.Item
							>
							<Select.Item class="min-h-10 rounded-lg px-3" value="oldest" label="Oldest first"
								>Oldest first</Select.Item
							>
						</Select.Content>
					</Select.Root>
				</div>
			</div>
		</Card.Header>
		<Card.Content class="px-4 pt-4 pb-4 sm:px-6 sm:pt-6 sm:pb-6">
			{#if isLoading}
				<div class="flex h-24 items-center justify-center text-sm text-muted-foreground">
					Loading conversions…
				</div>
			{:else if filteredConversions.length === 0}
				<div class="flex h-24 items-center justify-center text-sm text-muted-foreground">
					No conversions found.
				</div>
			{:else}
				<div class="space-y-3 sm:hidden">
					{#each filteredConversions as conversion (conversion.id)}
						<Card.Root class="gap-0 py-0">
							<Card.Content class="space-y-4 p-4">
								<div class="flex items-start justify-between gap-3">
									<div class="min-w-0 space-y-1">
										<p class="truncate text-sm font-medium">{conversion.original_filename}</p>
										<p class="text-xs text-muted-foreground">{formatDate(conversion.created_at)}</p>
									</div>
									<Badge variant={statusVariant(conversion.status)} class="shrink-0 capitalize">
										{#if conversion.status === 'processing'}
											<Loader2Icon class="mr-1 size-3.5 animate-spin" />
										{/if}
										{conversion.status}
									</Badge>
								</div>

								{#if conversion.error_message}
									<p class="text-xs text-destructive">{conversion.error_message}</p>
								{/if}

								<div class="flex flex-wrap gap-2">
									<Button
										variant="outline"
										size="sm"
										disabled={!conversion.source_download_url}
										onclick={() => openDownload(conversion.source_download_url)}
									>
										PDF
									</Button>
									<Button
										variant="outline"
										size="sm"
										disabled={!conversion.download_url}
										onclick={() => openDownload(conversion.download_url)}
									>
										CSV
									</Button>
									<Button
										variant="outline"
										size="sm"
										disabled={!conversion.json_download_url}
										onclick={() => openDownload(conversion.json_download_url)}
									>
										JSON
									</Button>
								</div>

								<div class="grid grid-cols-2 gap-2">
									<Button
										variant="outline"
										size="sm"
										disabled={conversion.status === 'pending' || conversion.status === 'processing'}
										onclick={() => openPreview(conversion)}
									>
										<EyeIcon class="size-4" />
										Preview
									</Button>
									<Button
										variant="ghost"
										size="sm"
										disabled={conversion.status === 'pending' || conversion.status === 'processing'}
										class="text-destructive hover:text-destructive"
										onclick={() => {
											conversionPendingDelete = conversion;
											deleteDialogOpen = true;
										}}
									>
										<Trash2Icon class="size-4" />
										Delete
									</Button>
								</div>
							</Card.Content>
						</Card.Root>
					{/each}
				</div>

				<div class="hidden sm:block">
					<Table.Root>
						<Table.Header>
							<Table.Row>
								<Table.Head>File name</Table.Head>
								<Table.Head>Status</Table.Head>
								<Table.Head>Uploaded</Table.Head>
								<Table.Head>Exports</Table.Head>
								<Table.Head class="text-right">Actions</Table.Head>
							</Table.Row>
						</Table.Header>
						<Table.Body>
							{#each filteredConversions as conversion (conversion.id)}
								<Table.Row>
									<Table.Cell>
										<div class="space-y-1">
											<p class="font-medium">{conversion.original_filename}</p>
											{#if conversion.error_message}
												<p class="text-xs text-destructive">{conversion.error_message}</p>
											{/if}
										</div>
									</Table.Cell>
									<Table.Cell>
										<Badge variant={statusVariant(conversion.status)} class="capitalize">
											{#if conversion.status === 'processing'}
												<Loader2Icon class="mr-1 size-3.5 animate-spin" />
											{/if}
											{conversion.status}
										</Badge>
									</Table.Cell>
									<Table.Cell class="text-muted-foreground"
										>{formatDate(conversion.created_at)}</Table.Cell
									>
									<Table.Cell>
										<div class="flex flex-wrap gap-2">
											<Button
												variant="outline"
												size="sm"
												disabled={!conversion.source_download_url}
												onclick={() => openDownload(conversion.source_download_url)}
											>
												PDF
											</Button>
											<Button
												variant="outline"
												size="sm"
												disabled={!conversion.download_url}
												onclick={() => openDownload(conversion.download_url)}
											>
												CSV
											</Button>
											<Button
												variant="outline"
												size="sm"
												disabled={!conversion.json_download_url}
												onclick={() => openDownload(conversion.json_download_url)}
											>
												JSON
											</Button>
										</div>
									</Table.Cell>
									<Table.Cell class="text-right">
										<div class="flex justify-end gap-2">
											<Button
												variant="outline"
												size="sm"
												disabled={conversion.status === 'pending' ||
													conversion.status === 'processing'}
												onclick={() => openPreview(conversion)}
											>
												<EyeIcon class="size-4" />
												Preview
											</Button>
											<Button
												variant="ghost"
												size="sm"
												disabled={conversion.status === 'pending' ||
													conversion.status === 'processing'}
												class="text-destructive hover:text-destructive"
												onclick={() => {
													conversionPendingDelete = conversion;
													deleteDialogOpen = true;
												}}
											>
												<Trash2Icon class="size-4" />
												Delete
											</Button>
										</div>
									</Table.Cell>
								</Table.Row>
							{/each}
						</Table.Body>
					</Table.Root>
				</div>
			{/if}
		</Card.Content>
	</Card.Root>
</div>

<Dialog.Root bind:open={previewDialogOpen}>
	<Dialog.Content
		class="flex h-[calc(100vh-0.75rem)] w-[calc(100vw-0.75rem)] !max-w-[calc(100vw-0.75rem)] flex-col gap-1.5 overflow-hidden p-3 sm:h-[min(92vh,1100px)] sm:w-[min(96vw,1680px)] sm:!max-w-[min(96vw,1680px)] sm:gap-2 sm:p-5"
	>
		{#if previewLoading}
			<div class="py-8 text-sm text-muted-foreground">Loading preview…</div>
		{:else if previewConversion}
			<Dialog.Header class="shrink-0 gap-1 pr-10">
				<Dialog.Title>{previewConversion.original_filename || 'Preview conversion'}</Dialog.Title>
				<Dialog.Description>Edit rows before downloading updated exports.</Dialog.Description>
			</Dialog.Header>

			<div class="min-h-0 min-w-0 flex-1 overflow-auto rounded-lg border">
				<div class="w-full min-w-0">
					<Table.Root class="table-fixed">
						<Table.Header>
							<Table.Row>
								{#each previewConversion.preview_headers as header, headerIndex (header)}
									<Table.Head
										class={previewColumnClass(
											headerIndex,
											previewConversion.preview_headers.length
										)}
									>
										{header}
									</Table.Head>
								{/each}
								<Table.Head
									class="sticky top-0 z-10 w-12 border-b bg-background/95 px-1.5 py-2 text-right text-xs backdrop-blur supports-[backdrop-filter]:bg-background/85 sm:w-14 sm:px-2 sm:text-sm"
								>
									Row
								</Table.Head>
							</Table.Row>
						</Table.Header>
						<Table.Body>
							{#each editableRows as row, rowIndex (rowIndex)}
								<Table.Row>
									{#each row as cell, cellIndex (cellIndex)}
										<Table.Cell class={previewCellClass(cellIndex)}>
											<Input
												class={previewInputClass(cellIndex)}
												value={cell}
												oninput={(event) =>
													updateCell(
														rowIndex,
														cellIndex,
														(event.currentTarget as HTMLInputElement).value
													)}
											/>
										</Table.Cell>
									{/each}
									<Table.Cell class="p-1.5 text-right sm:p-2">
										<Button
											variant="ghost"
											size="icon-sm"
											onclick={() => removePreviewRow(rowIndex)}
										>
											<Trash2Icon class="size-4" />
										</Button>
									</Table.Cell>
								</Table.Row>
							{/each}
						</Table.Body>
					</Table.Root>
				</div>
			</div>
		{/if}
	</Dialog.Content>
</Dialog.Root>

<AlertDialog.Root bind:open={deleteDialogOpen}>
	<AlertDialog.Content>
		<AlertDialog.Header>
			<AlertDialog.Title>Delete this conversion?</AlertDialog.Title>
			<AlertDialog.Description>
				This removes the original PDF and generated exports from your history.
			</AlertDialog.Description>
		</AlertDialog.Header>
		<AlertDialog.Footer>
			<AlertDialog.Cancel>Cancel</AlertDialog.Cancel>
			<AlertDialog.Action onclick={confirmDeleteConversion}>Delete</AlertDialog.Action>
		</AlertDialog.Footer>
	</AlertDialog.Content>
</AlertDialog.Root>
