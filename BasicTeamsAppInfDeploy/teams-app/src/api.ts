import type { RuntimeConfig } from "./config";

export type OnboardingFormState = {
  firstName: string;
  lastName: string;
  jobTitle: string;
  department: string;
  managerEmail: string;
  startDate: string;
  requestedProfile: string;
  notes: string;
};

export type SubmitOnboardingResponse = {
  id: string;
  status: number;
  userPrincipalName: string;
  approveUri: string;
  denyUri: string;
};

export async function submitOnboardingRequest(
  config: RuntimeConfig,
  form: OnboardingFormState
): Promise<SubmitOnboardingResponse> {
  if (!config.apiBaseUrl.trim()) {
    throw new Error("Function API base URL is required.");
  }

  const url = new URL("/api/onboarding-requests", normalizeBaseUrl(config.apiBaseUrl));

  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json"
    },
    body: JSON.stringify(toPayload(form))
  });

  const responseText = await response.text();
  if (!response.ok) {
    throw new Error(createErrorMessage(response.status, responseText));
  }

  return JSON.parse(responseText) as SubmitOnboardingResponse;
}

function toPayload(form: OnboardingFormState) {
  return {
    firstName: emptyToUndefined(form.firstName),
    lastName: emptyToUndefined(form.lastName),
    jobTitle: emptyToUndefined(form.jobTitle),
    department: emptyToUndefined(form.department),
    managerEmail: emptyToUndefined(form.managerEmail),
    startDate: emptyToUndefined(form.startDate),
    requestedProfile: emptyToUndefined(form.requestedProfile),
    notes: emptyToUndefined(form.notes)
  };
}

function normalizeBaseUrl(value: string): string {
  return value.endsWith("/") ? value : `${value}/`;
}

function emptyToUndefined(value: string): string | undefined {
  const trimmed = value.trim();
  return trimmed.length === 0 ? undefined : trimmed;
}

function createErrorMessage(statusCode: number, responseText: string): string {
  if (!responseText) {
    return `Request failed with HTTP ${statusCode}.`;
  }

  try {
    const payload = JSON.parse(responseText) as { errors?: string[]; error?: string };
    if (payload.errors?.length) {
      return payload.errors.join(" ");
    }

    if (payload.error) {
      return payload.error;
    }
  } catch {
    return `Request failed with HTTP ${statusCode}: ${responseText}`;
  }

  return `Request failed with HTTP ${statusCode}.`;
}
