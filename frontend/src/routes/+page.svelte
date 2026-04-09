<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { onMount } from 'svelte';
	import { googleAuthUrl } from '$lib/api';
	import LoginShaderBackground from '$lib/components/login-shader-background.svelte';
	import { Button } from '$lib/components/ui/button';
	import * as Card from '$lib/components/ui/card';
	import { hydrateSession, sessionLoading } from '$lib/session';

	onMount(() => {
		void (async () => {
			try {
				const user = await hydrateSession();

				if (user) {
					await goto(resolve('/convert'));
				}
			} catch {
				// Keep the login screen visible if the backend is unavailable.
			}
		})();
	});
</script>

<div
	class="relative flex min-h-screen items-center justify-center overflow-hidden bg-black px-4 py-10"
>
	<LoginShaderBackground />
	<div class="absolute inset-0 bg-black/45"></div>
	<div
		class="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_top,rgba(255,255,255,0.14),transparent_34%),radial-gradient(circle_at_bottom,rgba(255,255,255,0.08),transparent_30%)]"
	></div>

	<div class="relative z-10 w-full max-w-lg">
		<div class="pointer-events-none absolute inset-0 rounded-2xl bg-white/10 blur-3xl"></div>

		<Card.Root
			class="relative gap-0 overflow-hidden rounded-2xl border-white/15 bg-background/88 py-0 shadow-[0_30px_120px_rgba(0,0,0,0.45)] backdrop-blur-xl"
		>
			<div
				class="pointer-events-none absolute inset-0 bg-[linear-gradient(135deg,rgba(255,255,255,0.88),rgba(255,255,255,0.82))]"
			></div>
			<div
				class="pointer-events-none absolute inset-x-0 top-0 h-24 bg-[radial-gradient(circle_at_top,rgba(255,255,255,0.9),transparent_72%)]"
			></div>

			<Card.Header class="relative space-y-1.5 px-5 pt-5 pb-0 text-left sm:px-6 sm:pt-6 sm:pb-0">
				<Card.Title class="max-w-md text-2xl font-semibold tracking-tight text-balance sm:text-3xl">
					Bank Statement Convert
				</Card.Title>
				<Card.Description class="max-w-sm text-sm leading-5 text-balance sm:max-w-md sm:text-sm">
					Convert PDF bank statements into structured CSV.
				</Card.Description>
			</Card.Header>
			<Card.Content class="relative px-5 pt-5 pb-5 sm:px-6 sm:pt-6 sm:pb-6">
				<Button
					variant="outline"
					size="default"
					class="w-full justify-center gap-2 rounded-md"
					href={googleAuthUrl}
					disabled={$sessionLoading}
				>
					<svg viewBox="0 0 24 24" aria-hidden="true" class="size-4">
						<path
							fill="#4285F4"
							d="M21.6 12.23c0-.68-.06-1.33-.17-1.96H12v3.7h5.39a4.62 4.62 0 0 1-2 3.03v2.51h3.24c1.9-1.74 2.97-4.3 2.97-7.28Z"
						/>
						<path
							fill="#34A853"
							d="M12 22c2.7 0 4.96-.9 6.61-2.44l-3.24-2.5c-.9.6-2.05.95-3.37.95-2.59 0-4.79-1.75-5.57-4.1H3.08v2.58A9.98 9.98 0 0 0 12 22Z"
						/>
						<path
							fill="#FBBC05"
							d="M6.43 13.91A5.99 5.99 0 0 1 6.12 12c0-.66.11-1.3.31-1.91V7.5H3.08A9.98 9.98 0 0 0 2 12c0 1.61.39 3.13 1.08 4.5l3.35-2.59Z"
						/>
						<path
							fill="#EA4335"
							d="M12 5.98c1.47 0 2.79.51 3.83 1.5l2.87-2.87C16.95 2.98 14.69 2 12 2 8.08 2 4.7 4.26 3.08 7.5l3.35 2.59c.78-2.35 2.98-4.11 5.57-4.11Z"
						/>
					</svg>
					<span class="text-sm">Continue with Google</span>
				</Button>
			</Card.Content>
		</Card.Root>
	</div>
</div>
