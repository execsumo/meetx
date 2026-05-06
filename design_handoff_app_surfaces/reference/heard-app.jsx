/* Heard — top-level app: design canvas with all surfaces + tweaks. */
/* eslint-disable */

const HeardTweaks = () => {
  const [tweaks, setTweak] = useTweaks(/*EDITMODE-BEGIN*/{
    "density": "comfortable",
    "accent": "dusk",
    "showSpeakers": true,
    "showOnboarding": true
  }/*EDITMODE-END*/);

  // Live-apply accent / density to PAPER tokens
  React.useEffect(() => {
    const accents = {
      dusk:    { accent: '#3F5C8C', accentInk: '#2F4570', accentSoft: '#E5EAF3' },
      olive:   { accent: '#5C6F3E', accentInk: '#46552F', accentSoft: '#E8ECDC' },
      brick:   { accent: '#A6452B', accentInk: '#7E3220', accentSoft: '#F2DCD2' },
      ink:     { accent: '#1C2024', accentInk: '#000000', accentSoft: '#E0DDD4' },
    };
    const a = accents[tweaks.accent] || accents.dusk;
    Object.assign(PAPER, a);
  }, [tweaks.accent]);

  return (
    <TweaksPanel title="Heard — Tweaks">
      <TweakSection title="Accent">
        <TweakRadio
          value={tweaks.accent}
          onChange={v => setTweak('accent', v)}
          options={[
            { value: 'dusk', label: 'Dusk' },
            { value: 'olive', label: 'Olive' },
            { value: 'brick', label: 'Brick' },
            { value: 'ink', label: 'Ink' },
          ]}
        />
      </TweakSection>
      <TweakSection title="Density">
        <TweakRadio
          value={tweaks.density}
          onChange={v => setTweak('density', v)}
          options={[
            { value: 'compact', label: 'Compact' },
            { value: 'comfortable', label: 'Comfort' },
          ]}
        />
      </TweakSection>
      <TweakSection title="Show">
        <TweakToggle label="Speaker naming" value={tweaks.showSpeakers} onChange={v => setTweak('showSpeakers', v)}/>
        <TweakToggle label="Onboarding" value={tweaks.showOnboarding} onChange={v => setTweak('showOnboarding', v)}/>
      </TweakSection>
    </TweaksPanel>
  );
};

const App = () => {
  const [showAbout, setShowAbout] = React.useState(false);
  return (
    <React.Fragment>
      <HeardTweaks/>
      <DesignCanvas title="Heard — App surfaces" initialZoom={0.65}>
        <DCSection id="settings" title="Settings · primary surface">
          <DCArtboard id="settings-general" label="Settings · General" width={880} height={600}>
            <Settings initialTab="general" showAbout={showAbout} setShowAbout={setShowAbout}/>
          </DCArtboard>
          <DCArtboard id="settings-dictation" label="Settings · Dictation" width={880} height={600}>
            <Settings initialTab="dictation" showAbout={showAbout} setShowAbout={setShowAbout}/>
          </DCArtboard>
          <DCArtboard id="settings-models" label="Settings · Models" width={880} height={600}>
            <Settings initialTab="models" showAbout={showAbout} setShowAbout={setShowAbout}/>
          </DCArtboard>
          <DCArtboard id="settings-speakers" label="Settings · Speakers" width={880} height={600}>
            <Settings initialTab="speakers" showAbout={showAbout} setShowAbout={setShowAbout}/>
          </DCArtboard>
        </DCSection>

        <DCSection id="menubar" title="Menu bar dropdown · five states">
          <DCArtboard id="mb-idle" label="Idle (watching)" width={300} height={420}>
            <div style={{ padding: 16, background: 'transparent' }}><MenuBarDropdown state="idle"/></div>
          </DCArtboard>
          <DCArtboard id="mb-rec" label="Recording" width={300} height={420}>
            <div style={{ padding: 16 }}><MenuBarDropdown state="recording"/></div>
          </DCArtboard>
          <DCArtboard id="mb-proc" label="Processing" width={300} height={420}>
            <div style={{ padding: 16 }}><MenuBarDropdown state="processing"/></div>
          </DCArtboard>
          <DCArtboard id="mb-dict" label="Dictating" width={300} height={420}>
            <div style={{ padding: 16 }}><MenuBarDropdown state="dictating"/></div>
          </DCArtboard>
          <DCArtboard id="mb-paused" label="Paused" width={300} height={420}>
            <div style={{ padding: 16 }}><MenuBarDropdown state="paused"/></div>
          </DCArtboard>
        </DCSection>

        <DCSection id="dialogs" title="Auxiliary surfaces">
          <DCArtboard id="onboarding" label="First-run onboarding" width={620} height={480}>
            <Onboarding/>
          </DCArtboard>
          <DCArtboard id="naming" label="Speaker naming window" width={560} height={520}>
            <SpeakerNamingWindow/>
          </DCArtboard>
          <DCArtboard id="about" label="About Heard (sheet)" width={420} height={420}>
            <div style={{
              width: 420, height: 420, background: PAPER.bg, borderRadius: 11,
              boxShadow: `0 0 0 0.5px ${PAPER.border}`,
              display: 'flex', alignItems: 'center', justifyContent: 'center', overflow: 'hidden',
            }}>
              <AboutSheet onClose={() => {}}/>
            </div>
          </DCArtboard>
        </DCSection>

        <DCSection id="states" title="Empty & error states">
          <DCArtboard id="empty-speakers" label="No speakers yet" width={520} height={380}>
            <EmptyFrame kind="no-speakers" label="Speakers"/>
          </DCArtboard>
          <DCArtboard id="empty-mic" label="Microphone denied" width={520} height={380}>
            <EmptyFrame kind="mic-denied" label="General"/>
          </DCArtboard>
          <DCArtboard id="empty-model" label="Model download failed" width={520} height={380}>
            <EmptyFrame kind="model-failed" label="Models"/>
          </DCArtboard>
        </DCSection>
      </DesignCanvas>
    </React.Fragment>
  );
};

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App/>);
