/* Heard — primitive UI components. Loads after heard-tokens.jsx */
/* eslint-disable */
const { useState: hpUseState } = React;

// ── Window chrome ──
const HeardWindow = ({ title = "Heard — Settings", children, width = 880, height = 600, toolbar }) => (
  <div style={{
    width, height, background: PAPER.bg, borderRadius: 11,
    boxShadow: `0 1px 0 rgba(255,255,255,0.5) inset, 0 0 0 0.5px ${PAPER.border}, 0 24px 56px ${PAPER.shadowDeep}, 0 6px 16px ${PAPER.shadow}`,
    overflow: 'hidden', display: 'flex', flexDirection: 'column',
    fontFamily: FONT_UI, color: PAPER.ink,
  }}>
    <div style={{
      height: 38, background: 'linear-gradient(180deg, #F0E7D5 0%, #E8DEC8 100%)',
      borderBottom: `0.5px solid ${PAPER.border}`,
      display: 'flex', alignItems: 'center', padding: '0 12px', gap: 8,
      flexShrink: 0, position: 'relative',
    }}>
      <div style={{ display: 'flex', gap: 8 }}>
        <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#E76A5C', boxShadow: 'inset 0 0 0 0.5px rgba(0,0,0,0.15)' }}/>
        <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#E5A23E', boxShadow: 'inset 0 0 0 0.5px rgba(0,0,0,0.15)' }}/>
        <span style={{ width: 12, height: 12, borderRadius: '50%', background: '#5BB45C', boxShadow: 'inset 0 0 0 0.5px rgba(0,0,0,0.15)' }}/>
      </div>
      <div style={{
        position: 'absolute', left: 0, right: 0, textAlign: 'center', pointerEvents: 'none',
        fontSize: 13, fontWeight: 600, color: PAPER.ink2, fontFamily: FONT_DISPLAY, letterSpacing: -0.1,
      }}>{title}</div>
      {toolbar && <div style={{ marginLeft: 'auto', display: 'flex', gap: 6 }}>{toolbar}</div>}
    </div>
    <div style={{ flex: 1, display: 'flex', minHeight: 0 }}>{children}</div>
  </div>
);

// ── Pill / badge ──
const Pill = ({ tone = 'neutral', children, dot, icon }) => {
  const map = {
    neutral: { bg: PAPER.surfaceAlt, fg: PAPER.ink2, dotC: PAPER.mute },
    good:    { bg: PAPER.goodSoft, fg: PAPER.good, dotC: PAPER.good },
    warn:    { bg: PAPER.warnSoft, fg: PAPER.warn, dotC: PAPER.warn },
    bad:     { bg: PAPER.badSoft, fg: PAPER.bad, dotC: PAPER.bad },
    accent:  { bg: PAPER.accentSoft, fg: PAPER.accentInk, dotC: PAPER.accent },
  }[tone];
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      background: map.bg, color: map.fg,
      padding: '2px 7px', borderRadius: 999,
      fontSize: 10.5, fontWeight: 600, letterSpacing: 0.1,
      whiteSpace: 'nowrap', lineHeight: 1.4,
    }}>
      {dot && <span style={{ width: 6, height: 6, borderRadius: '50%', background: map.dotC }}/>}
      {icon && <Icon name={icon} size={10} color={map.fg}/>}
      {children}
    </span>
  );
};

