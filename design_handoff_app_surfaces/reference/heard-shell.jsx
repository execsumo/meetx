/* Heard — Settings shell + sidebar + auxiliary surfaces. */
/* eslint-disable */

const TABS = [
  { id: 'general', label: 'General', icon: 'gear' },
  { id: 'dictation', label: 'Dictation', icon: 'keyboard' },
  { id: 'models', label: 'Models', icon: 'cube' },
  { id: 'speakers', label: 'Speakers', icon: 'people' },
];

const Sidebar = ({ active, setActive, onAbout }) => (
  <div style={{
    width: 188, background: PAPER.sidebar,
    borderRight: `0.5px solid ${PAPER.border}`,
    display: 'flex', flexDirection: 'column', flexShrink: 0,
  }}>
    <div style={{ padding: '14px 12px 10px', display: 'flex', alignItems: 'center', gap: 9 }}>
      <HeardMark size={26}/>
      <div>
        <div style={{ fontSize: 12.5, fontWeight: 700, color: PAPER.ink, fontFamily: FONT_DISPLAY, letterSpacing: -0.2 }}>Heard</div>
        <div style={{ fontSize: 10, color: PAPER.mute, fontFamily: FONT_MONO }}>v0.1.0</div>
      </div>
    </div>
    <div style={{ padding: '0 8px', flex: 1, display: 'flex', flexDirection: 'column', gap: 2 }}>
      {TABS.map(t => {
        const sel = t.id === active;
        return (
          <button key={t.id} onClick={() => setActive(t.id)} style={{
            display: 'flex', alignItems: 'center', gap: 9,
            padding: '6px 9px', borderRadius: 6,
            background: sel ? PAPER.surface : 'transparent',
            border: 'none', cursor: 'pointer', textAlign: 'left',
            color: PAPER.ink,
            boxShadow: sel ? `0 0 0 0.5px ${PAPER.border}, 0 1px 2px ${PAPER.shadow}` : 'none',
            fontFamily: FONT_UI,
          }}>
            <Icon name={t.icon} size={13} color={sel ? PAPER.accent : PAPER.ink2}/>
            <span style={{ fontSize: 12.5, fontWeight: sel ? 600 : 500 }}>{t.label}</span>
          </button>
        );
      })}
    </div>
    <button onClick={onAbout} style={{
      margin: 8, padding: '8px 9px', borderRadius: 6,
      background: 'transparent', border: `0.5px solid ${PAPER.borderSoft}`,
      cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 8,
      color: PAPER.ink2, fontFamily: FONT_UI, fontSize: 11.5,
    }}>
      <Icon name="info" size={12} color={PAPER.mute}/>
      About Heard
      <span style={{ marginLeft: 'auto' }}><Icon name="chevron.right" size={10} color={PAPER.mute}/></span>
    </button>
  </div>
);

// ── Settings shell ──
const Settings = ({ initialTab = 'general', showAbout, setShowAbout }) => {
  const [active, setActive] = React.useState(initialTab);
  const [s, setS_] = React.useState({
    launchAtLogin: true, autoWatch: true, devMode: false,
    vocab: ['Heard', 'Parakeet', 'WeSpeaker', 'CTC', 'diarization', 'CATapDescription', 'AUHAL'],
    vocabDraft: '',
    dictEnabled: true, pushToTalk: false,
    speakerFilter: '',
  });
  const setS = (patch) => setS_(prev => ({ ...prev, ...patch }));
  return (
    <HeardWindow title="Heard — Settings">
      <Sidebar active={active} setActive={setActive} onAbout={() => setShowAbout && setShowAbout(true)}/>
      <div style={{ flex: 1, minWidth: 0, display: 'flex', flexDirection: 'column', position: 'relative' }}>
        {active === 'general' && <PaneGeneral s={s} setS={setS}/>}
        {active === 'dictation' && <PaneDictation s={s} setS={setS}/>}
        {active === 'models' && <PaneModels s={s} setS={setS}/>}
        {active === 'speakers' && <PaneSpeakers s={s} setS={setS}/>}
        {showAbout && <AboutSheet onClose={() => setShowAbout(false)}/>}
      </div>
    </HeardWindow>
  );
};

