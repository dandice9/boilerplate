import { browser } from "$app/environment";
import { apiFetch } from "./api";

export type AuthUser = {
  id: number;
  email: string;
  name: string;
  role: "management";
  createdAt: string;
  updatedAt: string;
};

const STORAGE_KEY = "management_auth_token";
const ROLE = "management" as const;

class AuthStore {
  token = $state<string | null>(null);
  user = $state<AuthUser | null>(null);
  loading = $state(true);

  constructor() {
    if (browser) {
      this.token = localStorage.getItem(STORAGE_KEY);
      this.refresh();
    } else {
      this.loading = false;
    }
  }

  async refresh() {
    if (!this.token) {
      this.loading = false;
      return;
    }

    try {
      const { user } = await apiFetch<{ user: AuthUser }>("/auth/me", {
        headers: { Authorization: `Bearer ${this.token}` },
      });
      this.user = user;
    } catch {
      this.clear();
    } finally {
      this.loading = false;
    }
  }

  async login(email: string, password: string) {
    const { token, user } = await apiFetch<{ token: string; user: AuthUser }>("/auth/login", {
      method: "POST",
      body: JSON.stringify({ email, password, role: ROLE }),
    });
    this.setSession(token, user);
  }

  async register(email: string, password: string, name: string) {
    const { token, user } = await apiFetch<{ token: string; user: AuthUser }>("/auth/register", {
      method: "POST",
      body: JSON.stringify({ email, password, name, role: ROLE }),
    });
    this.setSession(token, user);
  }

  async logout() {
    if (this.token) {
      try {
        await apiFetch("/auth/logout", {
          method: "POST",
          headers: { Authorization: `Bearer ${this.token}` },
        });
      } catch {
        // token may already be invalid/expired — clearing locally is enough
      }
    }
    this.clear();
  }

  private setSession(token: string, user: AuthUser) {
    this.token = token;
    this.user = user;
    if (browser) localStorage.setItem(STORAGE_KEY, token);
  }

  private clear() {
    this.token = null;
    this.user = null;
    if (browser) localStorage.removeItem(STORAGE_KEY);
  }
}

export const auth = new AuthStore();
