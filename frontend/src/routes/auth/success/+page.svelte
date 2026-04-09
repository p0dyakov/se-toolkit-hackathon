<script lang="ts">
	import { goto } from '$app/navigation';
	import { resolve } from '$app/paths';
	import { onMount } from 'svelte';
	import { Skeleton } from '$lib/components/ui/skeleton';
	import * as Card from '$lib/components/ui/card';

	onMount(() => {
		void goto(resolve('/convert'));
	});
</script>

<div class="mx-auto flex min-h-screen max-w-lg items-center px-4">
	<Card.Root class="w-full">
		<Card.Header>
			<Card.Title>Finishing sign in</Card.Title>
			<Card.Description
				>The session cookie is already set. Redirecting back to the app.</Card.Description
			>
		</Card.Header>
		<Card.Content class="space-y-3">
			<Skeleton class="h-4 w-full rounded-full" />
			<Skeleton class="h-4 w-4/5 rounded-full" />
		</Card.Content>
	</Card.Root>
</div>
