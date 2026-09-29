{{flutter_js}}
{{flutter_build_config}}

_flutter.loader.load({
  config: { canvasKitBaseUrl: 'canvaskit/' },
  onEntrypointLoaded: async function(engineInitializer) {
    try {
      const runner = await engineInitializer.initializeEngine({canvasKitBaseUrl: 'canvaskit/'});
      await runner.runApp();
    } catch (_) {
      window.onariaStartupFailed?.();
    }
  }
}).catch(() => window.onariaStartupFailed?.());
