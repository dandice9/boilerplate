<script lang="ts">
	import { goto } from "$app/navigation";
	import { auth } from "$lib/auth.svelte";
	import { ApiError } from "$lib/api";

	let email = $state("");
	let password = $state("");
	let error = $state<string | null>(null);
	let submitting = $state(false);

	async function handleSubmit(e: SubmitEvent) {
		e.preventDefault();
		error = null;
		submitting = true;
		try {
			await auth.login(email, password);
			await goto("/dashboard");
		} catch (err) {
			error = err instanceof ApiError ? err.message : "Login failed";
		} finally {
			submitting = false;
		}
	}
</script>

<main class="mx-auto max-w-sm p-8">
	<h1 class="text-2xl font-semibold">Vendor sign in</h1>

	<form class="mt-6 space-y-4" onsubmit={handleSubmit}>
		<div>
			<label for="email" class="block text-sm font-medium">Email</label>
			<input id="email" type="email" required bind:value={email} class="mt-1 w-full rounded border p-2" />
		</div>
		<div>
			<label for="password" class="block text-sm font-medium">Password</label>
			<input
				id="password"
				type="password"
				required
				bind:value={password}
				class="mt-1 w-full rounded border p-2"
			/>
		</div>

		{#if error}
			<p class="text-sm text-red-600">{error}</p>
		{/if}

		<button
			type="submit"
			disabled={submitting}
			class="w-full rounded bg-gray-900 p-2 text-white disabled:opacity-50"
		>
			{submitting ? "Signing in…" : "Sign in"}
		</button>
	</form>

	<p class="mt-4 text-sm text-gray-500">
		No account? <a href="/register" class="underline">Register</a>
	</p>
</main>
