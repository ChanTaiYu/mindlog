// Builds the MindLog CW2 report (Word .docx) with embedded screenshots.
const path = require('path');
const fs = require('fs');
const GLOBAL = require('child_process').execSync('npm root -g').toString().trim();
const {
  Document, Packer, Paragraph, TextRun, Table, TableRow, TableCell, ImageRun,
  AlignmentType, LevelFormat, TableOfContents, HeadingLevel, BorderStyle,
  WidthType, ShadingType, PageNumber, Header, Footer, PageBreak, ExternalHyperlink,
} = require(path.join(GLOBAL, 'docx'));

const DOCS = __dirname;
const IMGW = 165, IMGH = Math.round(165 * 1400 / 630); // 630x1400 aspect

const P = (text, opts = {}) =>
  new Paragraph({ spacing: { after: 120, line: 276 }, ...opts,
    children: typeof text === 'string' ? [new TextRun(text)] : text });
const H1 = (t) => new Paragraph({ heading: HeadingLevel.HEADING_1, children: [new TextRun(t)] });
const H2 = (t) => new Paragraph({ heading: HeadingLevel.HEADING_2, children: [new TextRun(t)] });

let figN = 0;
function figure(file, caption) {
  figN += 1;
  return [
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 120, after: 40 },
      children: [new ImageRun({ type: 'png', data: fs.readFileSync(path.join(DOCS, file)),
        transformation: { width: IMGW, height: IMGH },
        altText: { title: caption, description: caption, name: file } })] }),
    new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 200 },
      children: [new TextRun({ text: `Figure ${figN}: ${caption}`, italics: true, size: 18, color: '555555' })] }),
  ];
}
function figurePair(f1, c1, f2, c2) {
  figN += 1; const n1 = figN; figN += 1; const n2 = figN;
  const nb = { style: BorderStyle.NONE, size: 0, color: 'FFFFFF' };
  const borders = { top: nb, bottom: nb, left: nb, right: nb };
  const cell = (file, n, cap) => new TableCell({
    borders, width: { size: 4680, type: WidthType.DXA },
    margins: { top: 40, bottom: 40, left: 40, right: 40 },
    children: [
      new Paragraph({ alignment: AlignmentType.CENTER,
        children: [new ImageRun({ type: 'png', data: fs.readFileSync(path.join(DOCS, file)),
          transformation: { width: IMGW, height: IMGH },
          altText: { title: cap, description: cap, name: file } })] }),
      new Paragraph({ alignment: AlignmentType.CENTER,
        children: [new TextRun({ text: `Figure ${n}: ${cap}`, italics: true, size: 18, color: '555555' })] }),
    ] });
  return [ new Table({ width: { size: 9360, type: WidthType.DXA }, columnWidths: [4680, 4680],
    rows: [ new TableRow({ children: [cell(f1, n1, c1), cell(f2, n2, c2)] }) ] }),
    new Paragraph({ spacing: { after: 160 }, children: [] }) ];
}

const cb = { style: BorderStyle.SINGLE, size: 1, color: 'CCCCCC' };
const cbs = { top: cb, bottom: cb, left: cb, right: cb };
function tcell(text, w, opts = {}) {
  return new TableCell({ borders: cbs, width: { size: w, type: WidthType.DXA },
    margins: { top: 80, bottom: 80, left: 120, right: 120 },
    shading: opts.head ? { fill: 'D5E0F5', type: ShadingType.CLEAR } : undefined,
    children: [new Paragraph({ children: [new TextRun({ text, bold: !!opts.head, size: 20 })] })] });
}
const features = [
  ['Secure access', 'Passcode setup and lock screen, optional biometric (fingerprint/face) unlock, and automatic locking when the app is backgrounded.'],
  ['Diary entries', 'Create, edit and delete entries with a title, body, date, mood and an optional photo from the camera or gallery.'],
  ['Mood tracking', 'A five-point mood is attached to every entry; the dashboard plots the average daily mood as a weekly trend chart.'],
  ['Task planner', 'A to-do list to add tasks, tick them off and swipe to delete, with open/done counts.'],
  ['Mood–productivity insight', 'Correlates average mood against the number of tasks completed each day and summarises the relationship in plain language.'],
  ['Mood-tagged search & On this day', 'Search entries by free text and/or mood, and resurface entries written on the same date in previous years.'],
  ['Daily reminder', 'A configurable local notification that prompts the user to journal at a chosen time.'],
  ['Quote of the day', 'An inspirational quote fetched from an external REST API (ZenQuotes) with an offline fallback.'],
];
const featureTable = new Table({
  width: { size: 9360, type: WidthType.DXA }, columnWidths: [2500, 5460, 1400],
  rows: [
    new TableRow({ tableHeader: true, children: [
      tcell('Feature / Module', 2500, { head: true }),
      tcell('Description', 5460, { head: true }),
      tcell('Developed by', 1400, { head: true }) ] }),
    ...features.map(([f, d]) => new TableRow({ children: [
      tcell(f, 2500), tcell(d, 5460), tcell('Chan Tai Yu', 1400) ] })),
  ],
});

