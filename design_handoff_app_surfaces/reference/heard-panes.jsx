/* Heard — Settings panes (General, Dictation, Models, Speakers). */
/* eslint-disable */

// Reusable: inline-edit text
const InlineText = ({ value, onChange }) => {
  const [v, setV] = React.useState(value);
  const [editing, setEditing] = React.useState(false);
  React.useEffect(() => setV(value), [value]);
  if (!editing) {
    return (
      <span onClick={() => setEditing(true)} style={{ cursor: 'text', fontSize: 12 }}>{v}</span>
    );
  }
  return (
    <Input value={v} onChange={setV} width={140} />
  );
};

// ──────────────────────────────────────────────
// GENERAL
// ──────────────────────────────────────────────
const PaneGeneral = ({ s, setS }) => {
  const perms = [
    { id: 'mic', icon: 'mic', name: 'Microphone', why: 'Record your voice during meetings and dictation', state: 'granted', required: true },
    { id: 'screen', icon: 'screen', name: 'Screen Recording', why: 'Read Teams window titles for transcript filenames', state: 'granted', required: true },
    { id: 'audio', icon: 'wave', name: 'System Audio', why: 'Capture other participants via Teams audio tap', state: 'granted' },
    { id: 'a11y', icon: 'fig', name: 'Accessibility', why: 'Read participant rosters and inject dictation text', state: 'limited', detail: 'Required for dictation' },
  ];

  return (
    <PaneScroll>
      <PaneHeader title="General" sub="Behavior, vocabulary, and where Heard saves your transcripts." icon="gear"/>

      <SectionLabel>Behavior</SectionLabel>
      <Card padding={4}>
        <Row icon="power" label="Launch at login" sub="Open Heard automatically when you sign in" control={<Toggle on={s.launchAtLogin} onChange={v => setS({ launchAtLogin: v })}/>}/>
        <Row icon="record" label="Auto-watch on launch" sub="Start listening for Teams meetings immediately" control={<Toggle on={s.autoWatch} onChange={v => setS({ autoWatch: v })}/>}/>
        <Row icon="bolt" label="Developer mode" sub="Enable Simulate Meeting controls in the menu bar" last control={<Toggle on={s.devMode} onChange={v => setS({ devMode: v })}/>}/>
      </Card>

      <div style={{ height: 14 }}/>
      <SectionLabel>Permissions</SectionLabel>
      <Card padding={4}>
        {perms.map((p, i) => (
          <PermRow key={p.id} perm={p} last={i === perms.length - 1}/>
        ))}
      </Card>

      <div style={{ height: 14 }}/>
      <SectionLabel hint="Domain-specific terms (names, jargon, codenames). Boosted via CTC during transcription.">Custom vocabulary</SectionLabel>
      <Card padding={12}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginBottom: 10 }}>
          <Input value={s.vocabDraft} onChange={v => setS({ vocabDraft: v })} placeholder="Add a term (min 3 chars)" width={260} leadingIcon="plus"/>
          <Btn kind="primary" size="sm" onClick={() => {
            const t = (s.vocabDraft || '').trim();
            if (t.length < 3) return;
            setS({ vocab: [...s.vocab, t], vocabDraft: '' });
          }}>Add</Btn>
          <span style={{ marginLeft: 'auto', fontSize: 10.5, color: PAPER.mute, fontFamily: FONT_MONO }}>{s.vocab.length} / 50</span>
        </div>
        {s.vocab.length === 0 ? (
          <div style={{ fontSize: 11, color: PAPER.mute, padding: '8px 0' }}>No custom terms yet.</div>
        ) : (
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: 5 }}>
            {s.vocab.map((t, i) => (
              <span key={i} style={{
                display: 'inline-flex', alignItems: 'center', gap: 4,
                padding: '3px 4px 3px 9px', borderRadius: 999,
                background: PAPER.surfaceAlt, color: PAPER.ink,
                fontSize: 11, border: `0.5px solid ${PAPER.borderSoft}`,
              }}>
                {t}
                <button onClick={() => setS({ vocab: s.vocab.filter((_, j) => j !== i) })} style={{
                  border: 'none', background: 'transparent', padding: 2, borderRadius: '50%',
                  display: 'flex', cursor: 'pointer', color: PAPER.mute,
                }}><Icon name="x" size={9}/></button>
              </span>
            ))}
          </div>
        )}
      </Card>

      <div style={{ height: 14 }}/>
      <SectionLabel>Output folder</SectionLabel>
      <Card padding={12}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div style={{
            flex: 1, display: 'flex', alignItems: 'center', gap: 8,
            padding: '6px 9px', background: PAPER.bg, borderRadius: 6,
            border: `0.5px solid ${PAPER.border}`, minWidth: 0,
          }}>
            <Icon name="folder" size={13} color={PAPER.accent}/>
            <span style={{
              fontSize: 11.5, color: PAPER.ink2, fontFamily: FONT_MONO,
              whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', minWidth: 0, flex: 1,
            }}>~/Documents/Heard</span>
          </div>
          <Btn size="sm">Choose…</Btn>
          <Btn size="sm" kind="ghost">Reset</Btn>
          <Btn size="sm" icon="arrow.right">Open</Btn>
        </div>
      </Card>
    </PaneScroll>
  );
};