// ── About sheet ──
const AboutSheet = ({ onClose }) => (
  <div style={{
    position: 'absolute', inset: 0, background: 'rgba(28, 32, 36, 0.32)',
    display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 10,
  }}>
    <div style={{
      width: 380, background: PAPER.surface, borderRadius: 12,
      boxShadow: `0 0 0 0.5px ${PAPER.border}, 0 24px 56px ${PAPER.shadowDeep}`,
      overflow: 'hidden', textAlign: 'center',
    }}>
      <div style={{
        padding: '26px 24px 20px',
        background: 'linear-gradient(180deg, #F0E7D5 0%, #FBF7EF 100%)',
        borderBottom: `0.5px solid ${PAPER.borderSoft}`,
      }}>
        <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 14 }}>
          <div style={{ filter: 'drop-shadow(0 6px 12px rgba(60,45,20,0.18))' }}>
            <HeardMark size={72}/>
          </div>
        </div>
        <div style={{ fontSize: 22, fontWeight: 600, fontFamily: FONT_DISPLAY, color: PAPER.ink, letterSpacing: -0.4 }}>Heard</div>
        <div style={{ fontSize: 11.5, color: PAPER.mute, marginTop: 3, fontFamily: FONT_MONO }}>Version 0.1.0 · macOS 15+</div>
        <div style={{ fontSize: 12, color: PAPER.ink2, marginTop: 12, lineHeight: 1.5 }}>
          Automatic Teams meeting detection,<br/>dual-track recording, on-device transcription<br/>and speaker diarization.
        </div>
        <div style={{ display: 'flex', justifyContent: 'center', gap: 6, marginTop: 14 }}>
          <Pill tone="good" icon="shield">On-device</Pill>
          <Pill tone="neutral" icon="cpu">No cloud</Pill>
          <Pill tone="neutral" icon="sparkle">No LLM</Pill>
        </div>
      </div>
      <div style={{ padding: '12px 16px', fontSize: 10.5, color: PAPER.mute, lineHeight: 1.5 }}>
        FluidAudio · Parakeet TDT · Silero VAD · WeSpeaker
      </div>
      <div style={{ padding: '8px 12px 14px', display: 'flex', justifyContent: 'center', gap: 6 }}>
        <Btn size="sm">Acknowledgements</Btn>
        <Btn size="sm" kind="primary" onClick={onClose}>Done</Btn>
      </div>
    </div>
  </div>
);