const doc = new Document({
  creator: 'Chan Tai Yu',
  title: 'MindLog – CW2 Project Report',
  styles: {
    default: { document: { run: { font: 'Arial', size: 22 } } },
    paragraphStyles: [
      { id: 'Heading1', name: 'Heading 1', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 30, bold: true, font: 'Arial', color: '1F3864' },
        paragraph: { spacing: { before: 280, after: 160 }, outlineLevel: 0 } },
      { id: 'Heading2', name: 'Heading 2', basedOn: 'Normal', next: 'Normal', quickFormat: true,
        run: { size: 25, bold: true, font: 'Arial', color: '2E5496' },
        paragraph: { spacing: { before: 200, after: 120 }, outlineLevel: 1 } },
    ],
  },
  numbering: { config: [
    { reference: 'bullets', levels: [{ level: 0, format: LevelFormat.BULLET, text: '•',
      alignment: AlignmentType.LEFT, style: { paragraph: { indent: { left: 720, hanging: 360 } } } }] },
  ] },
  sections: [{
    properties: { page: { size: { width: 12240, height: 15840 },
      margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } } },
    footers: { default: new Footer({ children: [ new Paragraph({ alignment: AlignmentType.CENTER,
      children: [ new TextRun({ text: 'MindLog – 6002CEM CW2   |   Page ', size: 18, color: '888888' }),
        new TextRun({ children: [PageNumber.CURRENT], size: 18, color: '888888' }) ] }) ] }) },
    children: [
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { before: 200, after: 60 },
        children: [new TextRun({ text: 'MindLog', bold: true, size: 56, color: '1F3864' })] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 40 },
        children: [new TextRun({ text: 'A Private, Encrypted Journal, Mood Tracker & Task Planner', size: 26, color: '2E5496' })] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 40 },
        children: [new TextRun({ text: 'CW2 Project Report – 6002CEM Mobile App Development', size: 22 })] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 40 },
        children: [new TextRun({ text: 'Chan Tai Yu (Individual Submission)', size: 22, bold: true })] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 40 },
        children: [ new TextRun({ text: 'GitHub: ', size: 22 }),
          new ExternalHyperlink({ link: 'https://github.com/ChanTaiYu/mindlog',
            children: [new TextRun({ text: 'https://github.com/ChanTaiYu/mindlog', style: 'Hyperlink', size: 22 })] }) ] }),
      new Paragraph({ alignment: AlignmentType.CENTER, spacing: { after: 200 },
        children: [new TextRun({ text: 'Note: This report follows the official coursework cover sheet (pages 1–2 of the module template).', italics: true, size: 18, color: '777777' })] }),

      new Paragraph({ children: [new PageBreak()] }),
      new Paragraph({ spacing: { after: 120 }, children: [new TextRun({ text: 'Table of Contents', bold: true, size: 28, color: '1F3864' })] }),
      new TableOfContents('Table of Contents', { hyperlink: true, headingStyleRange: '1-2' }),
      new Paragraph({ children: [new PageBreak()] }),

      H1('1. Introduction'),
      P('MindLog is a mobile application built with the Flutter framework and the Dart language. It develops the concept proposed in Coursework 1 into a working product. The central idea is that reflection, emotion and action are connected and should live in one place: rather than juggling a separate journal, mood tracker and to-do app, MindLog brings them together so that patterns between how a person feels and what they do become visible.'),
      P('The application is aimed at anyone who wants to build a daily journaling habit while keeping their thoughts genuinely private. Because a personal diary is sensitive data, MindLog is designed to be private by default: every entry is encrypted on the device and protected by a passcode, with optional biometric unlock for convenience. This directly addresses the module learning outcome of scoping, designing and implementing a basic security policy for confidential data on a mobile device.'),
      P('Beyond the core journaling experience, MindLog adds value that comparable apps rarely combine. Because mood and completed tasks are stored together, the app can show how a user’s mood relates to their productivity; entries can be searched by mood and resurfaced on their anniversary; and a daily quote fetched from an external service provides a small moment of encouragement. The result is a feature-rich, security-conscious application that demonstrates UI design, local persistence, sensor and API integration, and state management.'),
      P('This report lists the application’s features, describes each module in detail with screenshots, evaluates the app’s strengths and limitations, proposes future enhancements, and closes with a personal reflection.'),

      H1('2. Features and Contributions'),
      P('This is an individual project, so all modules were designed and implemented by Chan Tai Yu. The table below summarises the features delivered. The application contains eight feature areas spread across nine screens, integrates two device sensors (biometric and camera) and one external API, and persists all data in an encrypted local database.'),
      featureTable,
      new Paragraph({ spacing: { after: 120 }, children: [] }),

      H1('3. Module Descriptions'),
      P('Each module below is labelled with its developer (Chan Tai Yu for all modules) and illustrated with screenshots captured from the app running on an Android emulator with sample data loaded.'),

      H2('3.1 Secure Access (Chan Tai Yu)'),
      P('On first launch the user is asked to create a passcode. The passcode is never stored directly. Instead it is stretched into a 256-bit key using PBKDF2-HMAC-SHA256 with a random per-installation salt, and that derived key becomes the encryption key for the database. A short verifier hash is stored so the passcode can be checked quickly, while the device keystore (via flutter_secure_storage) holds the salt and, when biometric unlock is enabled, a protected copy of the key. On subsequent launches the lock screen requires the passcode, and if the user has enrolled a fingerprint or face it can be used to unlock instead. The whole application sits behind this gate and re-locks automatically whenever it is sent to the background.'),
      ...figurePair('shot_setup.png', 'First-run passcode creation', 'shot_lock.png', 'Lock screen on every launch'),

      H2('3.2 Diary Entries (Chan Tai Yu)'),
      P('The diary module provides full create, read, update and delete (CRUD) functionality. An entry has a title, a free-text body, a date, a selected mood and an optional photo attachment. The editor lets the user pick a mood from a five-point scale, choose the date, type the entry, and attach an image taken with the camera or chosen from the gallery using the image_picker plugin; the picked image is copied into the app’s private storage so it persists. Entries are listed newest-first, each card showing the mood, title, date and a short preview, and tapping a card opens a detail view with edit and delete actions.'),
      ...figurePair('shot_diary.png', 'Diary list of entries', 'shot_editor.png', 'Entry editor with the mood picker'),

      H2('3.3 Mood Tracking & Dashboard (Chan Tai Yu)'),
      P('Every entry records a mood on a scale from Awful (1) to Great (5). The home dashboard turns these into insight at a glance: it greets the user, shows the quote of the day, displays quick statistics (number of entries and open tasks), and plots the average daily mood for the past week as a smooth line chart built with the fl_chart library. The dashboard also resurfaces entries written on the same calendar date in previous years under an “On this day” section when any exist.'),
      ...figure('shot_home.png', 'Home dashboard with quote, statistics and the weekly mood-trend chart'),

      H2('3.4 Task Planner (Chan Tai Yu)'),
      P('The task planner is a lightweight to-do list. Users type a task and press Add, tick it off when complete (it stays in the list with a strikethrough under the “done” count), and swipe left to delete. A summary line shows how many tasks are open versus done. Crucially, each completed task records the time it was completed, which feeds the mood–productivity insight described next.'),
      ...figure('shot_tasks.png', 'Task planner with open and completed tasks'),

      H2('3.5 Mood–Productivity Insight (Chan Tai Yu)'),
      P('This is MindLog’s signature feature. Because moods (from diary entries) and task-completion times are stored in the same database, the Insights screen can relate the two. It aggregates the last fourteen days and presents a bar chart of tasks completed per day, where each bar is coloured by that day’s average mood, alongside a plain-language summary such as whether the user tends to get more done on better-mood days. This turns raw logs into actionable self-knowledge.'),
      ...figure('shot_insights.png', 'Insights screen relating mood to tasks completed over two weeks'),

      H2('3.6 Mood-Tagged Search & On This Day (Chan Tai Yu)'),
      P('The search screen lets the user find past entries by typing free text and/or filtering by a specific mood – for example, surfacing every entry written when they felt anxious. Combined with the dashboard’s “On this day” feature, this makes the journal a resource for reflection rather than a write-only log.'),
      ...figure('shot_search.png', 'Searching entries with a mood filter applied'),

      H2('3.7 Settings, Daily Reminder & Quote API (Chan Tai Yu)'),
      P('The settings screen ties several modules together. The user can switch between light, dark and system themes; enable a daily reminder and choose its time, which schedules a repeating local notification through the flutter_local_notifications plugin (requesting the notification permission on Android 13+); toggle biometric unlock; and change the passcode, which securely re-keys the encrypted database. A “Load sample data” action populates a fortnight of demo entries and tasks for demonstration. Separately, the dashboard’s quote of the day is fetched from the ZenQuotes REST API over HTTPS, with a cached fallback so a quote always appears even when offline.'),
      ...figure('shot_settings.png', 'Settings: theme, reminder, security and data options'),

      H1('4. Strengths of the Application'),
      P('Security by default. The strongest aspect of MindLog is that privacy is built into its foundations rather than added as an afterthought. The database is encrypted at rest using SQLCipher, the encryption key is derived from the user’s passcode with a slow, salted key-derivation function, and sensitive values are kept in the platform keystore. This is a genuine, defensible security policy rather than a token password check.'),
      P('Breadth and depth of functionality. The application offers eight distinct feature areas across nine screens, comfortably exceeding a basic multi-screen app. The features are also interconnected – moods feed the dashboard chart and the insight engine, completed tasks feed the same insight, and entries feed both search and the anniversary view – which gives the app a sense of cohesion.'),
      P('Meaningful use of sensors and an external API. MindLog uses the biometric sensor for authentication, the camera/gallery for photo attachments, and an external REST API for the daily quote. These are used in service of real features rather than for their own sake.'),
      P('Considered, consistent user interface. The app uses Material 3 with a single seeded colour palette, giving a calm and consistent look across light and dark themes. Moods are reinforced with both colour and emoji, charts are clean and labelled, and navigation follows a familiar bottom-bar pattern, making the app easy to learn.'),
      P('Robust and tested. Analytics such as the mood trend and the insight chart are computed from data already held in memory, so screens update instantly. The codebase passes static analysis with no issues and is covered by unit and widget tests – including tests for the PBKDF2 security layer and for the mood picker across screen sizes and font scales – giving confidence in the most important code.'),

      H1('5. Limitations of the Application'),
      P('Local-only storage with no backup. The deliberate local-first, encrypted design has a trade-off: there is currently no cloud backup or synchronisation. If the device is lost or the app’s data is cleared, the journal cannot be recovered. This is acceptable for a privacy-focused prototype but would concern long-term users.'),
      P('Single device and single user. Because data never leaves the device, the same journal cannot be opened on a second device, and there is no concept of multiple user accounts. The encryption is also tied to a numeric passcode; a short passcode is convenient but offers less protection than a full password.'),
      P('Biometric key handling. To support fingerprint/face unlock, a copy of the database key is stored in the keystore and released after a successful biometric check. This is a pragmatic and common approach, but it is a slightly weaker model than re-deriving the key from a secret every time, and it depends on the security of the device keystore.'),
      P('Limited content richness. Entries support a single photo and plain text only – there is no rich formatting, multiple images, voice notes, or free-form tags beyond the mood. Search is substring-based rather than full-text indexed, which is fine at small scale but would not scale to thousands of entries.'),
      P('External service dependence and platform coverage. The quote feature relies on a single third-party API; if that service changes or is unavailable, only the cached or fallback quote is shown. Finally, although the project is configured for both Android and iOS, it was built and tested on Android, so iOS behaviour (particularly around notifications and biometrics) has not been verified.'),

      H1('6. Future Enhancements'),
      P('Several enhancements would build naturally on the current foundation:'),
      new Paragraph({ numbering: { reference: 'bullets', level: 0 }, children: [new TextRun('Encrypted cloud backup and sync, so the journal survives device loss and can be opened on multiple devices, ideally with end-to-end encryption so the server never sees plaintext.')] }),
      new Paragraph({ numbering: { reference: 'bullets', level: 0 }, children: [new TextRun('Richer entries: multiple photos, basic text formatting, voice notes, and user-defined tags in addition to mood.')] }),
      new Paragraph({ numbering: { reference: 'bullets', level: 0 }, children: [new TextRun('Full-text search and an export-to-PDF option so users can archive or print their journal.')] }),
      new Paragraph({ numbering: { reference: 'bullets', level: 0 }, children: [new TextRun('Location and weather tagging using the device GPS and a weather API, adding a second external API/sensor and richer context to each entry.')] }),
      new Paragraph({ numbering: { reference: 'bullets', level: 0 }, children: [new TextRun('A home-screen widget and quick-add shortcut to lower the friction of logging, supporting habit formation.')] }),
      new Paragraph({ numbering: { reference: 'bullets', level: 0 }, children: [new TextRun('Localisation and accessibility improvements (screen-reader labels, dynamic text sizing) to widen the audience.')] }),

      H1('7. Personal Reflection'),
      new Paragraph({ children: [new TextRun({ text: 'Chan Tai Yu', bold: true })], spacing: { after: 80 } }),
      P('Building MindLog taught me how much thought a “simple” journaling app actually requires once privacy is taken seriously. The most valuable thing I learned was designing a practical security policy: deriving an encryption key from a passcode with PBKDF2, using that key to open a SQLCipher database, and storing secrets in the platform keystore. Reasoning about where the key lives at each moment – and the trade-off involved in enabling biometric unlock – made abstract security concepts concrete.'),
      P('I also grew more comfortable with Flutter’s widget model and state management using Provider, and with integrating plugins for biometrics, the camera, notifications and HTTP. Testing on a device taught me the most: I found and fixed a row of mood chips that overflowed at larger font sizes, two screens left blank by invalid layout constraints (a nested Scaffold and a button whose theme forced an infinite width), and a crash on the search screen caused by a setState callback that accidentally returned a Future. Tracking each of these down from the framework’s error output, understanding why it happened, and adding tests to guard against it taught me far more than writing the happy path did.'),
      P('If I were to start again, I would plan the persistence and analytics layer up front so that screens compute from in-memory data from the beginning, and I would set up a device test loop earlier to catch layout issues sooner. Overall I am proud that the app is both feature-rich and genuinely secure, and I finish the module much more confident in mobile development.'),

      H1('8. Conclusion'),
      P('MindLog delivers a cohesive, security-first mobile application that unites journaling, mood tracking and task management, and adds original value by relating mood to productivity. It demonstrates multi-screen UI design, encrypted local persistence with authentication, sensor and external-API integration, and tested, statically clean code – meeting and extending the goals set out in Coursework 1.'),
    ],
  }],
});

Packer.toBuffer(doc).then((buffer) => {
  const out = path.join(DOCS, '..', 'MindLog_CW2_Report.docx');
  fs.writeFileSync(out, buffer);
  console.log('WROTE ' + out + ' (' + buffer.length + ' bytes)');
});