const PermRow = ({ perm, last }) => {
  const tone = perm.state === 'granted' ? 'good' : perm.state === 'limited' ? 'warn' : 'bad';
  const stateLabel = perm.state === 'granted' ? 'Granted' : perm.state === 'limited' ? 'Limited' : 'Not granted';
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 10,
      padding: '8px 4px',
      borderBottom: last ? 'none' : `0.5px solid ${PAPER.borderSoft}`,
    }}>
      <div style={{
        width: 28, height: 28, borderRadius: 7,
        background: tone === 'good' ? PAPER.goodSoft : tone === 'warn' ? PAPER.warnSoft : PAPER.badSoft,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: tone === 'good' ? PAPER.good : tone === 'warn' ? PAPER.warn : PAPER.bad,
        flexShrink: 0,
      }}>
        <Icon name={perm.icon} size={14}/>
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <div style={{ fontSize: 12, color: PAPER.ink, fontWeight: 600 }}>{perm.name}</div>
          {perm.required && <Pill tone="neutral">Required</Pill>}
          {perm.detail && <span style={{ fontSize: 10.5, color: PAPER.mute }}>{perm.detail}</span>}
        </div>
        <div style={{ fontSize: 11, color: PAPER.mute, marginTop: 1 }}>{perm.why}</div>
      </div>
      <Pill tone={tone} dot>{stateLabel}</Pill>
      {perm.state !== 'granted' && <Btn size="sm">Grant…</Btn>}
    </div>
  );
};

