<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { onMount } from 'svelte';
	import AppShell from '$lib/components/app-shell.svelte';
	import { currentUser, hydrateSession, sessionLoading } from '$lib/session';

	let { children } = $props();
	let ready = $state(false);

	onMount(() => {
		void (async () => {
			try {
				const user = await hydrateSession();

				if (!user) {
					await goto(resolve('/'));
					return;
				}
			} catch {
				await goto(resolve('/'));
				return;
			} finally {
				ready = true;
			}
		})();
	});
</script>

{#if $sessionLoading || !ready}
	<div class="flex min-h-screen items-center justify-center bg-background px-4">
		<p class="text-sm text-muted-foreground">Loading…</p>
	</div>
{:else if $currentUser}
	<AppShell>
		{@render children()}
	</AppShell>
{/if}
