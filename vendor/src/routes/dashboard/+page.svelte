<script lang="ts">
	import { goto } from "$app/navigation";
	import { auth } from "$lib/auth.svelte";

	$effect(() => {
		if (!auth.loading && !auth.user) {
			goto("/login");
		}
	});

	async function handleLogout() {
		await auth.logout();
		await goto("/login");
	}
</script>

{#if auth.loading}
	<main class="flex min-h-screen items-center justify-center">
		<p class="text-gray-500">Loading…</p>
	</main>
{:else if auth.user}
	<main class="mx-auto max-w-2xl p-8">
		<div class="flex items-center justify-between">
			<h1 class="text-2xl font-semibold">Vendor dashboard</h1>
			<button onclick={handleLogout} class="rounded border px-3 py-1.5 text-sm">Logout</button>
		</div>

		<p class="mt-2 text-gray-600">
			Signed in as <strong>{auth.user.name}</strong> ({auth.user.email})
		</p>

		<dl class="mt-8 grid grid-cols-2 gap-4 text-sm">
			<div class="rounded border p-4">
				<dt class="text-gray-500">Role</dt>
				<dd class="mt-1 font-medium">{auth.user.role}</dd>
			</div>
			<div class="rounded border p-4">
				<dt class="text-gray-500">Member since</dt>
				<dd class="mt-1 font-medium">{new Date(auth.user.createdAt).toLocaleDateString()}</dd>
			</div>
		</dl>
	</main>
{/if}
