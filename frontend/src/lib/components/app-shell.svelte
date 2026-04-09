<script lang="ts">
	import { resolve } from '$app/paths';
	import { page } from '$app/state';
	import { cn } from '$lib/utils';

	let { children } = $props();

	const navigation = [
		{ href: '/convert', label: 'Convert' },
		{ href: 'https://docs.statementconverter.ru', label: 'Docs', external: true },
		{ href: '/profile', label: 'Profile' }
	];

	function isActive(pathname: string, href: string) {
		return pathname === href;
	}
</script>

<div class="min-h-screen bg-background">
	<header class="border-b bg-background">
		<div class="mx-auto flex h-14 max-w-6xl items-center justify-between gap-3 px-3 sm:px-6">
			<a href={resolve('/convert')} class="text-sm font-semibold text-foreground">
				<span class="sm:hidden">BSC</span>
				<span class="hidden sm:inline">Bank Statement Convert</span>
			</a>

			<nav class="flex items-center gap-1 overflow-x-auto">
				{#each navigation as item (item.href)}
					{#if item.external}
						<a
							href={item.href}
							target="_blank"
							rel="noopener noreferrer"
							class="inline-flex h-9 shrink-0 items-center rounded-md px-2.5 text-sm font-medium text-foreground transition-colors hover:bg-muted sm:px-3"
						>
							{item.label}
						</a>
					{:else}
						<a
							href={resolve(item.href as '/convert' | '/profile')}
							aria-current={isActive(page.url.pathname, item.href) ? 'page' : undefined}
							class={cn(
								'inline-flex h-9 shrink-0 items-center rounded-md px-2.5 text-sm font-medium transition-colors sm:px-3',
								isActive(page.url.pathname, item.href)
									? 'bg-muted text-foreground'
									: 'text-muted-foreground hover:bg-muted hover:text-foreground'
							)}
						>
							{item.label}
						</a>
					{/if}
				{/each}
			</nav>
		</div>
	</header>

	<main class="mx-auto w-full max-w-6xl px-4 py-8 sm:px-6">
		{@render children()}
	</main>
</div>
