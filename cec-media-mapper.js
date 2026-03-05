const { execFileSync } = require('child_process');

function parseBoolean(value, defaultValue) {
  if (value == null || value === '') {
    return defaultValue;
  }
  return /^(1|true|yes)$/i.test(String(value));
}

function createCecMediaMapper(options = {}) {
  const enabled = parseBoolean(options.enabled, true);
  const verbose = parseBoolean(options.verbose, false);
  const osascriptBin = options.osascriptBin || 'osascript';
  const player = (options.player || 'Spotify').trim();

  const playPauseScript = [`tell application "${player}" to playpause`];
  const pauseScript = [`tell application "${player}" to pause`];
  const nextTrackScript = [`tell application "${player}" to next track`];
  const prevTrackScript = [`tell application "${player}" to previous track`];

  function runScript(lines) {
    if (!enabled) {
      return;
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
    } catch (err) {
      if (verbose) {
        console.error('CEC media mapper command failed:', err.message);
      }
    }
  }

  function handleKey(keyName) {
    const normalized = (keyName || '').toLowerCase();
    switch (normalized) {
      case 'play':
      case 'pause':
      case 'play_function':
      case 'pause_play_function':
        runScript(playPauseScript);
        if (verbose) {
          console.log(`CEC media mapper handled key: ${normalized}`);
        }
        break;
      case 'stop':
      case 'stop_function':
        runScript(pauseScript);
        if (verbose) {
          console.log(`CEC media mapper handled key: ${normalized}`);
        }
        break;
      case 'fast_forward':
      case 'forward':
        runScript(nextTrackScript);
        if (verbose) {
          console.log(`CEC media mapper handled key: ${normalized}`);
        }
        break;
      case 'rewind':
      case 'backward':
        runScript(prevTrackScript);
        if (verbose) {
          console.log(`CEC media mapper handled key: ${normalized}`);
        }
        break;
      default:
        break;
    }
  }

  return {
    handleKey,
  };
}

module.exports = {
  createCecMediaMapper,
};