// ── Card ──
const Card = ({ title, hint, action, children, padding = 12, accent }) => (
  <div style={{
    background: PAPER.surface, borderRadius: 10,
    boxShadow: `0 0 0 0.5px ${PAPER.border}, 0 1px 2px ${PAPER.shadow}`,
    overflow: 'hidden',
  }}>
    {(title || action) && (
      <div style={{
        display: 'flex', alignItems: 'center', gap: 10,
        padding: '9px 12px',
        borderBottom: `0.5px solid ${PAPER.borderSoft}`,
        background: accent ? PAPER.accentSoft : 'transparent',
      }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          {title && <div style={{ fontSize: 12, fontWeight: 700, color: PAPER.ink, letterSpacing: -0.1 }}>{title}</div>}
          {hint && <div style={{ fontSize: 11, color: PAPER.mute, marginTop: 1 }}>{hint}</div>}
        </div>
        {action}
      </div>
    )}
    <div style={{ padding }}>{children}</div>
  </div>
);

// ── Row inside a card ──
const Row = ({ label, sub, control, icon, last, onClick }) => (
  <div onClick={onClick} style={{
    display: 'flex', alignItems: 'center', gap: 10,
    padding: '7px 2px',
    borderBottom: last ? 'none' : `0.5px solid ${PAPER.borderSoft}`,
    cursor: onClick ? 'pointer' : 'default',
  }}>
    {icon && (
      <div style={{
        width: 26, height: 26, borderRadius: 6,
        background: PAPER.surfaceAlt,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        color: PAPER.ink2, flexShrink: 0,
      }}>
        <Icon name={icon} size={13}/>
      </div>
    )}
    <div style={{ flex: 1, minWidth: 0 }}>
      <div style={{ fontSize: 12, color: PAPER.ink, fontWeight: 500 }}>{label}</div>
      {sub && <div style={{ fontSize: 11, color: PAPER.mute, marginTop: 1, lineHeight: 1.35 }}>{sub}</div>}
    </div>
    {control}
  </div>
);

// ── Toggle ──
const Toggle = ({ on, onChange }) => (
  <button onClick={() => onChange && onChange(!on)} style={{
    width: 30, height: 18, borderRadius: 999,
    background: on ? PAPER.accent : PAPER.muteSoft,
    border: 'none', padding: 2, cursor: 'pointer',
    display: 'flex', alignItems: 'center',
    transition: 'background 120ms',
    boxShadow: `inset 0 0.5px 1px rgba(0,0,0,0.1)`,
  }}>
    <span style={{
      width: 14, height: 14, borderRadius: '50%',
      background: '#FFFFFF',
      transform: on ? 'translateX(12px)' : 'translateX(0)',
      transition: 'transform 140ms',
      boxShadow: '0 1px 2px rgba(0,0,0,0.2)',
    }}/>
  </button>
);

// ── Button ──
const Btn = ({ kind = 'default', icon, children, onClick, disabled, size = 'md' }) => {
  const tones = {
    default: { bg: PAPER.surface, fg: PAPER.ink, border: PAPER.border },
    primary: { bg: PAPER.accent, fg: '#FFFFFF', border: PAPER.accentInk },
    ghost:   { bg: 'transparent', fg: PAPER.ink2, border: 'transparent' },
    danger:  { bg: PAPER.surface, fg: PAPER.bad, border: PAPER.border },
    dark:    { bg: PAPER.ink, fg: PAPER.bg, border: PAPER.ink },
  }[kind] || { bg: PAPER.surface, fg: PAPER.ink, border: PAPER.border };
  const sz = size === 'sm' ? { px: 8, py: 3, fs: 11 } : { px: 10, py: 5, fs: 12 };
  return (
    <button onClick={onClick} disabled={disabled} style={{
      display: 'inline-flex', alignItems: 'center', gap: 5,
      padding: `${sz.py}px ${sz.px}px`, borderRadius: 6,
      background: tones.bg, color: tones.fg,
      border: `0.5px solid ${tones.border}`,
      fontFamily: FONT_UI, fontSize: sz.fs, fontWeight: 500,
      cursor: disabled ? 'default' : 'pointer',
      opacity: disabled ? 0.5 : 1,
      boxShadow: kind === 'default' ? `0 1px 0 ${PAPER.shadow}` : 'none',
      whiteSpace: 'nowrap',
    }}>
      {icon && <Icon name={icon} size={11} color={tones.fg}/>}
      {children}
    </button>
  );
};

// ── Input ──
const Input = ({ value, onChange, placeholder, mono, width, suffix, leadingIcon }) => (
  <div style={{
    display: 'inline-flex', alignItems: 'center', gap: 6,
    width: width || 'auto',
    background: PAPER.bg,
    border: `0.5px solid ${PAPER.border}`,
    borderRadius: 6, padding: '4px 8px',
    boxShadow: `inset 0 1px 1px ${PAPER.shadow}`,
  }}>
    {leadingIcon && <Icon name={leadingIcon} size={11} color={PAPER.mute}/>}
    <input
      value={value} placeholder={placeholder}
      onChange={(e) => onChange && onChange(e.target.value)}
      style={{
        flex: 1, border: 'none', outline: 'none', background: 'transparent',
        fontFamily: mono ? FONT_MONO : FONT_UI, fontSize: 12, color: PAPER.ink,
        minWidth: 0, padding: 0,
      }}
    />
    {suffix && <span style={{ fontSize: 10.5, color: PAPER.mute }}>{suffix}</span>}
  </div>
);

// ── Section header ──
const SectionLabel = ({ children, hint }) => (
  <div style={{ marginBottom: 8, paddingLeft: 2 }}>
    <div style={{
      fontSize: 10.5, fontWeight: 700, color: PAPER.mute,
      textTransform: 'uppercase', letterSpacing: 0.7,
    }}>{children}</div>
    {hint && <div style={{ fontSize: 11, color: PAPER.mute, marginTop: 2 }}>{hint}</div>}
  </div>
);

// ── Slider ──
const Slider = ({ value, min, max, step, onChange, marks }) => {
  const pct = ((value - min) / (max - min)) * 100;
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
      <div style={{ position: 'relative', height: 18, display: 'flex', alignItems: 'center' }}>
        <div style={{ position: 'absolute', left: 0, right: 0, height: 3, background: PAPER.muteSoft, borderRadius: 2 }}/>
        <div style={{ position: 'absolute', left: 0, width: `${pct}%`, height: 3, background: PAPER.accent, borderRadius: 2 }}/>
        <div style={{
          position: 'absolute', left: `calc(${pct}% - 7px)`, width: 14, height: 14,
          borderRadius: '50%', background: '#FFFFFF',
          boxShadow: `0 0 0 0.5px ${PAPER.border}, 0 1px 2px ${PAPER.shadow}`,
        }}/>
      </div>
      {marks && (
        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 10, color: PAPER.mute, fontFamily: FONT_MONO }}>
          {marks.map((m, i) => <span key={i}>{m}</span>)}
        </div>
      )}
    </div>
  );
};

