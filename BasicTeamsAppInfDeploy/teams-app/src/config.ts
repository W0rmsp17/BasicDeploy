const apiBaseUrlFromEnv = import.meta.env.VITE_API_BASE_URL as string | undefined;
const functionKeyFromEnv = import.meta.env.VITE_FUNCTION_KEY as string | undefined;

export type RuntimeConfig = {
  apiBaseUrl: string;
  functionKey: string;
};

const storageKey = "m365-onboarding-teams-config";

export function loadRuntimeConfig(): RuntimeConfig {
  const url = new URL(window.location.href);
  const queryApiBaseUrl = url.searchParams.get("apiBaseUrl");
  const queryFunctionKey = url.searchParams.get("functionKey");
  const saved = readSavedConfig();

  return {
    apiBaseUrl: queryApiBaseUrl ?? saved?.apiBaseUrl ?? apiBaseUrlFromEnv ?? "",
    functionKey: queryFunctionKey ?? saved?.functionKey ?? functionKeyFromEnv ?? ""
  };
}

export function saveRuntimeConfig(config: RuntimeConfig): void {
  window.localStorage.setItem(storageKey, JSON.stringify(config));
}

function readSavedConfig(): RuntimeConfig | null {
  const raw = window.localStorage.getItem(storageKey);
  if (!raw) {
    return null;
  }

  try {
    return JSON.parse(raw) as RuntimeConfig;
  } catch {
    return null;
  }
}