// ── Menu bar dropdown ──
const MenuBarDropdown = ({ state = 'idle' }) => {
  const headers = {
    idle: { dot: PAPER.good, title: 'Watching', sub: 'Waiting for Teams meeting', titleColor: PAPER.ink },
    paused: { dot: PAPER.warn, title: 'Paused', sub: 'Click to resume', titleColor: PAPER.ink },
    recording: { dot: PAPER.bad, title: 'Recording', sub: 'Sprint Planning · Q4 Roadmap', titleColor: PAPER.bad, trailing: '12:48' },
    processing: { dot: PAPER.warn, title: 'Processing', sub: 'Transcribing · 64%', titleColor: PAPER.warn, progress: 0.64 },
    dictating: { dot: PAPER.bad, title: 'Dictating', sub: '"Let me check the calendar and circle…"', titleColor: PAPER.bad },
  };
  const h = headers[state];
  return (
    <div style={{
      width: 268, background: PAPER.surface,
      borderRadius: 10,
      boxShadow: `0 0 0 0.5px ${PAPER.border}, 0 18px 40px ${PAPER.shadowDeep}, 0 4px 10px ${PAPER.shadow}`,
      fontFamily: FONT_UI, color: PAPER.ink, overflow: 'hidden',
    }}>
      {/* status header */}
      <div style={{ padding: 8 }}>
        <div style={{
          padding: '9px 10px', borderRadius: 7,
          background: state === 'recording' || state === 'dictating' ? PAPER.recordingBg : PAPER.surfaceAlt,
          color: state === 'recording' || state === 'dictating' ? PAPER.recordingInk : PAPER.ink,
          display: 'flex', alignItems: 'center', gap: 9,
        }}>
          <Dot color={h.dot} pulsing={state !== 'idle' && state !== 'paused'}/>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 12.5, fontWeight: 600, color: state === 'recording' || state === 'dictating' ? '#F5EFE4' : h.titleColor }}>{h.title}</div>
            <div style={{ fontSize: 10.5, opacity: 0.75, marginTop: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{h.sub}</div>
            {h.progress != null && (
              <div style={{ marginTop: 5, height: 3, background: 'rgba(245,239,228,0.25)', borderRadius: 2, overflow: 'hidden' }}>
                <div style={{ width: `${h.progress * 100}%`, height: '100%', background: PAPER.warn }}/>
              </div>
            )}
          </div>
          {h.trailing && (
            <span style={{ fontFamily: FONT_MONO, fontSize: 11, fontVariantNumeric: 'tabular-nums' }}>{h.trailing}</span>
          )}
        </div>
      </div>
      <div style={{ height: 0.5, background: PAPER.borderSoft, margin: '0 8px' }}/>
      {/* actions */}
      <div style={{ padding: 6 }}>
        {state === 'idle' && <MItem icon="bolt" label="Simulate meeting"/>}
        {state === 'recording' && <MItem icon="stop" label="End recording" danger/>}
        {(state === 'idle' || state === 'paused') && <MItem icon="keyboard" label="Start dictation" kbd="⌃⇧D"/>}
        <MItem icon="people" label="Name speakers…" badge="2"/>
        <MItem icon="folder" label="Open transcripts"/>
      </div>
      <div style={{ height: 0.5, background: PAPER.borderSoft, margin: '0 8px' }}/>
      <div style={{ padding: 6 }}>
        <MItem icon="gear" label="Settings…" kbd="⌘,"/>
        <MItem icon="power" label="Quit Heard" kbd="⌘Q"/>
      </div>
    </div>
  );
};

const MItem = ({ icon, label, kbd, badge, danger }) => (
  <div style={{
    display: 'flex', alignItems: 'center', gap: 9,
    padding: '5px 8px', borderRadius: 5,
    fontSize: 12, color: danger ? PAPER.bad : PAPER.ink,
    cursor: 'default',
  }}>
    <Icon name={icon} size={12} color={danger ? PAPER.bad : PAPER.ink2}/>
    <span style={{ flex: 1 }}>{label}</span>
    {badge && <Pill tone="accent">{badge}</Pill>}
    {kbd && <span style={{ fontFamily: FONT_MONO, fontSize: 10.5, color: PAPER.mute }}>{kbd}</span>}
  </div>
);

