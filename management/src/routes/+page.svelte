<script lang="ts">
	import { onMount } from "svelte";
	import { apiFetch } from "$lib/api";

	type User = { id: number; email: string; name: string };

	let users = $state<User[]>([]);
	let error = $state<string | null>(null);
	let loading = $state(true);

	onMount(async () => {
		try {
			users = await apiFetch<User[]>("/users");
		} catch (e) {
			error = e instanceof Error ? e.message : "Failed to load users";
		} finally {
			loading = false;
		}
	});
</script>

<main class="mx-auto max-w-2xl p-8">
	<h1 class="text-2xl font-semibold">Management Console</h1>

	{#if loading}
		<p class="mt-4 text-gray-500">Loading users…</p>
	{:else if error}
		<p class="mt-4 text-red-600">{error}</p>
	{:else}
		<ul class="mt-4 space-y-2">
			{#each users as user (user.id)}
				<li class="rounded border p-3">{user.name} &lt;{user.email}&gt;</li>
			{:else}
				<li class="text-gray-500">No users yet.</li>
			{/each}
		</ul>
	{/if}
</main>