// ──────────────────────────────────────────────
// DICTATION
// ──────────────────────────────────────────────
const PaneDictation = ({ s, setS }) => (
  <PaneScroll>
    <PaneHeader title="Dictation" sub="Type with your voice into any focused text field." icon="keyboard"/>

    <Card padding={12} accent>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <div style={{
          width: 38, height: 38, borderRadius: 9,
          background: PAPER.accentSoft, color: PAPER.accent,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          <Icon name="keyboard" size={18}/>
        </div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: PAPER.ink }}>Enable dictation</div>
          <div style={{ fontSize: 11.5, color: PAPER.mute, marginTop: 2 }}>Press the hotkey to start typing with your voice anywhere.</div>
        </div>
        <Toggle on={s.dictEnabled} onChange={v => setS({ dictEnabled: v })}/>
      </div>
    </Card>

    <div style={{ height: 14 }}/>
    <SectionLabel>Hotkey</SectionLabel>
    <Card padding={12}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 12, color: PAPER.ink, fontWeight: 500 }}>Shortcut</div>
          <div style={{ fontSize: 11, color: PAPER.mute, marginTop: 2 }}>{s.pushToTalk ? 'Hold to dictate, release to stop' : 'Tap to start, tap again to stop'}</div>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
          <Kbd>⌃</Kbd><Kbd>⇧</Kbd><Kbd>D</Kbd>
        </div>
        <Btn size="sm" icon="record">Record…</Btn>
      </div>
      <div style={{ borderTop: `0.5px solid ${PAPER.borderSoft}`, paddingTop: 10 }}>
        <Row label="Push-to-talk" sub="Hold instead of toggle" last control={<Toggle on={s.pushToTalk} onChange={v => setS({ pushToTalk: v })}/>}/>
      </div>
    </Card>

    <div style={{ height: 14 }}/>
    <SectionLabel hint="Keep ASR models in memory after you stop dictating to skip the reload delay on the next utterance.">Model keep-alive</SectionLabel>
    <Card padding={12}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 10 }}>
        <div style={{ fontSize: 12, color: PAPER.ink2 }}>Stay loaded for</div>
        <div style={{ fontSize: 14, fontWeight: 700, fontFamily: FONT_MONO, color: PAPER.ink }}>2m 0s</div>
      </div>
      <Slider value={120} min={0} max={600} marks={['Off', '5m', '10m']}/>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginTop: 12, paddingTop: 10, borderTop: `0.5px solid ${PAPER.borderSoft}` }}>
        <div style={{ fontSize: 11, color: PAPER.mute }}>≈ 800 MB resident while loaded</div>
        <Btn size="sm" icon="x">Unload now</Btn>
      </div>
    </Card>

    <div style={{ height: 14 }}/>
    <Card padding={12}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <Icon name="sparkle" size={14} color={PAPER.accent}/>
        <div style={{ flex: 1, fontSize: 11.5, color: PAPER.ink2, lineHeight: 1.45 }}>
          <strong style={{ color: PAPER.ink }}>Tip:</strong> dictation uses a 0.6 s polling loop with stability-based commits — words only land in your text field once they appear in two consecutive cycles, so revisions don't double-type.
        </div>
      </div>
    </Card>
  </PaneScroll>
);

