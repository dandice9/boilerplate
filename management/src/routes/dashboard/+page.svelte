<script lang="ts">
	import { goto } from "$app/navigation";
	import { auth } from "$lib/auth.svelte";
	import { apiFetch, ApiError } from "$lib/api";

	type ManagedUser = { id: number; email: string; name: string; role: string; createdAt: string };

	let users = $state<ManagedUser[]>([]);
	let usersError = $state<string | null>(null);
	let loadingUsers = $state(false);
	let loadedFor = $state<string | null>(null);

	$effect(() => {
		if (!auth.loading && !auth.user) {
			goto("/login");
		}
	});

	$effect(() => {
		if (auth.user && auth.token && loadedFor !== auth.token) {
			loadedFor = auth.token;
			loadUsers();
		}
	});

	async function loadUsers() {
		loadingUsers = true;
		try {
			users = await apiFetch<ManagedUser[]>("/users", {
				headers: { Authorization: `Bearer ${auth.token}` },
			});
		} catch (err) {
			usersError = err instanceof ApiError ? err.message : "Failed to load users";
		} finally {
			loadingUsers = false;
		}
	}

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
			<h1 class="text-2xl font-semibold">Management dashboard</h1>
			<button onclick={handleLogout} class="rounded border px-3 py-1.5 text-sm">Logout</button>
		</div>

		<p class="mt-2 text-gray-600">
			Signed in as <strong>{auth.user.name}</strong> ({auth.user.email})
		</p>

		<h2 class="mt-8 text-lg font-medium">All accounts</h2>
		{#if loadingUsers}
			<p class="mt-2 text-gray-500">Loading users…</p>
		{:else if usersError}
			<p class="mt-2 text-red-600">{usersError}</p>
		{:else}
			<ul class="mt-2 space-y-2">
				{#each users as user (user.id)}
					<li class="rounded border p-3">
						{user.name} &lt;{user.email}&gt; <span class="text-xs text-gray-500">({user.role})</span>
					</li>
				{:else}
					<li class="text-gray-500">No users yet.</li>
				{/each}
			</ul>
		{/if}
	</main>
{/if}