// ── Segmented control ──
const Segmented = ({ options, value, onChange }) => (
  <div style={{
    display: 'inline-flex', padding: 2,
    background: PAPER.surfaceAlt, borderRadius: 7,
    border: `0.5px solid ${PAPER.borderSoft}`,
  }}>
    {options.map(o => {
      const sel = o.value === value;
      return (
        <button key={o.value} onClick={() => onChange && onChange(o.value)} style={{
          padding: '3px 10px', borderRadius: 5,
          background: sel ? PAPER.surface : 'transparent',
          border: 'none', cursor: 'pointer',
          fontFamily: FONT_UI, fontSize: 11.5, fontWeight: sel ? 600 : 500,
          color: sel ? PAPER.ink : PAPER.ink2,
          boxShadow: sel ? `0 0 0 0.5px ${PAPER.border}, 0 1px 2px ${PAPER.shadow}` : 'none',
        }}>{o.label}</button>
      );
    })}
  </div>
);

// ── Kbd ──
const Kbd = ({ children }) => (
  <span style={{
    display: 'inline-block',
    fontFamily: FONT_MONO, fontSize: 11, fontWeight: 600,
    color: PAPER.ink,
    padding: '2px 6px',
    background: PAPER.surface,
    border: `0.5px solid ${PAPER.border}`,
    borderRadius: 4,
    boxShadow: `0 1px 0 ${PAPER.borderSoft}`,
  }}>{children}</span>
);

// ── Status dot ──
const Dot = ({ color = PAPER.good, pulsing }) => (
  <span style={{
    display: 'inline-block', width: 7, height: 7, borderRadius: '50%',
    background: color, position: 'relative', flexShrink: 0,
    boxShadow: pulsing ? `0 0 0 3px ${color}33` : 'none',
  }}/>
);

Object.assign(window, {
  HeardWindow, Pill, Card, Row, Toggle, Btn, Input, SectionLabel, Slider, Segmented, Kbd, Dot,
});
