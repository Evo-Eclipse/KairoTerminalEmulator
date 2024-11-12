# KairoTerminalEmulator

### Overview / Обзор

KairoTerminalEmulator is a straightforward terminal emulator developed in Swift, utilizing SwiftUI for its graphical user interface. This project was initiated as an academic exercise and marks my first venture into working with SwiftUI. The objective was to create a shell-like experience akin to a UNIX environment, complete with a user-friendly GUI.

KairoTerminalEmulator — это простой эмулятор терминала, разработанный на языке Swift с использованием SwiftUI для графического интерфейса. Проект был создан в учебных целях и представляет собой мой первый опыт работы с SwiftUI. Цель заключалась в создании графического интерфейса, напоминающего оболочку в UNIX-подобной среде.

----

**Installation / Установка**

1. **Clone the repository:**
   - Use `git clone` to download the repository to your local machine.
   - Используйте `git clone` для загрузки репозитория на локальный компьютер.
2. **Open the project in Xcode:**
   - Navigate to the project folder and open project folder.
   - Перейдите в папку проекта и откройте папку проекта.
3. **Build and run the application:**
   - Click the "Play" button in Xcode to build and run the app.
   - Нажмите кнопку "Play" в Xcode, чтобы собрать и запустить приложение.

----

**Configuration / Конфигурация**

- The emulator requires a YAML configuration file, which includes:
   - A username for prompt display.
   - A path to a virtual filesystem archive (tar format).
   - A path to a log file (csv format).
- Эмулятор использует YAML файл конфигурации, который содержит:
   - Имя пользователя для показа в приглашении к вводу.
   - Путь к архиву виртуальной файловой системы (в формате tar).
   - Путь к лог-файлу (в формате csv).

**Example formatting / Пример заполнения:**

```yaml
username: "<USERNAME>"
tarFilePath: "/Users/<USERNAME>/Documents//filesystem.tar"
logFilePath: "/Users/<USERNAME>/Documents/log.csv"
```

----

**Usage / Использование**

- **Supported commands:** `ls`, `cd`, `exit`, `head`, `cp`, `du`.
- The emulator simulates a basic shell session in a UNIX-like environment.
- **Поддерживаемые команды:** `ls`, `cd`, `exit`, `head`, `cp`, `du`.
- Эмулятор имитирует простой сеанс shell в подобной UNIX среде.

----

**Testing / Тестирование**

- Functional tests are implemented using `Swift Tests` for the core code and `XCTest` for GUI components.
- Each command is validated by at least two unit tests to ensure basic functionality.
- Функциональные тесты написаны с помощью `Swift Tests` для основного кода и `XCTest` для GUI компонентов.
- Каждая команда проверена как минимум двумя юнит-тестами для обеспечения основной функциональности.

----

**Disclaimer / Ответственность**

- This project was developed for academic purposes and marks my initial experience with SwiftUI. The code is not optimized for production and was crafted "on the fly" to meet the assignment requirements.
- Проект создан исключительно в академических целях и представляет мой первый опыт работы с SwiftUI. Код не оптимизирован для продакшн-использования и был создан исключительно для выполнения требований задания.

