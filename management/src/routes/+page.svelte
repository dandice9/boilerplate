<script lang="ts">
	import { goto } from "$app/navigation";
	import { auth } from "$lib/auth.svelte";

	$effect(() => {
		if (!auth.loading) {
			goto(auth.user ? "/dashboard" : "/login", { replaceState: true });
		}
	});
</script>

<main class="flex min-h-screen items-center justify-center">
	<p class="text-gray-500">Loading…</p>
</main>
