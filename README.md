# Pocket Cat

Two versions: English first, then Russian.

---

## 🇬🇧 English (EN)

This is a hobby project — a block-based game builder inspired by Pocket Up, but built with LÖVE instead of Corona.

Why LÖVE? Because I wanted something cross-platform that works on PC, phones, and maybe even toasters (okay, not toasters). The code is rough, the UI is clunky, but it kinda works.

If you're looking for a polished game maker, this isn't it. If you want to tinker, break things, or contribute — be my guest.

### What's inside

- Drag-and-drop blocks with editable params (numbers, letters, +, -).
- Scenes and objects (switch, add, delete).
- A basic sprite editor (pixel-level, nothing fancy).
- Variables and simple math in block parameters (like `x+10`).
- Save/load projects as JSON (`.cat` files).
- Auto-build for Android (arm64 APK) and Windows portable EXE via GitHub Actions.

### How to run

Get LÖVE 11.5, then open the project folder as a love app.  
On Android, build the APK or grab a pre-built one from Actions/Releases.  
For everything else — read the code, it's self-documenting (kinda).

### Known issues

- Block dragging is janky, especially with nested blocks.
- Mobile UI isn't really optimised (fullscreen only).
- No proper docs, sorry.

### Developers

- **derka** — UI, block system, sprite editor, debugging, architecture, core logic, Android build.
- **dimas4ek229** — idea.

We're not actively maintaining this, but PRs are welcome.  
Use it, break it, fix it — it's MIT.

---

## 🇷🇺 Русская версия (RU)

Это хобби-проект — конструктор игр на блоках, вдохновлённый Pocket Up, но написанный на LÖVE, а не на Corona.

Почему LÖVE? Потому что хотелось кроссплатформенности, чтобы работало и на ПК, и на телефонах. Код сыроват, интерфейс неидеален, но в целом оно работает.

Если вы ищете готовый инструмент для создания игр — это не оно. Если хотите покопаться, поломать или доработать — добро пожаловать.

### Что внутри

- Блоки с параметрами (перетаскивание, редактирование: цифры, буквы, +, -).
- Сцены и объекты (переключение, добавление, удаление).
- Примитивный редактор спрайтов (попиксельный, без наворотов).
- Переменные и простая арифметика в параметрах (типа `x+10`).
- Сохранение/загрузка проектов в JSON (файлы `.cat`).
- Автосборка APK (только arm64) и портативного EXE через GitHub Actions.

### Как запустить

Поставьте LÖVE 11.5, откройте папку проекта как love-приложение.  
На Android — соберите APK или возьмите готовый из Actions/Releases.  
Всё остальное — в коде, он сам себя документирует (ну, почти).

### Известные проблемы

- Перетаскивание блоков работает с костылями, особенно с вложенными.
- Интерфейс под мобилки не оптимизирован (только полноэкранный режим).
- Нормальной документации нет, извините.

### Разработчики

- **derka** — интерфейс, система блоков, редактор спрайтов, отладка, архитектура, ядро, сборка под Android.
- **dimas4ek229** — идея.

Мы не поддерживаем проект активно, но пул-реквесты принимаются.  
Используйте, ломайте, чините — код под MIT.
