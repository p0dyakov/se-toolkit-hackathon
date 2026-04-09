<script lang="ts">
	import { page } from '$app/state';
	import { Button } from '$lib/components/ui/button';
	import * as Card from '$lib/components/ui/card';

	const message = $derived(page.url.searchParams.get('message') || 'Authentication failed.');
</script>

<div class="mx-auto flex min-h-screen max-w-lg items-center px-4">
	<Card.Root class="w-full">
		<Card.Header>
			<Card.Title>Could not sign in</Card.Title>
			<Card.Description>{message}</Card.Description>
		</Card.Header>
		<Card.Content>
			<Button href="/">Back to home</Button>
		</Card.Content>
	</Card.Root>
</div>