// ── Speaker Naming window ──
const SpeakerNamingWindow = () => {
  const candidates = [
    { id: 1, tmp: 'Speaker 4', suggested: 'Priya Shah', playing: false },
    { id: 2, tmp: 'Speaker 5', suggested: null, playing: true },
    { id: 3, tmp: 'Speaker 6', suggested: 'Marcus Lee', playing: false },
  ];
  return (
    <HeardWindow title="Heard — Name Speakers" width={560} height={520}>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }}>
        <div style={{ padding: '20px 24px 16px', textAlign: 'center', borderBottom: `0.5px solid ${PAPER.borderSoft}` }}>
          <div style={{
            width: 44, height: 44, borderRadius: 10, margin: '0 auto 10px',
            background: PAPER.accentSoft, color: PAPER.accent,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="people" size={22}/>
          </div>
          <div style={{ fontSize: 17, fontWeight: 600, fontFamily: FONT_DISPLAY, color: PAPER.ink, letterSpacing: -0.3 }}>New Speakers Detected</div>
          <div style={{ fontSize: 12, color: PAPER.mute, marginTop: 4, lineHeight: 1.45 }}>
            Listen to each voice clip and enter their name.<br/>Unnamed speakers are saved with generic labels.
          </div>
          <div style={{ fontSize: 10.5, color: PAPER.warn, marginTop: 8, fontFamily: FONT_MONO }}>Auto-saving in 1m 47s</div>
        </div>
        <div style={{ flex: 1, overflow: 'auto', padding: '14px 20px', display: 'flex', flexDirection: 'column', gap: 8 }}>
          {candidates.map(c => (
            <div key={c.id} style={{
              display: 'flex', alignItems: 'center', gap: 10,
              padding: 10, borderRadius: 9, background: PAPER.surface,
              boxShadow: `0 0 0 0.5px ${PAPER.borderSoft}`,
            }}>
              <button style={{
                width: 38, height: 38, borderRadius: 8,
                background: c.playing ? PAPER.bad : PAPER.accentSoft,
                color: c.playing ? '#FFFFFF' : PAPER.accent,
                border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center',
                cursor: 'pointer',
              }}>
                <Icon name={c.playing ? 'stop' : 'play'} size={14} color={c.playing ? '#FFFFFF' : PAPER.accent}/>
              </button>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 4 }}>
                  <span style={{ fontSize: 11, color: PAPER.mute, fontFamily: FONT_MONO }}>{c.tmp}</span>
                  {c.suggested && <Pill tone="warn">maybe {c.suggested}?</Pill>}
                  {c.playing && <Pill tone="bad" dot>Playing</Pill>}
                </div>
                <Input value={c.suggested || ''} placeholder="Enter speaker name" width="100%"/>
              </div>
              <Btn kind="primary" size="sm">Save</Btn>
            </div>
          ))}
        </div>
        <div style={{ padding: '12px 20px', borderTop: `0.5px solid ${PAPER.borderSoft}`, display: 'flex' }}>
          <Btn kind="ghost">Skip all</Btn>
          <div style={{ flex: 1 }}/>
          <Btn kind="primary">Save & Close</Btn>
        </div>
      </div>
    </HeardWindow>
  );
};

// ── Onboarding ──
const Onboarding = () => (
  <HeardWindow title="Welcome to Heard" width={620} height={480}>
    <div style={{ flex: 1, display: 'flex', flexDirection: 'column' }}>
      <div style={{
        padding: '28px 32px 20px',
        background: 'linear-gradient(180deg, #F0E7D5 0%, #FBF7EF 100%)',
        borderBottom: `0.5px solid ${PAPER.borderSoft}`,
        textAlign: 'center',
      }}>
        <div style={{ filter: 'drop-shadow(0 6px 14px rgba(60,45,20,0.18))', display: 'inline-block' }}>
          <HeardMark size={56}/>
        </div>
        <div style={{ fontSize: 22, fontWeight: 600, fontFamily: FONT_DISPLAY, color: PAPER.ink, marginTop: 12, letterSpacing: -0.4 }}>Heard works in the background.</div>
        <div style={{ fontSize: 12.5, color: PAPER.ink2, marginTop: 6, lineHeight: 1.5 }}>
          We'll grant a few permissions so it can detect your Teams meetings,<br/>capture audio, and write transcripts to disk. Nothing leaves your Mac.
        </div>
      </div>
      <div style={{ flex: 1, padding: '18px 24px', display: 'flex', flexDirection: 'column', gap: 8, overflow: 'auto' }}>
        <OnbStep n={1} icon="mic" title="Microphone" desc="Record your voice during meetings and dictation." status="granted"/>
        <OnbStep n={2} icon="screen" title="Screen Recording" desc="Read Teams window titles for transcript filenames." status="granted"/>
        <OnbStep n={3} icon="wave" title="System Audio" desc="Capture other participants via Teams audio tap." status="active"/>
        <OnbStep n={4} icon="fig" title="Accessibility" desc="Read participant names and inject dictation text." status="pending"/>
      </div>
      <div style={{ padding: '12px 20px', borderTop: `0.5px solid ${PAPER.borderSoft}`, display: 'flex', alignItems: 'center', gap: 8 }}>
        <span style={{ fontSize: 11, color: PAPER.mute }}>Step 3 of 4</span>
        <div style={{ flex: 1 }}/>
        <Btn kind="ghost">Skip for now</Btn>
        <Btn kind="primary" icon="arrow.right">Grant System Audio…</Btn>
      </div>
    </div>
  </HeardWindow>
);

