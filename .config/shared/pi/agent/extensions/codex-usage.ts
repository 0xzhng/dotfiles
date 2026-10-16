import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const WIDGET = "codex-usage";
const USAGE_URL = "https://chatgpt.com/backend-api/wham/usage";

function object(value: unknown): Record<string, unknown> {
	return typeof value === "object" && value !== null ? value as Record<string, unknown> : {};
}

function formatWindow(value: unknown): string | undefined {
	const window = object(value);
	const used = window.used_percent;
	const seconds = window.limit_window_seconds;
	const reset = window.reset_at;
	if (typeof used !== "number" || !Number.isFinite(used) || used < 0 || used > 100 ||
		typeof seconds !== "number" || !Number.isSafeInteger(seconds) || seconds <= 0 ||
		typeof reset !== "number" || !Number.isFinite(reset) || reset <= 0) return;
	const date = new Date(reset * 1000);
	if (!Number.isFinite(date.getTime())) return;
	const label = seconds === 604800 ? "Weekly" : seconds % 3600 === 0 ? `${seconds / 3600}h` : `${seconds}s`;
	return `Codex ${label}: ${Math.round(100 - used)}% left · reset ${date.toLocaleString([], {
		month: "short", day: "numeric", hour: "2-digit", minute: "2-digit",
	})}`;
}

export default function codexUsage(pi: ExtensionAPI) {
	let timer: ReturnType<typeof setInterval> | undefined;
	let activeCtx: ExtensionContext | undefined;
	let controller: AbortController | undefined;
	let generation = 0;

	function clear(ctx: ExtensionContext) {
		if (ctx.hasUI) ctx.ui.setWidget(WIDGET, undefined);
	}

	async function refresh(ctx: ExtensionContext) {
		const request = ++generation;
		controller?.abort();
		clear(ctx);
		const model = ctx.model;
		if (ctx.mode !== "tui" || !ctx.hasUI || model?.provider !== "openai-codex" ||
			!ctx.modelRegistry.isUsingOAuth(model)) return;
		const abort = new AbortController();
		controller = abort;
		try {
			const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
			if (request !== generation || !auth.ok || !auth.apiKey) return;
			// Codex's request adapter also takes the account ID from this OAuth JWT claim.
			const claim = object(JSON.parse(Buffer.from(auth.apiKey.split(".")[1] ?? "", "base64url").toString()));
			const accountId = object(claim["https://api.openai.com/auth"]).chatgpt_account_id;
			if (typeof accountId !== "string" || !accountId) return;
			const response = await fetch(USAGE_URL, {
				headers: { Authorization: `Bearer ${auth.apiKey}`, "chatgpt-account-id": accountId },
				redirect: "error",
				signal: AbortSignal.any([abort.signal, AbortSignal.timeout(15_000)]),
			});
			if (!response.ok) return;
			const payload: unknown = await response.json();
			const limits = object(object(payload).rate_limit);
			const lines = [formatWindow(limits.primary_window), formatWindow(limits.secondary_window)]
				.filter((line): line is string => line !== undefined);
			if (request === generation && lines.length) ctx.ui.setWidget(WIDGET, lines);
		} catch {
			// Unavailable usage stays hidden; never show invented zeros or stale limits.
		}
	}

	function stop() {
		if (timer) clearInterval(timer);
		timer = undefined;
		generation++;
		controller?.abort();
		controller = undefined;
		if (activeCtx) clear(activeCtx);
		activeCtx = undefined;
	}

	pi.on("session_start", async (_event, ctx) => {
		stop();
		activeCtx = ctx;
		timer = setInterval(() => { if (activeCtx) void refresh(activeCtx); }, 60_000);
		await refresh(ctx);
	});
	pi.on("model_select", async (_event, ctx) => {
		activeCtx = ctx;
		await refresh(ctx);
	});
	pi.on("session_shutdown", async () => { stop(); });
}
