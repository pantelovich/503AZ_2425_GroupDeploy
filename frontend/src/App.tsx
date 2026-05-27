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

type PublicSummary = {
  service: string;
  status: string;
  source: string;
  public_records: PublicRecord[];
  personnel_records: string;
  operational_log_details: string;
};

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL || '';

function App() {
  const [summary, setSummary] = useState<PublicSummary | null>(null);
  const [error, setError] = useState('');
  const [note, setNote] = useState('');
  const [saveStatus, setSaveStatus] = useState('');

  useEffect(() => {
    async function loadSummary() {
      if (!apiBaseUrl) {
        setError('API URL is not configured.');
        return;
      }

      try {
        const response = await fetch(`${apiBaseUrl}/public-summary`);
        if (!response.ok) throw new Error(`API returned ${response.status}`);
        setSummary(await response.json());
      } catch (err) {
        setError(err instanceof Error ? err.message : 'Could not load summary.');
      }
    }

    loadSummary();
  }, []);

  async function saveOperatorNote() {
    setSaveStatus('');
    const cleanNote = note.trim();
    if (!cleanNote) return;

    try {
      const session = await fetchAuthSession();
      const token = session.tokens?.idToken?.toString();

      const response = await fetch(`${apiBaseUrl}/operator-notes`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ note: cleanNote })
      });

      if (!response.ok) throw new Error(`Save failed with ${response.status}`);
      setNote('');
      setSaveStatus('Saved to DynamoDB');
    } catch (err) {
      setSaveStatus(err instanceof Error ? err.message : 'Could not save note.');
    }
  }

  return (
    <main className="shell">
      <header className="topbar">
        <div>
          <p className="eyebrow">CivicNexus serverless add-on</p>
          <h1>Operator console</h1>
        </div>
      </header>

      <section className="workspace">
        <div className="data-panel">
          <div className="section-title">
            <h2>Public city data</h2>
            <p>Operational signals only. Personnel and detailed logs stay restricted.</p>
          </div>
          {error && <p className="status error">{error}</p>}
          {!summary && !error && <p className="status">Loading live summary...</p>}
          {summary && (
            <>
              <div className="meta-row">
                <span>API: {summary.status}</span>
                <span>Source: {summary.source}</span>
                <span>Personnel: {summary.personnel_records}</span>
              </div>
              <div className="records">
                {summary.public_records.map((record) => (
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
            <p>Cognito sign-in required before a note can be stored.</p>
          </div>
          <Authenticator>
            {({ signOut }) => (
              <div className="operator-form">
                <p className="status">Signed in. Notes are written to DynamoDB.</p>
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
            )}
          </Authenticator>
        </aside>
      </section>
    </main>
  );
}

export default App;
