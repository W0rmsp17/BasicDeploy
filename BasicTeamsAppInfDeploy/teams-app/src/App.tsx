import { FormEvent, useMemo, useState } from "react";
import { AlertCircle, CheckCircle2, ClipboardList, Save, Send, Settings } from "lucide-react";
import {
  type OnboardingFormState,
  type SubmitOnboardingResponse,
  submitOnboardingRequest
} from "./api";
import { loadRuntimeConfig, saveRuntimeConfig, type RuntimeConfig } from "./config";

type AppProps = {
  isRunningInTeams: boolean;
};

const emptyForm: OnboardingFormState = {
  firstName: "",
  lastName: "",
  jobTitle: "",
  department: "",
  managerEmail: "",
  startDate: "",
  requestedProfile: "Standard",
  notes: ""
};

const profileOptions = ["Standard", "Operations", "Finance", "Field", "Executive"];

export function App({ isRunningInTeams }: AppProps) {
  const [form, setForm] = useState<OnboardingFormState>(emptyForm);
  const [config, setConfig] = useState<RuntimeConfig>(() => loadRuntimeConfig());
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [errorMessage, setErrorMessage] = useState("");
  const [response, setResponse] = useState<SubmitOnboardingResponse | null>(null);

  const previewUpn = useMemo(() => {
    const firstName = form.firstName.trim().toLowerCase();
    const lastName = form.lastName.trim().toLowerCase();
    if (!firstName || !lastName) {
      return "pending";
    }

    return `${firstName}.${lastName}`.replace(/[^a-z0-9._-]/g, "");
  }, [form.firstName, form.lastName]);

  function updateForm<K extends keyof OnboardingFormState>(key: K, value: OnboardingFormState[K]) {
    setForm((current) => ({
      ...current,
      [key]: value
    }));
  }

  function updateConfig<K extends keyof RuntimeConfig>(key: K, value: RuntimeConfig[K]) {
    setConfig((current) => ({
      ...current,
      [key]: value
    }));
  }

  function handleSaveConfig() {
    saveRuntimeConfig(config);
    setIsSettingsOpen(false);
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setIsSubmitting(true);
    setErrorMessage("");
    setResponse(null);

    try {
      const result = await submitOnboardingRequest(config, form);
      setResponse(result);
      setForm(emptyForm);
    } catch (error) {
      setErrorMessage(error instanceof Error ? error.message : "Request failed.");
    } finally {
      setIsSubmitting(false);
    }
  }

  return (
    <main className="app-shell">
      <header className="top-bar">
        <div>
          <div className="eyebrow">Microsoft 365</div>
          <h1>User onboarding</h1>
        </div>
        <div className="top-actions">
          <span className={isRunningInTeams ? "status-pill connected" : "status-pill"}>
            {isRunningInTeams ? "Teams" : "Browser"}
          </span>
          <button
            className="icon-button"
            type="button"
            title="Connection settings"
            aria-label="Connection settings"
            onClick={() => setIsSettingsOpen((value) => !value)}
          >
            <Settings size={18} />
          </button>
        </div>
      </header>

      {isSettingsOpen && (
        <section className="settings-panel" aria-label="Connection settings">
          <label>
            Function API base URL
            <input
              value={config.apiBaseUrl}
              onChange={(event) => updateConfig("apiBaseUrl", event.target.value)}
              placeholder="https://func-name.azurewebsites.net"
            />
          </label>
          <button className="secondary-button" type="button" onClick={handleSaveConfig}>
            <Save size={16} />
            Save
          </button>
        </section>
      )}

      <section className="summary-strip" aria-label="Request summary">
        <div>
          <span>UPN prefix</span>
          <strong>{previewUpn}</strong>
        </div>
        <div>
          <span>Profile</span>
          <strong>{form.requestedProfile}</strong>
        </div>
        <div>
          <span>Approval</span>
          <strong>Email workflow</strong>
        </div>
      </section>

      <form className="onboarding-form" onSubmit={handleSubmit}>
        <section className="form-section">
          <div className="section-title">
            <ClipboardList size={18} />
            <h2>Identity</h2>
          </div>
          <div className="field-grid two-columns">
            <label>
              First name
              <input
                value={form.firstName}
                onChange={(event) => updateForm("firstName", event.target.value)}
                autoComplete="given-name"
                required
              />
            </label>
            <label>
              Last name
              <input
                value={form.lastName}
                onChange={(event) => updateForm("lastName", event.target.value)}
                autoComplete="family-name"
                required
              />
            </label>
          </div>
        </section>

        <section className="form-section">
          <div className="section-title">
            <ClipboardList size={18} />
            <h2>Role</h2>
          </div>
          <div className="field-grid two-columns">
            <label>
              Job title
              <input value={form.jobTitle} onChange={(event) => updateForm("jobTitle", event.target.value)} />
            </label>
            <label>
              Department
              <input value={form.department} onChange={(event) => updateForm("department", event.target.value)} />
            </label>
            <label>
              Manager email
              <input
                value={form.managerEmail}
                onChange={(event) => updateForm("managerEmail", event.target.value)}
                inputMode="email"
                type="email"
              />
            </label>
            <label>
              Start date
              <input
                value={form.startDate}
                onChange={(event) => updateForm("startDate", event.target.value)}
                type="date"
              />
            </label>
          </div>
        </section>

        <section className="form-section">
          <div className="section-title">
            <ClipboardList size={18} />
            <h2>Access</h2>
          </div>
          <div className="field-grid">
            <label>
              Requested profile
              <select
                value={form.requestedProfile}
                onChange={(event) => updateForm("requestedProfile", event.target.value)}
              >
                {profileOptions.map((profile) => (
                  <option key={profile} value={profile}>
                    {profile}
                  </option>
                ))}
              </select>
            </label>
            <label>
              Notes
              <textarea value={form.notes} onChange={(event) => updateForm("notes", event.target.value)} rows={4} />
            </label>
          </div>
        </section>

        {errorMessage && (
          <div className="message error" role="alert">
            <AlertCircle size={18} />
            <span>{errorMessage}</span>
          </div>
        )}

        {response && (
          <div className="message success" role="status">
            <CheckCircle2 size={18} />
            <span>
              Request accepted for <strong>{response.userPrincipalName}</strong>.
            </span>
          </div>
        )}

        <div className="form-actions">
          <button className="primary-button" type="submit" disabled={isSubmitting}>
            <Send size={18} />
            {isSubmitting ? "Submitting" : "Submit request"}
          </button>
        </div>
      </form>
    </main>
  );
}