// ──────────────────────────────────────────────
// MODELS — hybrid: hero summary + per-model list
// ──────────────────────────────────────────────
const PaneModels = ({ s, setS }) => {
  const models = [
    { kind: 'transcription', name: 'Parakeet TDT V2', role: 'Meeting & dictation transcription', size: '650 MB', state: 'ready' },
    { kind: 'vad', name: 'Silero VAD v6', role: 'Silence trimming', size: '8 MB', state: 'ready' },
    { kind: 'diarization', name: 'LS-EEND + WeSpeaker', role: 'Speaker segmentation & embeddings', size: '210 MB', state: 'ready' },
    { kind: 'ctc', name: 'Parakeet CTC 110M', role: 'Custom vocabulary boosting', size: '110 MB', state: 'downloading', progress: 0.62 },
  ];
  const totalReady = models.filter(m => m.state === 'ready').length;
  return (
    <PaneScroll>
      <PaneHeader title="Models" sub="On-device models for transcription, diarization, and vocabulary boosting." icon="cube"/>

      {/* Hero status card */}
      <div style={{
        background: 'linear-gradient(180deg, #2E3338 0%, #1C2024 100%)',
        borderRadius: 10, padding: 16, color: '#F5EFE4',
        boxShadow: `0 0 0 0.5px rgba(0,0,0,0.4), 0 6px 14px rgba(60,45,20,0.18)`,
        position: 'relative', overflow: 'hidden',
      }}>
        <div style={{ position: 'absolute', top: -20, right: -20, opacity: 0.08 }}>
          <Icon name="bubble" size={140} color="#F5EFE4"/>
        </div>
        <div style={{ display: 'flex', alignItems: 'flex-start', gap: 14, position: 'relative' }}>
          <div style={{
            width: 40, height: 40, borderRadius: 9,
            background: 'rgba(245,239,228,0.10)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <Icon name="cpu" size={20} color="#F5EFE4"/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11, fontWeight: 700, color: '#C9BBA5', letterSpacing: 0.7, textTransform: 'uppercase' }}>On-device pipeline</div>
            <div style={{ fontSize: 18, fontWeight: 600, fontFamily: FONT_DISPLAY, marginTop: 3, letterSpacing: -0.3 }}>{totalReady} of {models.length} models ready</div>
            <div style={{ fontSize: 11.5, color: '#A89E8A', marginTop: 3 }}>978 MB on disk · keep-alive 2m · ~800 MB peak RAM</div>
          </div>
        </div>
        <div style={{ display: 'flex', gap: 6, marginTop: 14 }}>
          <Btn kind="dark" icon="arrow.down" size="sm">Download missing</Btn>
          <Btn kind="ghost" size="sm" icon="x"><span style={{ color: '#F5EFE4' }}>Unload all</span></Btn>
        </div>
      </div>

      <div style={{ height: 14 }}/>
      <SectionLabel>Transcription model</SectionLabel>
      <Card padding={12}>
        <div style={{ display: 'flex', gap: 10 }}>
          <ModelChoice selected name="Parakeet TDT V2" detail="Recommended · best accuracy"/>
          <ModelChoice name="Parakeet TDT V3" detail="Experimental · multilingual" beta/>
        </div>
      </Card>

      <div style={{ height: 14 }}/>
      <SectionLabel>Models on disk</SectionLabel>
      <Card padding={4}>
        {models.map((m, i) => (
          <ModelRow key={m.kind} m={m} last={i === models.length - 1}/>
        ))}
      </Card>

      <div style={{ height: 14 }}/>
      <SectionLabel hint="Keep meeting models loaded after a transcription finishes to speed up back-to-back jobs.">Pipeline keep-alive</SectionLabel>
      <Card padding={12}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 10 }}>
          <div style={{ fontSize: 12, color: PAPER.ink2 }}>Stay loaded for</div>
          <div style={{ fontSize: 14, fontWeight: 700, fontFamily: FONT_MONO, color: PAPER.ink }}>2m 0s</div>
        </div>
        <Slider value={120} min={0} max={600} marks={['Off', '5m', '10m']}/>
      </Card>
    </PaneScroll>
  );
};

const ModelChoice = ({ selected, name, detail, beta }) => (
  <div style={{
    flex: 1, padding: 11, borderRadius: 8,
    background: selected ? PAPER.accentSoft : PAPER.bg,
    border: `${selected ? 1 : 0.5}px solid ${selected ? PAPER.accent : PAPER.border}`,
    cursor: 'pointer', position: 'relative',
  }}>
    <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
      <div style={{
        width: 14, height: 14, borderRadius: '50%',
        border: `1.5px solid ${selected ? PAPER.accent : PAPER.muteSoft}`,
        background: selected ? PAPER.accent : 'transparent',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        {selected && <span style={{ width: 5, height: 5, borderRadius: '50%', background: '#FFFFFF' }}/>}
      </div>
      <div style={{ fontSize: 12.5, fontWeight: 600, color: PAPER.ink }}>{name}</div>
      {beta && <Pill tone="warn">Beta</Pill>}
    </div>
    <div style={{ fontSize: 11, color: PAPER.mute, marginTop: 4, marginLeft: 20 }}>{detail}</div>
  </div>
);

const ModelRow = ({ m, last }) => {
  const stateNode = m.state === 'ready'
    ? <Pill tone="good" dot>Ready</Pill>
    : m.state === 'downloading'
    ? <div style={{ display: 'flex', alignItems: 'center', gap: 6, minWidth: 110 }}>
        <div style={{ flex: 1, height: 4, background: PAPER.muteSoft, borderRadius: 2, overflow: 'hidden' }}>
          <div style={{ width: `${m.progress * 100}%`, height: '100%', background: PAPER.accent }}/>
        </div>
        <span style={{ fontSize: 10.5, color: PAPER.accent, fontFamily: FONT_MONO }}>{Math.round(m.progress * 100)}%</span>
      </div>
    : <Pill tone="neutral">Not downloaded</Pill>;
  return (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 10,
      padding: '9px 4px',
      borderBottom: last ? 'none' : `0.5px solid ${PAPER.borderSoft}`,
    }}>
      <div style={{
        width: 28, height: 28, borderRadius: 7, background: PAPER.surfaceAlt,
        display: 'flex', alignItems: 'center', justifyContent: 'center', color: PAPER.ink2,
      }}>
        <Icon name={m.kind === 'transcription' ? 'wave' : m.kind === 'vad' ? 'sparkle' : m.kind === 'diarization' ? 'people' : 'cube'} size={13}/>
      </div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 12, color: PAPER.ink, fontWeight: 600 }}>{m.name}</div>
        <div style={{ fontSize: 11, color: PAPER.mute, marginTop: 1 }}>{m.role} · <span style={{ fontFamily: FONT_MONO }}>{m.size}</span></div>
      </div>
      {stateNode}
    </div>
  );
};