const OnbStep = ({ n, icon, title, desc, status }) => {
  const map = {
    granted: { tone: 'good', label: 'Granted', icon: 'check' },
    active:  { tone: 'accent', label: 'Now', icon: 'arrow.right' },
    pending: { tone: 'neutral', label: 'Up next', icon: null },
  }[status];
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12,
      padding: 12, borderRadius: 9,
      background: status === 'active' ? PAPER.accentSoft : PAPER.surface,
      boxShadow: status === 'active' ? `0 0 0 1px ${PAPER.accent}` : `0 0 0 0.5px ${PAPER.borderSoft}`,
    }}>
      <div style={{
        width: 30, height: 30, borderRadius: 8,
        background: status === 'granted' ? PAPER.goodSoft : PAPER.surfaceAlt,
        color: status === 'granted' ? PAPER.good : status === 'active' ? PAPER.accent : PAPER.ink2,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <Icon name={icon} size={14}/>
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 12.5, fontWeight: 600, color: PAPER.ink }}>{title}</div>
        <div style={{ fontSize: 11, color: PAPER.mute, marginTop: 1 }}>{desc}</div>
      </div>
      <Pill tone={map.tone} dot={status === 'granted'}>{map.label}</Pill>
    </div>
  );
};

// ── Empty / error states ──
const EmptyState = ({ kind }) => {
  const conf = {
    'no-speakers': {
      icon: 'people', title: 'No speakers yet',
      desc: 'Speakers will appear here after your first meeting transcribes. Heard learns voices over time.',
      cta: 'Open transcripts',
    },
    'mic-denied': {
      icon: 'mic', title: 'Microphone access required',
      desc: 'Heard cannot record without microphone permission. Open System Settings to grant access.',
      cta: 'Open System Settings…', danger: true,
    },
    'model-failed': {
      icon: 'warn', title: 'Model download failed',
      desc: 'Network interrupted while fetching Parakeet TDT V2. Check your connection and retry.',
      cta: 'Retry download', danger: true,
    },
  }[kind];
  return (
    <div style={{
      flex: 1, display: 'flex', flexDirection: 'column',
      alignItems: 'center', justifyContent: 'center', textAlign: 'center', padding: 32,
    }}>
      <div style={{
        width: 56, height: 56, borderRadius: 14,
        background: conf.danger ? PAPER.badSoft : PAPER.surfaceAlt,
        color: conf.danger ? PAPER.bad : PAPER.mute,
        display: 'flex', alignItems: 'center', justifyContent: 'center', marginBottom: 14,
      }}>
        <Icon name={conf.icon} size={26}/>
      </div>
      <div style={{ fontSize: 14, fontWeight: 600, color: PAPER.ink, fontFamily: FONT_DISPLAY }}>{conf.title}</div>
      <div style={{ fontSize: 12, color: PAPER.mute, marginTop: 6, maxWidth: 280, lineHeight: 1.5 }}>{conf.desc}</div>
      <div style={{ marginTop: 14 }}><Btn kind={conf.danger ? 'primary' : 'default'}>{conf.cta}</Btn></div>
    </div>
  );
};

const EmptyFrame = ({ kind, label }) => (
  <HeardWindow title={`Heard — ${label}`} width={520} height={380}>
    <div style={{ flex: 1, display: 'flex' }}><EmptyState kind={kind}/></div>
  </HeardWindow>
);

Object.assign(window, { Settings, MenuBarDropdown, SpeakerNamingWindow, Onboarding, EmptyState, EmptyFrame, AboutSheet });
