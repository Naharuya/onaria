(() => {
  const status = document.getElementById('startup-status');
  const retry = document.getElementById('retry');
  window.onariaStartupFailed = () => {
    if (!status?.isConnected) return;
    status.textContent = '앱을 열지 못했어요. 인터넷 연결을 확인하고 다시 열어 주세요.';
    retry.hidden = false;
  };
  retry.addEventListener('click', () => window.location.reload());
  const timeout = window.setTimeout(window.onariaStartupFailed, 30000);
  window.addEventListener('flutter-first-frame', () => {
    window.clearTimeout(timeout);
    document.getElementById('startup')?.remove();
  }, { once: true });
  const script = document.createElement('script');
  script.src = 'flutter_bootstrap.js';
  script.addEventListener('error', window.onariaStartupFailed);
  document.body.appendChild(script);
})();
