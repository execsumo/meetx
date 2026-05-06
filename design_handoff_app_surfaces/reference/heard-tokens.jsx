/* Heard — design tokens + icons. Loaded as Babel script; exports to window. */
/* eslint-disable */

const FONT_UI = '-apple-system, BlinkMacSystemFont, "SF Pro Text", system-ui, sans-serif';
const FONT_DISPLAY = '-apple-system, BlinkMacSystemFont, "SF Pro Display", system-ui, sans-serif';
const FONT_MONO = 'ui-monospace, SFMono-Regular, "SF Mono", Menlo, monospace';

const PAPER = {
  bg:          '#F5EFE4',
  surface:     '#FBF7EF',
  surfaceAlt:  '#EFE7D7',
  sidebar:     '#EBE2CE',
  border:      '#D9CFB9',
  borderSoft:  '#E5DCC8',
  ink:         '#1C2024',
  ink2:        '#3A3F47',
  mute:        '#7B7264',
  muteSoft:    '#C9BBA5',
  shadow:      'rgba(60, 45, 20, 0.06)',
  shadowDeep:  'rgba(60, 45, 20, 0.18)',
  accent:      '#3F5C8C',
  accentInk:   '#2F4570',
  accentSoft:  '#E5EAF3',
  good:        '#3D7A4F',
  goodSoft:    '#E1EEDF',
  warn:        '#A66A1F',
  warnSoft:    '#F4E6CE',
  bad:         '#A6452B',
  badSoft:     '#F2DCD2',
  recordingBg: '#2E3338',
  recordingInk:'#F5EFE4',
};

