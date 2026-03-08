const { execFileSync } = require('child_process');

function parseBoolean(value, defaultValue) {
  if (value == null || value === '') {
    return defaultValue;
  }
  return /^(1|true|yes)$/i.test(String(value));
}

function createCecKeyboardMapper(options = {}) {
  const enabled = parseBoolean(options.enabled, true);
  const verbose = parseBoolean(options.verbose, false);
  const osascriptBin = options.osascriptBin || 'osascript';

  function runScript(lines) {
    if (!enabled) {
      return false;
    }

    const args = [];
    for (const line of lines) {
      args.push('-e', line);
    }

    try {
      execFileSync(osascriptBin, args, {
        stdio: ['ignore', 'pipe', 'pipe'],
        encoding: 'utf8',
      });
      return true;
    } catch (err) {
      if (verbose) {
        console.error('CEC keyboard mapper command failed:', err.message);
      }
      return false;
    }
  }

  function sendKeyCode(keyCode, label) {
    const ok = runScript([
      'tell application "System Events"',
      `  key code ${keyCode}`,
      'end tell',
    ]);
    if (verbose) {
      console.log(`CEC keyboard mapper sent ${label}: ${ok ? 'ok' : 'failed'}`);
    }
    return ok;
  }

  function sendEscape() {
    return sendKeyCode(53, 'Escape');
  }

  function sendEnter() {
    return sendKeyCode(36, 'Enter');
  }

  function sendArrow(direction) {
    const keyCodeByDirection = {
      up: 126,
      down: 125,
      left: 123,
      right: 124,
    };
    const normalized = (direction || '').toLowerCase();
    const code = keyCodeByDirection[normalized];
    if (code == null) {
      return false;
    }
    return sendKeyCode(code, `${normalized} arrow`);
  }

  return {
    sendEscape,
    sendEnter,
    sendArrow,
  };
}

module.exports = {
  createCecKeyboardMapper,
};
