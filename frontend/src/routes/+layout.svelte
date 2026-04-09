<script lang="ts">
	import './layout.css';
	import favicon from '$lib/assets/favicon.svg';
	import { Toaster } from '$lib/components/ui/sonner';

	let { children } = $props();
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
	<title>Bank Statement Convert</title>
	<meta
		name="description"
		content="Convert bank statements into CSV files with Google auth and AI-assisted backend processing."
	/>
</svelte:head>

{@render children()}
<Toaster position="top-right" />
