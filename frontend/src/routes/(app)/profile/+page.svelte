<script lang="ts">
	import CheckIcon from '@lucide/svelte/icons/check';
	import CopyIcon from '@lucide/svelte/icons/copy';
	import KeyRoundIcon from '@lucide/svelte/icons/key-round';
	import TerminalSquareIcon from '@lucide/svelte/icons/terminal-square';
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { onMount } from 'svelte';
	import { toast } from 'svelte-sonner';
	import * as AlertDialog from '$lib/components/ui/alert-dialog';
	import { Button } from '$lib/components/ui/button';
	import * as Card from '$lib/components/ui/card';
	import { ScrollArea } from '$lib/components/ui/scroll-area';
	import * as Select from '$lib/components/ui/select';
	import { currentUser } from '$lib/session';
	import { destroyAccount, signOut } from '$lib/session';
	import { fetchProfile } from '$lib/api';
	import type { CodeSamples } from '$lib/types';

	let deleteAccountOpen = $state(false);
	let codeSamples = $state<CodeSamples>({});
	let codeTab = $state('curl');
	let profileLoading = $state(true);
	let copiedKey = $state(false);
	let copiedSample = $state<string | null>(null);
	let highlightedCode = $derived(highlightCode(codeTab, codeSamples[codeTab] ?? ''));

	const codeTabs = [
		{ key: 'curl', label: 'cURL' },
		{ key: 'typescript', label: 'TypeScript' },
		{ key: 'javascript', label: 'JavaScript' },
		{ key: 'python', label: 'Python' },
		{ key: 'ruby', label: 'Ruby' },
		{ key: 'go', label: 'Go' },
		{ key: 'php', label: 'PHP' },
		{ key: 'response_json', label: 'Response JSON' }
	];

	onMount(() => {
		void loadProfile();
	});

	async function loadProfile() {
		try {
			const payload = await fetchProfile();
			currentUser.set(payload.user);
			codeSamples = payload.code_samples;
		} catch (error) {
			console.error(error);
			toast.error('Could not load profile details.');
		} finally {
			profileLoading = false;
		}
	}

	async function copyText(value: string, type: 'key' | 'sample', sampleKey?: string) {
		try {
			await navigator.clipboard.writeText(value);

			if (type === 'key') {
				copiedKey = true;
				setTimeout(() => {
					copiedKey = false;
				}, 1500);
			} else if (sampleKey) {
				copiedSample = sampleKey;
				setTimeout(() => {
					if (copiedSample === sampleKey) copiedSample = null;
				}, 1500);
			}
		} catch (error) {
			console.error(error);
			toast.error('Could not copy to clipboard.');
		}
	}

	async function handleSignOut() {
		try {
			await signOut();
			await goto(resolve('/'));
		} catch (error) {
			console.error(error);
			toast.error('Could not sign out.');
		}
	}

	async function handleDeleteAccount() {
		try {
			await destroyAccount();
			deleteAccountOpen = false;
			await goto(resolve('/'));
		} catch (error) {
			console.error(error);
			toast.error('Could not delete account.');
		}
	}

	function highlightCode(sampleKey: string, code: string) {
		const patterns =
			sampleKey === 'response_json'
				? [
						{ regex: /"(?:[^"\\]|\\.)*"(?=\s*:)/g, className: 'text-sky-700' },
						{ regex: /"(?:[^"\\]|\\.)*"/g, className: 'text-emerald-700' },
						{ regex: /\b(?:null|true|false)\b/g, className: 'text-fuchsia-700' },
						{ regex: /\b\d+(?:\.\d+)?\b/g, className: 'text-amber-700' }
					]
				: [
						{
							regex:
								/\b(?:curl|const|await|fetch|import|require|print|puts|package|func|echo|response|headers|files|method|body)\b/g,
							className: 'text-sky-700'
						},
						{ regex: /https?:\/\/[^\s"'`]+/g, className: 'text-emerald-700' },
						{ regex: /"(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'/g, className: 'text-emerald-700' }
					];

		return code.split('\n').map((line) => {
			const matches = patterns
				.flatMap(({ regex, className }) =>
					Array.from(line.matchAll(regex), (match) => ({
						start: match.index ?? 0,
						end: (match.index ?? 0) + match[0].length,
						text: match[0],
						className
					}))
				)
				.sort((left, right) => left.start - right.start);

			const segments: Array<{ text: string; className?: string }> = [];
			let cursor = 0;

			for (const match of matches) {
				if (match.start < cursor) continue;
				if (match.start > cursor) {
					segments.push({ text: line.slice(cursor, match.start) });
				}
				segments.push({ text: match.text, className: match.className });
				cursor = match.end;
			}

			if (cursor < line.length) {
				segments.push({ text: line.slice(cursor) });
			}

			return segments.length ? segments : [{ text: '' }];
		});
	}
</script>

<div class="mx-auto max-w-4xl space-y-6">
	<Card.Root class="gap-0 py-0">
		<Card.Content class="space-y-4 px-4 py-4 sm:px-5 sm:py-5">
			<div class="space-y-1">
				<p class="text-sm font-medium">Name</p>
				<p class="text-sm text-muted-foreground">{$currentUser?.name}</p>
			</div>
			<div class="space-y-1">
				<p class="text-sm font-medium">Email</p>
				<p class="text-sm text-muted-foreground">{$currentUser?.email}</p>
			</div>
		</Card.Content>
		<Card.Footer
			class="flex-col items-stretch gap-2 border-t px-4 py-4 sm:flex-row sm:justify-end sm:px-5 sm:py-5"
		>
			<Button variant="outline" onclick={handleSignOut}>Sign out</Button>
			<Button variant="destructive" onclick={() => (deleteAccountOpen = true)}
				>Delete account</Button
			>
		</Card.Footer>
	</Card.Root>

	<Card.Root class="gap-0 py-0">
		<Card.Header class="gap-2 px-4 py-4 sm:px-5 sm:py-5">
			<div class="flex items-center gap-2">
				<KeyRoundIcon class="size-4" />
				<Card.Title class="text-base">API key</Card.Title>
			</div>
		</Card.Header>
		<Card.Content class="px-4 pb-4 sm:px-5 sm:pb-5">
			<div class="overflow-hidden rounded-xl border bg-muted/20">
				<div class="flex items-center justify-between gap-3 border-b bg-muted/40 px-4 py-3">
					<p class="text-xs font-medium tracking-[0.14em] text-muted-foreground uppercase">
						Bearer token
					</p>
					<Button
						variant="secondary"
						size="sm"
						disabled={profileLoading || !$currentUser?.api_key}
						onclick={() => $currentUser?.api_key && copyText($currentUser.api_key, 'key')}
					>
						{#if copiedKey}
							<CheckIcon class="size-4" />
							Copied
						{:else}
							<CopyIcon class="size-4" />
							Copy
						{/if}
					</Button>
				</div>
				<div class="overflow-x-auto px-4 py-4">
					<code class="block min-w-max font-mono text-sm text-foreground sm:text-[0.95rem]">
						{profileLoading ? 'Loading...' : ($currentUser?.api_key ?? 'Unavailable')}
					</code>
				</div>
			</div>
		</Card.Content>
	</Card.Root>

	<Card.Root class="gap-0 py-0">
		<Card.Header class="gap-2 px-4 py-4 sm:px-5 sm:py-5">
			<div class="flex items-center gap-2">
				<TerminalSquareIcon class="size-4" />
				<Card.Title class="text-base">API examples</Card.Title>
			</div>
		</Card.Header>
		<Card.Content class="space-y-4 px-4 pb-4 sm:px-5 sm:pb-5">
			<div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
				<Select.Root type="single" bind:value={codeTab}>
					<Select.Trigger class="w-full sm:w-56">
						{codeTabs.find((tab) => tab.key === codeTab)?.label ?? 'Select language'}
					</Select.Trigger>
					<Select.Content>
						{#each codeTabs as tab (tab.key)}
							<Select.Item value={tab.key} label={tab.label}>{tab.label}</Select.Item>
						{/each}
					</Select.Content>
				</Select.Root>
			</div>

			<div class="overflow-hidden rounded-xl border bg-zinc-50">
				<div class="flex items-center justify-between gap-3 border-b bg-zinc-100/80 px-4 py-3">
					<div class="text-xs font-medium tracking-[0.14em] text-zinc-500 uppercase">
						{codeTabs.find((tab) => tab.key === codeTab)?.label}
					</div>
					<Button
						variant="secondary"
						size="sm"
						disabled={!codeSamples[codeTab]}
						onclick={() =>
							codeSamples[codeTab] && copyText(codeSamples[codeTab], 'sample', codeTab)}
					>
						{#if copiedSample === codeTab}
							<CheckIcon class="size-4" />
							Copied
						{:else}
							<CopyIcon class="size-4" />
							Copy
						{/if}
					</Button>
				</div>
				<ScrollArea class="w-full">
					<div class="w-max min-w-full px-4 py-4">
						<pre class="m-0 font-mono text-[13px] leading-6 text-zinc-900 sm:text-sm"><code
								>{#each highlightedCode as line, lineIndex (lineIndex)}{#each line as segment, segmentIndex (`${lineIndex}-${segmentIndex}-${segment.text}`)}<span
											class={segment.className}>{segment.text}</span
										>{/each}{#if lineIndex < highlightedCode.length - 1}<br />{/if}{/each}</code
							></pre>
					</div>
				</ScrollArea>
			</div>
		</Card.Content>
	</Card.Root>
</div>

<AlertDialog.Root bind:open={deleteAccountOpen}>
	<AlertDialog.Content>
		<AlertDialog.Header>
			<AlertDialog.Title class="text-destructive">Delete account?</AlertDialog.Title>
			<AlertDialog.Description>
				This removes your profile, conversion history, uploaded PDFs, generated exports, and API
				access.
			</AlertDialog.Description>
		</AlertDialog.Header>
		<AlertDialog.Footer>
			<AlertDialog.Cancel>Cancel</AlertDialog.Cancel>
			<AlertDialog.Action variant="destructive" onclick={handleDeleteAccount}>
				Delete account
			</AlertDialog.Action>
		</AlertDialog.Footer>
	</AlertDialog.Content>
</AlertDialog.Root>
