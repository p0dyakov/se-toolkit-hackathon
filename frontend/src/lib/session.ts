import { get, writable } from 'svelte/store';
import { deleteAccount, deleteSession, fetchCurrentUser } from '$lib/api';
import type { User } from '$lib/types';

export const currentUser = writable<User | null>(null);
export const sessionLoading = writable(true);

let hydrationPromise: Promise<User | null> | null = null;

export async function hydrateSession(force = false) {
	if (force || !hydrationPromise) {
		sessionLoading.set(true);
		hydrationPromise = (async () => {
			try {
				const payload = await fetchCurrentUser();
				const user = payload?.user ?? null;
				currentUser.set(user);
				return user;
			} finally {
				sessionLoading.set(false);
			}
		})();
	}

	try {
		return await hydrationPromise;
	} catch (error) {
		hydrationPromise = null;
		currentUser.set(null);
		throw error;
	}
}

export async function signOut() {
	await deleteSession();
	hydrationPromise = Promise.resolve(null);
	currentUser.set(null);
	sessionLoading.set(false);
}

export async function destroyAccount() {
	await deleteAccount();
	hydrationPromise = Promise.resolve(null);
	currentUser.set(null);
	sessionLoading.set(false);
}

export function getSessionUser() {
	return get(currentUser);
}