// ──────────────────────────────────────────────
// SPEAKERS
// ──────────────────────────────────────────────
const PaneSpeakers = ({ s, setS }) => {
  const candidates = [
    { id: 'c1', tmp: 'Speaker 4', suggested: 'Priya Shah' },
    { id: 'c2', tmp: 'Speaker 5', suggested: null },
  ];
  const speakers = [
    { id: 1, name: 'Me (Sam)', meetings: 42, first: 'Aug 12', last: 'Today', isYou: true },
    { id: 2, name: 'Priya Shah', meetings: 18, first: 'Sep 03', last: 'Today' },
    { id: 3, name: 'Marcus Lee', meetings: 11, first: 'Sep 14', last: 'Yesterday' },
    { id: 4, name: 'Jordan Kim', meetings: 7, first: 'Oct 02', last: 'Mon' },
    { id: 5, name: 'Speaker 6', meetings: 1, first: 'Today', last: 'Today', unnamed: true },
  ];
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100%', minHeight: 0 }}>
      <div style={{ padding: '14px 18px 0', flexShrink: 0 }}>
        <PaneHeader title="Speakers" sub="People Heard has heard before. Inline-rename, merge duplicates, or delete." icon="people" noBottom/>

        {candidates.length > 0 && (
          <div style={{ marginTop: 12 }}>
            <Card padding={10} accent>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
                <Icon name="sparkle" size={13} color={PAPER.accent}/>
                <div style={{ flex: 1, fontSize: 12, fontWeight: 600, color: PAPER.ink }}>{candidates.length} new speakers detected</div>
                <Btn size="sm" kind="ghost">Skip all</Btn>
                <Btn size="sm" kind="primary">Open naming…</Btn>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                {candidates.map(c => (
                  <div key={c.id} style={{
                    display: 'flex', alignItems: 'center', gap: 8,
                    padding: '5px 0', fontSize: 11.5, color: PAPER.ink2,
                  }}>
                    <span style={{ width: 70, fontFamily: FONT_MONO, color: PAPER.mute }}>{c.tmp}</span>
                    <button style={{
                      width: 22, height: 22, borderRadius: 5,
                      border: `0.5px solid ${PAPER.border}`, background: PAPER.surface,
                      color: PAPER.accent, display: 'flex', alignItems: 'center', justifyContent: 'center',
                      cursor: 'pointer',
                    }}><Icon name="play" size={9} color={PAPER.accent}/></button>
                    <Input value={c.suggested || ''} placeholder="Enter name" width={180}/>
                    {c.suggested && <Pill tone="warn">maybe {c.suggested}?</Pill>}
                    <Btn size="sm" kind="primary">Save</Btn>
                  </div>
                ))}
              </div>
            </Card>
          </div>
        )}

        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 12, marginBottom: 10 }}>
          <Input leadingIcon="magnifier" value={s.speakerFilter} onChange={v => setS({ speakerFilter: v })} placeholder="Search speakers" width={220}/>
          <Segmented value="meetings" options={[
            { value: 'name', label: 'A–Z' },
            { value: 'meetings', label: 'Meetings' },
            { value: 'recent', label: 'Recent' },
          ]}/>
          <div style={{ flex: 1 }}/>
          <Btn size="sm" icon="merge" disabled>Merge</Btn>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '6px 4px', fontSize: 10.5, fontWeight: 700, color: PAPER.mute, textTransform: 'uppercase', letterSpacing: 0.5, borderTop: `0.5px solid ${PAPER.borderSoft}` }}>
          <span style={{ width: 28 }}>Voice</span>
          <span style={{ flex: 1 }}>Name</span>
          <span style={{ width: 70, textAlign: 'right' }}>Meetings</span>
          <span style={{ width: 90, textAlign: 'right' }}>First seen</span>
          <span style={{ width: 90, textAlign: 'right' }}>Last seen</span>
        </div>
      </div>

      <div style={{ flex: 1, minHeight: 0, overflow: 'auto', padding: '0 18px 14px' }}>
        {speakers.map((sp, i) => <SpeakerRow key={sp.id} sp={sp} alt={i % 2 === 1}/>)}
      </div>
    </div>
  );
};