// Compact, hand-drawn SF-Symbol-style icon set.
const Icon = ({ name, size = 14, color = 'currentColor' }) => {
  const s = size, c = color, sw = Math.max(1.3, size / 11);
  const w = (children) => (
    <svg width={s} height={s} viewBox="0 0 16 16" fill="none" style={{ flexShrink: 0, display: 'block' }}>{children}</svg>
  );
  switch (name) {
    case 'gear': return w(<g><circle cx="8" cy="8" r="2.2" stroke={c} strokeWidth={sw}/><path d="M8 1.5v1.6M8 12.9v1.6M14.5 8h-1.6M3.1 8H1.5M12.6 3.4l-1.1 1.1M4.5 11.5l-1.1 1.1M12.6 12.6l-1.1-1.1M4.5 4.5L3.4 3.4" stroke={c} strokeWidth={sw} strokeLinecap="round"/></g>);
    case 'mic': return w(<g><rect x="6" y="1.8" width="4" height="8" rx="2" stroke={c} strokeWidth={sw}/><path d="M3.6 8c0 2.4 2 4.4 4.4 4.4S12.4 10.4 12.4 8M8 12.4v2.2" stroke={c} strokeWidth={sw} strokeLinecap="round"/></g>);
    case 'keyboard': return w(<g><rect x="1.5" y="4" width="13" height="8" rx="1.5" stroke={c} strokeWidth={sw}/><path d="M4 7h.01M6.5 7h.01M9 7h.01M11.5 7h.01M4 9.6h8" stroke={c} strokeWidth={sw} strokeLinecap="round"/></g>);
    case 'cube': return w(<g><path d="M8 1.6L14 4.6v6.8L8 14.4 2 11.4V4.6z" stroke={c} strokeWidth={sw} strokeLinejoin="round"/><path d="M2 4.6l6 3 6-3M8 7.6v6.8" stroke={c} strokeWidth={sw}/></g>);
    case 'people': return w(<g><circle cx="6" cy="6" r="2.2" stroke={c} strokeWidth={sw}/><path d="M2 13c.4-2 2-3.4 4-3.4s3.6 1.4 4 3.4" stroke={c} strokeWidth={sw} strokeLinecap="round"/><circle cx="11.6" cy="5.6" r="1.8" stroke={c} strokeWidth={sw}/><path d="M9.6 9.4c.6-.3 1.3-.5 2-.5 1.6 0 2.9 1.2 2.9 2.8" stroke={c} strokeWidth={sw} strokeLinecap="round"/></g>);
    case 'bubble': return w(<g><path d="M2 5.4C2 4 3 3 4.4 3h7.2C13 3 14 4 14 5.4v3.4c0 1.4-1 2.4-2.4 2.4h-3l-2.6 2v-2H4.4C3 11.2 2 10.2 2 8.8z" stroke={c} strokeWidth={sw} strokeLinejoin="round"/><circle cx="6" cy="7" r=".9" fill={c}/><circle cx="8" cy="7" r="1.1" fill={c}/><circle cx="10" cy="7" r=".9" fill={c}/></g>);
    case 'folder': return w(<g><path d="M1.8 4.4c0-.8.6-1.4 1.4-1.4h3l1.4 1.4h5.2c.8 0 1.4.6 1.4 1.4v6.4c0 .8-.6 1.4-1.4 1.4H3.2c-.8 0-1.4-.6-1.4-1.4z" stroke={c} strokeWidth={sw} strokeLinejoin="round"/></g>);
    case 'check': return w(<g><path d="M3 8.4l3 3 7-7.4" stroke={c} strokeWidth={sw + 0.4} strokeLinecap="round" strokeLinejoin="round"/></g>);
    case 'x': return w(<g><path d="M4 4l8 8M12 4l-8 8" stroke={c} strokeWidth={sw + 0.2} strokeLinecap="round"/></g>);
    case 'plus': return w(<g><path d="M8 3v10M3 8h10" stroke={c} strokeWidth={sw + 0.2} strokeLinecap="round"/></g>);
    case 'arrow.down': return w(<g><path d="M8 2v10M3.5 8L8 12.5 12.5 8" stroke={c} strokeWidth={sw + 0.2} strokeLinecap="round" strokeLinejoin="round"/></g>);
    case 'play': return w(<g><path d="M4.5 3.2L12 8 4.5 12.8z" fill={c}/></g>);
    case 'stop': return w(<g><rect x="4" y="4" width="8" height="8" rx="1" fill={c}/></g>);
    case 'wave': return w(<g><path d="M2 8h1.6M5 5.5v5M7 4v8M9 6v4M11 5v6M13 7v2" stroke={c} strokeWidth={sw + 0.4} strokeLinecap="round"/></g>);
    case 'magnifier': return w(<g><circle cx="7" cy="7" r="4" stroke={c} strokeWidth={sw}/><path d="M10 10l3 3" stroke={c} strokeWidth={sw + 0.2} strokeLinecap="round"/></g>);
    case 'trash': return w(<g><path d="M3 4.5h10M5.5 4.5V3.2c0-.6.5-1.1 1.1-1.1h2.8c.6 0 1.1.5 1.1 1.1v1.3M4 4.5l.7 8.4c.05.6.55 1.1 1.15 1.1h4.3c.6 0 1.1-.5 1.15-1.1L12 4.5" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"/></g>);
    case 'merge': return w(<g><path d="M3 3v3.5c0 1.5 1 2.5 2.5 2.5H8M13 3v3.5c0 1.5-1 2.5-2.5 2.5H8M8 9v4M6 11l2 2 2-2" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"/></g>);
    case 'bolt': return w(<g><path d="M9 1.5L3 9h4l-1 5.5L13 7H9z" stroke={c} strokeWidth={sw} strokeLinejoin="round" fill="none"/></g>);
    case 'shield': return w(<g><path d="M8 1.5L2.5 3.5v5C2.5 12 5 13.6 8 14.5c3-.9 5.5-2.5 5.5-6V3.5z" stroke={c} strokeWidth={sw} strokeLinejoin="round"/></g>);
    case 'help': return w(<g><circle cx="8" cy="8" r="6" stroke={c} strokeWidth={sw}/><path d="M6.4 6c.2-.9 1-1.6 1.9-1.6 1.1 0 1.9.8 1.9 1.8 0 .8-.4 1.2-1.2 1.6-.7.3-.9.7-.9 1.2v.4M8 11.5v.6" stroke={c} strokeWidth={sw} strokeLinecap="round"/></g>);
    case 'chevron.right': return w(<g><path d="M6 3.5L10.5 8 6 12.5" stroke={c} strokeWidth={sw + 0.2} strokeLinecap="round" strokeLinejoin="round"/></g>);
    case 'arrow.right': return w(<g><path d="M3 8h10M9 4l4 4-4 4" stroke={c} strokeWidth={sw + 0.2} strokeLinecap="round" strokeLinejoin="round"/></g>);
    case 'record': return w(<g><circle cx="8" cy="8" r="6" stroke={c} strokeWidth={sw}/><circle cx="8" cy="8" r="2.6" fill={c}/></g>);
    case 'power': return w(<g><path d="M8 2v6" stroke={c} strokeWidth={sw + 0.2} strokeLinecap="round"/><path d="M4.5 4.5a4.8 4.8 0 1 0 7 0" stroke={c} strokeWidth={sw} strokeLinecap="round"/></g>);
    case 'info': return w(<g><circle cx="8" cy="8" r="6" stroke={c} strokeWidth={sw}/><path d="M8 7v4M8 4.6v.01" stroke={c} strokeWidth={sw + 0.2} strokeLinecap="round"/></g>);
    case 'warn': return w(<g><path d="M8 2L14.5 13H1.5z" stroke={c} strokeWidth={sw} strokeLinejoin="round"/><path d="M8 6.5v3.2M8 11.5v.01" stroke={c} strokeWidth={sw + 0.2} strokeLinecap="round"/></g>);
    case 'cpu': return w(<g><rect x="4" y="4" width="8" height="8" rx="1" stroke={c} strokeWidth={sw}/><rect x="6.5" y="6.5" width="3" height="3" stroke={c} strokeWidth={sw}/><path d="M6 1.5v2.5M8 1.5v2.5M10 1.5v2.5M6 12v2.5M8 12v2.5M10 12v2.5M1.5 6h2.5M1.5 8h2.5M1.5 10h2.5M12 6h2.5M12 8h2.5M12 10h2.5" stroke={c} strokeWidth={sw} strokeLinecap="round"/></g>);
    case 'lock': return w(<g><rect x="3.5" y="7" width="9" height="6.5" rx="1.2" stroke={c} strokeWidth={sw}/><path d="M5.5 7V5.2A2.5 2.5 0 0 1 8 2.7a2.5 2.5 0 0 1 2.5 2.5V7" stroke={c} strokeWidth={sw}/></g>);
    case 'screen': return w(<g><rect x="1.5" y="2.5" width="13" height="9" rx="1.2" stroke={c} strokeWidth={sw}/><path d="M5 14h6M8 11.5V14" stroke={c} strokeWidth={sw} strokeLinecap="round"/></g>);
    case 'fig': return w(<g><circle cx="8" cy="3.5" r="1.5" stroke={c} strokeWidth={sw}/><path d="M3 6h10M8 6v3M5 14l3-5 3 5" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"/></g>);
    case 'plug': return w(<g><path d="M5 2v3M11 2v3M3.5 5h9v3a4.5 4.5 0 0 1-9 0zM8 13v1.5" stroke={c} strokeWidth={sw} strokeLinecap="round" strokeLinejoin="round"/></g>);
    case 'sparkle': return w(<g><path d="M8 2v3M8 11v3M2 8h3M11 8h3" stroke={c} strokeWidth={sw} strokeLinecap="round"/><path d="M5 5l1.5 1.5M9.5 9.5L11 11M5 11l1.5-1.5M9.5 6.5L11 5" stroke={c} strokeWidth={sw} strokeLinecap="round"/></g>);
    case 'sun': return w(<g><circle cx="8" cy="8" r="2.6" stroke={c} strokeWidth={sw}/><path d="M8 1.5v1.6M8 12.9v1.6M14.5 8h-1.6M3.1 8H1.5M12.6 3.4l-1.1 1.1M4.5 11.5l-1.1 1.1M12.6 12.6l-1.1-1.1M4.5 4.5L3.4 3.4" stroke={c} strokeWidth={sw} strokeLinecap="round"/></g>);
    case 'moon': return w(<g><path d="M13 9.5A5.5 5.5 0 0 1 6.5 3a5 5 0 1 0 6.5 6.5z" stroke={c} strokeWidth={sw} strokeLinejoin="round"/></g>);
    default: return w(<circle cx="8" cy="8" r="3" stroke={c} strokeWidth={sw}/>);
  }
};

// Heard bubble glyph (matches the chosen app icon, simplified for chrome use).
const HeardMark = ({ size = 32 }) => (
  <svg width={size} height={size} viewBox="0 0 64 64" fill="none" style={{ display: 'block' }}>
    <rect width="64" height="64" rx="14" fill="url(#hm-bg)"/>
    <path d="M16 22c0-3.3 2.7-6 6-6h20c3.3 0 6 2.7 6 6v14c0 3.3-2.7 6-6 6H35l-7 6v-6h-6c-3.3 0-6-2.7-6-6z" fill="url(#hm-ink)"/>
    <circle cx="24" cy="29" r="2.4" fill="#E8DFD2" opacity="0.65"/>
    <circle cx="32" cy="29" r="3.2" fill="#E8DFD2"/>
    <circle cx="40" cy="29" r="2.4" fill="#E8DFD2" opacity="0.65"/>
    <defs>
      <linearGradient id="hm-bg" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#E8DFD2"/><stop offset="100%" stopColor="#C9BBA5"/></linearGradient>
      <linearGradient id="hm-ink" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stopColor="#2E3338"/><stop offset="100%" stopColor="#1C2024"/></linearGradient>
    </defs>
  </svg>
);

Object.assign(window, { FONT_UI, FONT_DISPLAY, FONT_MONO, PAPER, Icon, HeardMark });
