# Whiteboard

A simple whiteboard for teachers, made to be projected during lessons: click anywhere and type in a
handwriting font on notebook lines, draw, highlight, add pictures, run a timer, and save the whole
lesson as one picture.

## Two ways to use it

### 1. Open the link (any computer, nothing to install)

**https://algorbod-max.github.io/whiteboard/**

Works in Chrome or Edge on Windows, Mac or Chromebook. Everything works except two things that need
the Windows download: *handwriting → typed text*, and saving lessons into a folder (in the web
version, lesson pictures go to your **Downloads** folder). Your work stays in your own browser.

### 2. Download the full version (Windows)

1. Click the green **Code** button above → **Download ZIP**, and unzip it anywhere
   (for example in Documents).
2. Double-click **Start Whiteboard**. The whiteboard opens in its own window.
   - The first time, Windows may say the file comes from the internet: click
     **More info → Run anyway** (or right-click the file → Properties → tick **Unblock**).
3. For a desktop icon: right-click **Start Whiteboard** → *Send to* → *Desktop (create shortcut)*.
   You can give the shortcut the icon `whiteboard.ico` (right-click → Properties → Change Icon).

The download version adds:
- **✨ Smart handwriting**: what you write with the pen becomes typed text, using Windows' own
  handwriting reader (offline). It needs English handwriting, which Windows installs with the
  English language.
- Lesson pictures are saved automatically in the `Sessions` folder next to the files.

A small helper (`whiteboard-helper.ps1`, plain Windows PowerShell) runs in the background while
you use it. It only answers this computer, and stops by itself 30 minutes after you close the
whiteboard.

## What it does

- **Type**: click anywhere and type; text sits on the notebook lines. Enter = new line, Esc = done.
- **Pen, highlighter, eraser, move**; 5 colours; sizes S / M / L; 3 writing styles.
- **✨ Smart**: rough circles, squares, triangles and lines become clean shapes; drawings
  (stick figures, faces, bubbles…) get suggestions of clean pictures; it learns your way of drawing.
- **Pictures**: 138 drawings in 14 groups (people, faces, bubbles, animals, food, clothes, school,
  places, nature, transport, symbols…).
- **Pages** and **Scroll** (a board bigger than the screen, with a mini map).
- **Timer** for assignments, quizzes, tests… with a big countdown and a ring at the end.
- **Start lesson / End lesson**: at the end every page of the lesson is saved as one picture,
  named with the date, course, session and start–end time.
- **Themes**: whiteboard, blackboard, green chalkboard; backgrounds: lines, grid, plain.
- Keys: Ctrl+Z undo, Ctrl+Y redo, Page Up / Page Down pages, Tab hides the toolbar, F11 full screen.
