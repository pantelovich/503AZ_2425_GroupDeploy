import { useEffect, useState } from 'react';
import { Authenticator } from '@aws-amplify/ui-react';
import { fetchAuthSession } from 'aws-amplify/auth';

type PublicRecord = {
  id: string;
  dataType: string;
  location: string;
  reading: string;
  timestamp: string;
};

type ItemsResponse = {
  service: string;
  status: string;
  source: string;
  public_records: PublicRecord[];
  personnel_records: string;
  operational_log_details: string;
  operator_notes_count?: number;
  authenticated_operator?: string;
};

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || '';

async function authToken() {
  const session = await fetchAuthSession();
  const token = session.tokens?.idToken?.toString();
  if (!token) throw new Error('Cognito token was not available.');
  return token;
}

function AuthenticatedConsole({ signOut }: { signOut?: () => void }) {
  const [items, setItems] = useState<ItemsResponse | null>(null);
  const [error, setError] = useState('');
  const [note, setNote] = useState('');
  const [saveStatus, setSaveStatus] = useState('');

  async function loadItems() {
    if (!apiBaseUrl) {
      setError('API URL is not configured.');
      return;
    }

    try {
      const token = await authToken();
      const response = await fetch(`${apiBaseUrl}/items`, {
        headers: {
          Authorization: `Bearer ${token}`
        }
      });

      if (!response.ok) throw new Error(`API returned ${response.status}`);
      setItems(await response.json());
      setError('');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not load MongoDB data.');
    }
  }

  useEffect(() => {
    loadItems();
  }, []);

  async function saveOperatorNote() {
    setSaveStatus('');
    const cleanNote = note.trim();
    if (!cleanNote) return;

    try {
      const token = await authToken();
      const response = await fetch(`${apiBaseUrl}/items`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ note: cleanNote })
      });

      if (!response.ok) throw new Error(`Save failed with ${response.status}`);
      setNote('');
      setSaveStatus('Saved to MongoDB');
      await loadItems();
    } catch (err) {
      setSaveStatus(err instanceof Error ? err.message : 'Could not save note.');
    }
  }

  return (
    <section className="workspace">
      <div className="data-panel">
        <div className="section-title">
          <h2>Protected city data</h2>
          <p>Cognito authorises the API request. The API response is read from the private MongoDB stack.</p>
        </div>
        {error && <p className="status error">{error}</p>}
        {!items && !error && <p className="status">Loading MongoDB records...</p>}
        {items && (
          <>
            <div className="meta-row">
              <span>API: {items.status}</span>
              <span>Source: {items.source}</span>
              <span>Personnel: {items.personnel_records}</span>
              <span>Notes: {items.operator_notes_count ?? 0}</span>
            </div>
            <div className="records">
              {items.public_records.map((record) => (
                <div className="record" key={record.id}>
                  <div>
                    <strong>{record.location}</strong>
                    <small>{record.id}</small>
                  </div>
                  <span>{record.dataType.replace(/_/g, ' ')}</span>
                  <b>{record.reading}</b>
                  <time>{record.timestamp}</time>
                </div>
              ))}
            </div>
          </>
        )}
      </div>

      <aside className="operator-panel">
        <div className="section-title">
          <h2>Operator note</h2>
          <p>Notes are accepted only after Cognito sign-in and are stored in MongoDB.</p>
        </div>
        <div className="operator-form">
          <p className="status">Signed in as {items?.authenticated_operator || 'Cognito operator'}.</p>
          <textarea
            value={note}
            onChange={(event) => setNote(event.target.value)}
            maxLength={500}
            placeholder="Write a short operator note."
          />
          <div className="actions">
            <button onClick={saveOperatorNote}>Save note</button>
            <button className="secondary" onClick={signOut}>Sign out</button>
          </div>
          {saveStatus && <p className="status">{saveStatus}</p>}
        </div>
      </aside>
    </section>
  );
}

function App() {
  return (
    <main className="shell">
      <header className="topbar">
        <div>
          <p className="eyebrow">CivicNexus authenticated API</p>
          <h1>Operator console</h1>
        </div>
      </header>

      <section className="landing">
        <div>
          <h2>MongoDB is the only project database.</h2>
          <p>
            Sign in to call the Cognito-protected API. The API Gateway route uses JWT auth before Lambda
            reads and writes CivicNexus records through the private MongoDB-backed web tier.
          </p>
        </div>
      </section>

      <Authenticator>
        {({ signOut }) => <AuthenticatedConsole signOut={signOut} />}
      </Authenticator>
    </main>
  );
}

export default App;