const SpeakerRow = ({ sp, alt }) => (
  <div style={{
    display: 'flex', alignItems: 'center', gap: 10,
    padding: '7px 4px',
    borderBottom: `0.5px solid ${PAPER.borderSoft}`,
    background: alt ? 'rgba(217, 207, 185, 0.18)' : 'transparent',
  }}>
    <button style={{
      width: 26, height: 26, borderRadius: 6,
      border: `0.5px solid ${PAPER.border}`, background: PAPER.surface,
      display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
    }}>
      <Icon name="play" size={10} color={PAPER.accent}/>
    </button>
    <div style={{ flex: 1, display: 'flex', alignItems: 'center', gap: 6 }}>
      <span style={{ fontSize: 12, fontWeight: sp.isYou ? 700 : 500, color: sp.unnamed ? PAPER.mute : PAPER.ink, fontFamily: sp.unnamed ? FONT_MONO : FONT_UI, fontStyle: sp.unnamed ? 'italic' : 'normal' }}>{sp.name}</span>
      {sp.isYou && <Pill tone="accent">You</Pill>}
      {sp.unnamed && <Pill tone="warn">Unnamed</Pill>}
    </div>
    <span style={{ width: 70, textAlign: 'right', fontSize: 11.5, color: PAPER.ink2, fontFamily: FONT_MONO }}>{sp.meetings}</span>
    <span style={{ width: 90, textAlign: 'right', fontSize: 11.5, color: PAPER.mute }}>{sp.first}</span>
    <span style={{ width: 90, textAlign: 'right', fontSize: 11.5, color: PAPER.mute }}>{sp.last}</span>
  </div>
);

// ─── shared layout helpers ───
const PaneScroll = ({ children }) => (
  <div style={{ height: '100%', overflow: 'auto', padding: '14px 18px' }}>{children}</div>
);

const PaneHeader = ({ title, sub, icon, noBottom }) => (
  <div style={{
    display: 'flex', alignItems: 'flex-start', gap: 12,
    paddingBottom: noBottom ? 0 : 14, marginBottom: noBottom ? 0 : 14,
    borderBottom: noBottom ? 'none' : `0.5px solid ${PAPER.borderSoft}`,
  }}>
    <div style={{
      width: 32, height: 32, borderRadius: 8,
      background: PAPER.surface, color: PAPER.ink2,
      border: `0.5px solid ${PAPER.border}`,
      display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
    }}>
      <Icon name={icon} size={15}/>
    </div>
    <div style={{ flex: 1, minWidth: 0 }}>
      <div style={{ fontSize: 19, fontWeight: 600, fontFamily: FONT_DISPLAY, color: PAPER.ink, letterSpacing: -0.3 }}>{title}</div>
      <div style={{ fontSize: 11.5, color: PAPER.mute, marginTop: 2, lineHeight: 1.4 }}>{sub}</div>
    </div>
  </div>
);

Object.assign(window, { PaneGeneral, PaneDictation, PaneModels, PaneSpeakers, PaneScroll, PaneHeader, InlineText });
