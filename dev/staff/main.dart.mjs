// Compiles a dart2wasm-generated main module from `source` which can then
// instantiatable via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm modules from `bytes` which is then
// instantiatable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {builtins: ['js-string']};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export async function instantiate(modulePromise, importObjectPromise) {
  var moduleOrCompiledApp = await modulePromise;
  if (!(moduleOrCompiledApp instanceof CompiledApp)) {
    moduleOrCompiledApp = new CompiledApp(moduleOrCompiledApp);
  }
  const instantiatedApp = await moduleOrCompiledApp.instantiate(await importObjectPromise);
  return instantiatedApp.instantiatedModule;
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredModules` is a JS function that takes an array of module names
  //   matching wasm files produced by the dart2wasm compiler. It also takes a
  //   callback that should be invoked for each loaded module with 2 arugments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDeferredId` is a JS function that takes load ID produced by the
  //   compiler when the `load-ids` option is passed. Each load ID maps to one
  //   or more wasm files as specified in the emitted JSON file. It also takes a
  //   callback that should be invoked for each loaded module with 2 arugments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDynamicModule` is a JS function that takes two string names matching,
  //   in order, a wasm file produced by the dart2wasm compiler during dynamic
  //   module compilation and a corresponding js file produced by the same
  //   compilation. It also takes a callback that should be invoked with the
  //   loaded module in a format supported by `WebAssembly.compile` or
  //   `WebAssembly.compileStreaming` and the result of using the JS 'import'
  //   API on the js file path. It should return a Promise that resolves when
  //   all the modules have been loaded and the callback promises have resolved.
  async instantiate(additionalImports,
      {loadDeferredModules, loadDynamicModule, loadDeferredId} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + value;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
            _1: (decoder, codeUnits) => decoder.decode(codeUnits),
      _2: () => new TextDecoder("utf-8", {fatal: true}),
      _3: () => new TextDecoder("utf-8", {fatal: false}),
      _4: (s) => +s,
      _5: x0 => new Uint8Array(x0),
      _6: (x0,x1,x2) => x0.set(x1,x2),
      _7: (x0,x1) => x0.transferFromImageBitmap(x1),
      _9: (x0,x1,x2) => x0.slice(x1,x2),
      _10: (x0,x1) => x0.decode(x1),
      _11: (x0,x1) => x0.segment(x1),
      _12: () => new TextDecoder(),
      _14: x0 => x0.buffer,
      _15: x0 => x0.wasmMemory,
      _16: () => globalThis.window._flutter_skwasmInstance,
      _17: x0 => x0.rasterStartMilliseconds,
      _18: x0 => x0.rasterEndMilliseconds,
      _19: x0 => x0.imageBitmaps,
      _135: (x0,x1) => x0.appendChild(x1),
      _166: (x0,x1,x2) => x0.addEventListener(x1,x2),
      _167: (x0,x1,x2) => x0.removeEventListener(x1,x2),
      _168: (x0,x1) => new OffscreenCanvas(x0,x1),
      _169: x0 => x0.remove(),
      _170: (x0,x1) => x0.append(x1),
      _172: x0 => x0.unlock(),
      _173: x0 => x0.getReader(),
      _174: (x0,x1) => x0.item(x1),
      _175: x0 => x0.next(),
      _176: x0 => x0.now(),
      _183: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._183(f,arguments.length,x0) }),
      _184: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _186: (x0,x1) => x0.getModifierState(x1),
      _187: x0 => x0.preventDefault(),
      _188: x0 => x0.stopPropagation(),
      _189: (x0,x1) => x0.removeProperty(x1),
      _190: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._190(f,arguments.length,x0) }),
      _191: x0 => new window.FinalizationRegistry(x0),
      _192: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      _194: (x0,x1) => x0.unregister(x1),
      _195: (x0,x1) => x0.prepend(x1),
      _196: x0 => new Intl.Locale(x0),
      _197: (x0,x1) => x0.observe(x1),
      _198: x0 => x0.disconnect(),
      _199: (x0,x1) => x0.getAttribute(x1),
      _200: (x0,x1) => x0.contains(x1),
      _201: (x0,x1) => x0.querySelector(x1),
      _202: (x0,x1) => x0.matchMedia(x1),
      _203: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._203(f,arguments.length,x0) }),
      _204: (x0,x1,x2) => x0.call(x1,x2),
      _205: x0 => x0.blur(),
      _206: x0 => x0.hasFocus(),
      _207: (x0,x1) => x0.removeAttribute(x1),
      _208: (x0,x1,x2) => x0.insertBefore(x1,x2),
      _209: (x0,x1) => x0.hasAttribute(x1),
      _210: (x0,x1) => x0.getModifierState(x1),
      _211: (x0,x1) => x0.createTextNode(x1),
      _212: x0 => x0.getBoundingClientRect(),
      _213: (x0,x1) => x0.replaceWith(x1),
      _214: (x0,x1) => x0.contains(x1),
      _215: (x0,x1) => x0.closest(x1),
      _216: () => new Array(),
      _653: x0 => new Uint8Array(x0),
      _656: () => globalThis.window.flutterConfiguration,
      _658: x0 => x0.assetBase,
      _663: x0 => x0.canvasKitMaximumSurfaces,
      _664: x0 => x0.debugShowSemanticsNodes,
      _665: x0 => x0.hostElement,
      _666: x0 => x0.multiViewEnabled,
      _667: x0 => x0.nonce,
      _669: x0 => x0.fontFallbackBaseUrl,
      _679: x0 => x0.console,
      _680: x0 => x0.devicePixelRatio,
      _681: x0 => x0.document,
      _682: x0 => x0.history,
      _683: x0 => x0.innerHeight,
      _684: x0 => x0.innerWidth,
      _685: x0 => x0.location,
      _686: x0 => x0.navigator,
      _687: x0 => x0.visualViewport,
      _688: x0 => x0.performance,
      _689: x0 => x0.parent,
      _693: (x0,x1) => x0.getComputedStyle(x1),
      _694: x0 => x0.screen,
      _695: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._695(f,arguments.length,x0) }),
      _696: (x0,x1) => x0.requestAnimationFrame(x1),
      _700: (x0,x1) => x0.warn(x1),
      _703: x0 => globalThis.parseFloat(x0),
      _704: () => globalThis.window,
      _705: () => globalThis.Intl,
      _706: () => globalThis.Symbol,
      _709: x0 => x0.clipboard,
      _710: x0 => x0.maxTouchPoints,
      _711: x0 => x0.vendor,
      _712: x0 => x0.language,
      _713: x0 => x0.platform,
      _714: x0 => x0.userAgent,
      _715: (x0,x1) => x0.vibrate(x1),
      _716: x0 => x0.languages,
      _717: x0 => x0.documentElement,
      _718: (x0,x1) => x0.querySelector(x1),
      _719: (x0,x1) => x0.querySelectorAll(x1),
      _721: (x0,x1) => x0.createElement(x1),
      _724: (x0,x1) => x0.createEvent(x1),
      _725: x0 => x0.activeElement,
      _728: x0 => x0.head,
      _729: x0 => x0.body,
      _731: (x0,x1) => { x0.title = x1 },
      _734: x0 => x0.visibilityState,
      _735: () => globalThis.document,
      _736: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._736(f,arguments.length,x0) }),
      _737: (x0,x1) => x0.dispatchEvent(x1),
      _745: x0 => x0.target,
      _747: x0 => x0.timeStamp,
      _748: x0 => x0.type,
      _750: (x0,x1,x2,x3) => x0.initEvent(x1,x2,x3),
      _756: x0 => x0.baseURI,
      _757: x0 => x0.firstChild,
      _761: x0 => x0.parentElement,
      _763: (x0,x1) => { x0.textContent = x1 },
      _764: x0 => x0.parentNode,
      _766: (x0,x1) => x0.removeChild(x1),
      _767: x0 => x0.isConnected,
      _775: x0 => x0.clientHeight,
      _776: x0 => x0.clientWidth,
      _777: x0 => x0.offsetHeight,
      _778: x0 => x0.offsetWidth,
      _779: x0 => x0.id,
      _780: (x0,x1) => { x0.id = x1 },
      _783: (x0,x1) => { x0.spellcheck = x1 },
      _784: x0 => x0.tagName,
      _785: x0 => x0.style,
      _787: (x0,x1) => x0.querySelectorAll(x1),
      _788: (x0,x1,x2) => x0.setAttribute(x1,x2),
      _789: x0 => x0.tabIndex,
      _790: (x0,x1) => { x0.tabIndex = x1 },
      _791: (x0,x1) => x0.focus(x1),
      _792: x0 => x0.scrollTop,
      _793: (x0,x1) => { x0.scrollTop = x1 },
      _794: (x0,x1) => { x0.scrollLeft = x1 },
      _795: x0 => x0.scrollLeft,
      _796: x0 => x0.classList,
      _797: (x0,x1) => x0.scrollIntoView(x1),
      _800: (x0,x1) => { x0.className = x1 },
      _802: (x0,x1) => x0.getElementsByClassName(x1),
      _803: x0 => x0.click(),
      _804: (x0,x1) => x0.attachShadow(x1),
      _807: x0 => x0.computedStyleMap(),
      _808: (x0,x1) => x0.get(x1),
      _814: (x0,x1) => x0.getPropertyValue(x1),
      _815: (x0,x1,x2,x3) => x0.setProperty(x1,x2,x3),
      _816: x0 => x0.offsetLeft,
      _817: x0 => x0.offsetTop,
      _818: x0 => x0.offsetParent,
      _820: (x0,x1) => { x0.name = x1 },
      _821: x0 => x0.content,
      _822: (x0,x1) => { x0.content = x1 },
      _840: (x0,x1) => { x0.nonce = x1 },
      _845: (x0,x1) => { x0.width = x1 },
      _847: (x0,x1) => { x0.height = x1 },
      _850: (x0,x1) => x0.getContext(x1),
      _918: x0 => x0.width,
      _919: x0 => x0.height,
      _921: (x0,x1) => x0.fetch(x1),
      _922: x0 => x0.status,
      _924: x0 => x0.body,
      _925: x0 => x0.arrayBuffer(),
      _928: x0 => x0.read(),
      _929: x0 => x0.value,
      _930: x0 => x0.done,
      _938: x0 => x0.x,
      _939: x0 => x0.y,
      _942: x0 => x0.top,
      _943: x0 => x0.right,
      _944: x0 => x0.bottom,
      _945: x0 => x0.left,
      _955: x0 => x0.height,
      _956: x0 => x0.width,
      _957: x0 => x0.scale,
      _958: (x0,x1) => { x0.value = x1 },
      _961: (x0,x1) => { x0.placeholder = x1 },
      _963: (x0,x1) => { x0.name = x1 },
      _964: x0 => x0.selectionDirection,
      _965: x0 => x0.selectionStart,
      _966: x0 => x0.selectionEnd,
      _969: x0 => x0.value,
      _971: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _972: x0 => x0.readText(),
      _973: (x0,x1) => x0.writeText(x1),
      _975: x0 => x0.altKey,
      _976: x0 => x0.code,
      _977: x0 => x0.ctrlKey,
      _978: x0 => x0.key,
      _979: x0 => x0.keyCode,
      _980: x0 => x0.location,
      _981: x0 => x0.metaKey,
      _982: x0 => x0.repeat,
      _983: x0 => x0.shiftKey,
      _984: x0 => x0.isComposing,
      _986: x0 => x0.state,
      _987: (x0,x1) => x0.go(x1),
      _989: (x0,x1,x2,x3) => x0.pushState(x1,x2,x3),
      _990: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      _991: x0 => x0.pathname,
      _992: x0 => x0.search,
      _993: x0 => x0.hash,
      _997: x0 => x0.state,
      _1012: x0 => x0.matches,
      _1016: x0 => x0.matches,
      _1020: x0 => x0.relatedTarget,
      _1022: x0 => x0.clientX,
      _1023: x0 => x0.clientY,
      _1024: x0 => x0.offsetX,
      _1025: x0 => x0.offsetY,
      _1028: x0 => x0.button,
      _1029: x0 => x0.buttons,
      _1030: x0 => x0.ctrlKey,
      _1034: x0 => x0.pointerId,
      _1035: x0 => x0.pointerType,
      _1036: x0 => x0.pressure,
      _1037: x0 => x0.tiltX,
      _1038: x0 => x0.tiltY,
      _1039: x0 => x0.getCoalescedEvents(),
      _1042: x0 => x0.deltaX,
      _1043: x0 => x0.deltaY,
      _1044: x0 => x0.wheelDeltaX,
      _1045: x0 => x0.wheelDeltaY,
      _1046: x0 => x0.deltaMode,
      _1053: x0 => x0.changedTouches,
      _1056: x0 => x0.clientX,
      _1057: x0 => x0.clientY,
      _1060: x0 => x0.data,
      _1063: (x0,x1) => { x0.disabled = x1 },
      _1065: (x0,x1) => { x0.type = x1 },
      _1066: (x0,x1) => { x0.max = x1 },
      _1067: (x0,x1) => { x0.min = x1 },
      _1068: x0 => x0.value,
      _1069: (x0,x1) => { x0.value = x1 },
      _1070: x0 => x0.disabled,
      _1071: (x0,x1) => { x0.disabled = x1 },
      _1073: (x0,x1) => { x0.placeholder = x1 },
      _1075: (x0,x1) => { x0.name = x1 },
      _1076: (x0,x1) => { x0.autocomplete = x1 },
      _1078: x0 => x0.selectionDirection,
      _1079: x0 => x0.selectionStart,
      _1081: x0 => x0.selectionEnd,
      _1084: (x0,x1,x2) => x0.setSelectionRange(x1,x2),
      _1085: (x0,x1) => x0.add(x1),
      _1087: (x0,x1) => { x0.noValidate = x1 },
      _1088: (x0,x1) => { x0.method = x1 },
      _1089: (x0,x1) => { x0.action = x1 },
      _1114: x0 => x0.orientation,
      _1115: x0 => x0.width,
      _1116: x0 => x0.height,
      _1117: (x0,x1) => x0.lock(x1),
      _1136: x0 => new ResizeObserver(x0),
      _1139: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1139(f,arguments.length,x0,x1) }),
      _1147: x0 => x0.length,
      _1148: x0 => x0.iterator,
      _1149: x0 => x0.Segmenter,
      _1150: x0 => x0.v8BreakIterator,
      _1151: (x0,x1) => new Intl.Segmenter(x0,x1),
      _1154: x0 => x0.language,
      _1155: x0 => x0.script,
      _1156: x0 => x0.region,
      _1174: x0 => x0.done,
      _1175: x0 => x0.value,
      _1176: x0 => x0.index,
      _1180: (x0,x1) => new Intl.v8BreakIterator(x0,x1),
      _1181: (x0,x1) => x0.adoptText(x1),
      _1182: x0 => x0.first(),
      _1183: x0 => x0.next(),
      _1184: x0 => x0.current(),
      _1186: () => globalThis.window.FinalizationRegistry,
      _1197: x0 => x0.hostElement,
      _1198: x0 => x0.viewConstraints,
      _1201: x0 => x0.maxHeight,
      _1202: x0 => x0.maxWidth,
      _1203: x0 => x0.minHeight,
      _1204: x0 => x0.minWidth,
      _1205: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1205(f,arguments.length,x0) }),
      _1206: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1206(f,arguments.length,x0) }),
      _1207: (x0,x1) => ({addView: x0,removeView: x1}),
      _1210: x0 => x0.loader,
      _1211: () => globalThis._flutter,
      _1212: (x0,x1) => x0.didCreateEngineInitializer(x1),
      _1213: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1213(f,arguments.length,x0) }),
      _1214: (module,f) => finalizeWrapper(f, function() { return module.exports._1214(f,arguments.length) }),
      _1215: (x0,x1) => ({initializeEngine: x0,autoStart: x1}),
      _1218: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1218(f,arguments.length,x0) }),
      _1219: x0 => ({runApp: x0}),
      _1221: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1221(f,arguments.length,x0,x1) }),
      _1222: x0 => new Promise(x0),
      _1223: x0 => x0.length,
      _1288: x0 => x0.call(),
      _1302: (x0,x1,x2,x3) => x0.addEventListener(x1,x2,x3),
      _1303: (x0,x1,x2,x3) => x0.removeEventListener(x1,x2,x3),
      _1319: (x0,x1) => x0.getItem(x1),
      _1320: (x0,x1) => x0.removeItem(x1),
      _1321: (x0,x1,x2) => x0.setItem(x1,x2),
      _1322: Date.now,
      _1324: s => new Date(s * 1000).getTimezoneOffset() * 60,
      _1325: s => {
        if (!/^\s*[+-]?(?:Infinity|NaN|(?:\.\d+|\d+(?:\.\d*)?)(?:[eE][+-]?\d+)?)\s*$/.test(s)) {
          return NaN;
        }
        return parseFloat(s);
      },
      _1326: () => typeof dartUseDateNowForTicks !== "undefined",
      _1327: () => 1000 * performance.now(),
      _1328: () => Date.now(),
      _1329: () => {
        // On browsers return `globalThis.location.href`
        if (globalThis.location != null) {
          return globalThis.location.href;
        }
        return null;
      },
      _1330: () => {
        return typeof process != "undefined" &&
               Object.prototype.toString.call(process) == "[object process]" &&
               process.platform == "win32"
      },
      _1331: () => new WeakMap(),
      _1332: (map, o) => map.get(o),
      _1333: (map, o, v) => map.set(o, v),
      _1334: x0 => new WeakRef(x0),
      _1335: x0 => x0.deref(),
      _1336: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1336(f,arguments.length,x0) }),
      _1337: x0 => new FinalizationRegistry(x0),
      _1338: (x0,x1,x2,x3) => x0.register(x1,x2,x3),
      _1340: (x0,x1) => x0.unregister(x1),
      _1342: () => globalThis.WeakRef,
      _1343: () => globalThis.FinalizationRegistry,
      _1345: s => JSON.stringify(s),
      _1346: s => printToConsole(s),
      _1347: o => {
        if (o === null || o === undefined) return 0;
        if (typeof(o) === 'string') return 1;
        return 2;
      },
      _1348: (o, p, r) => o.replaceAll(p, () => r),
      _1349: (o, p, r) => o.replace(p, () => r),
      _1350: Function.prototype.call.bind(String.prototype.toLowerCase),
      _1351: s => s.toUpperCase(),
      _1352: s => s.trim(),
      _1353: s => s.trimLeft(),
      _1354: s => s.trimRight(),
      _1355: (string, times) => string.repeat(times),
      _1356: Function.prototype.call.bind(String.prototype.indexOf),
      _1357: (s, p, i) => s.lastIndexOf(p, i),
      _1358: (string, token) => string.split(token),
      _1359: Object.is,
      _1363: (o, t) => typeof o === t,
      _1364: (o, c) => o instanceof c,
      _1365: o => Object.keys(o),
      _1379: (o, a) => o == a,
      _1419: x0 => new Array(x0),
      _1421: x0 => x0.length,
      _1423: (x0,x1) => x0[x1],
      _1424: (x0,x1,x2) => { x0[x1] = x2 },
      _1427: (x0,x1,x2) => new DataView(x0,x1,x2),
      _1429: x0 => new Int8Array(x0),
      _1430: (x0,x1,x2) => new Uint8Array(x0,x1,x2),
      _1432: x0 => new Uint8ClampedArray(x0),
      _1434: x0 => new Int16Array(x0),
      _1436: x0 => new Uint16Array(x0),
      _1438: x0 => new Int32Array(x0),
      _1440: x0 => new Uint32Array(x0),
      _1442: x0 => new Float32Array(x0),
      _1444: x0 => new Float64Array(x0),
      _1468: x0 => x0.random(),
      _1469: (x0,x1) => x0.getRandomValues(x1),
      _1470: () => globalThis.crypto,
      _1471: () => globalThis.Math,
      _1484: (ms, c) =>
      setTimeout(() => dartInstance.exports.$invokeCallback(c),ms),
      _1485: (handle) => clearTimeout(handle),
      _1486: (ms, c) =>
      setInterval(() => dartInstance.exports.$invokeCallback(c), ms),
      _1487: (handle) => clearInterval(handle),
      _1488: (c) =>
      queueMicrotask(() => dartInstance.exports.$invokeCallback(c)),
      _1489: () => Date.now(),
      _1490: () => new Error().stack,
      _1491: (exn) => {
        let stackString = exn.toString();
        let frames = stackString.split('\n');
        let drop = 4;
        if (frames[0].startsWith('Error')) {
            drop += 1;
        }
        return frames.slice(drop).join('\n');
      },
      _1492: (s, m) => {
        try {
          return new RegExp(s, m);
        } catch (e) {
          return String(e);
        }
      },
      _1493: (x0,x1) => x0.exec(x1),
      _1494: (x0,x1) => x0.test(x1),
      _1495: x0 => x0.pop(),
      _1497: o => o === undefined,
      _1499: o => typeof o === 'function' && o[jsWrappedDartFunctionSymbol] === true,
      _1501: o => {
        const proto = Object.getPrototypeOf(o);
        return proto === Object.prototype || proto === null;
      },
      _1502: o => o instanceof RegExp,
      _1503: (l, r) => l === r,
      _1504: o => o,
      _1505: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'number') return 1;
        return 2;
      },
      _1506: o => o,
      _1507: o => {
        if (o === undefined || o === null) return 0;
        if (typeof o === 'boolean') return 1;
        return 2;
      },
      _1508: o => o,
      _1509: b => !!b,
      _1510: o => o.length,
      _1512: (o, i) => o[i],
      _1513: f => f.dartFunction,
      _1514: () => ({}),
      _1515: () => [],
      _1517: () => globalThis,
      _1518: (constructor, args) => {
        const factoryFunction = constructor.bind.apply(
            constructor, [null, ...args]);
        return new factoryFunction();
      },
      _1519: (o, p) => p in o,
      _1520: (o, p) => o[p],
      _1521: (o, p, v) => o[p] = v,
      _1522: (o, m, a) => o[m].apply(o, a),
      _1524: o => String(o),
      _1525: (p, s, f) => p.then(s, (e) => f(e, e === undefined)),
      _1526: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1526(f,arguments.length,x0) }),
      _1527: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1527(f,arguments.length,x0,x1) }),
      _1528: o => {
        if (o === undefined) return 1;
        var type = typeof o;
        if (type === 'boolean') return 2;
        if (type === 'number') return 3;
        if (type === 'string') return 4;
        if (o instanceof Array) return 5;
        if (ArrayBuffer.isView(o)) {
          if (o instanceof Int8Array) return 6;
          if (o instanceof Uint8Array) return 7;
          if (o instanceof Uint8ClampedArray) return 8;
          if (o instanceof Int16Array) return 9;
          if (o instanceof Uint16Array) return 10;
          if (o instanceof Int32Array) return 11;
          if (o instanceof Uint32Array) return 12;
          if (o instanceof Float32Array) return 13;
          if (o instanceof Float64Array) return 14;
          if (o instanceof DataView) return 15;
        }
        if (o instanceof ArrayBuffer) return 16;
        // Feature check for `SharedArrayBuffer` before doing a type-check.
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
            return 17;
        }
        if (o instanceof Promise) return 18;
        return 19;
      },
      _1529: o => [o],
      _1530: (o0, o1) => [o0, o1],
      _1531: (o0, o1, o2) => [o0, o1, o2],
      _1532: (o0, o1, o2, o3) => [o0, o1, o2, o3],
      _1533: (exn) => {
        if (exn instanceof Error) {
          return exn.stack;
        } else {
          return null;
        }
      },
      _1534: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI8ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1535: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI8ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1538: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmI32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1539: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmI32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1540: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF32ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1541: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF32ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1542: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const getValue = dartInstance.exports.$wasmF64ArrayGet;
        for (let i = 0; i < length; i++) {
          jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
        }
      },
      _1543: (jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
        const setValue = dartInstance.exports.$wasmF64ArraySet;
        for (let i = 0; i < length; i++) {
          setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
        }
      },
      _1544: x0 => new ArrayBuffer(x0),
      _1545: s => {
        if (/[[\]{}()*+?.\\^$|]/.test(s)) {
            s = s.replace(/[[\]{}()*+?.\\^$|]/g, '\\$&');
        }
        return s;
      },
      _1547: x0 => x0.index,
      _1548: x0 => x0.groups,
      _1549: x0 => x0.flags,
      _1550: x0 => x0.multiline,
      _1551: x0 => x0.ignoreCase,
      _1552: x0 => x0.unicode,
      _1553: x0 => x0.dotAll,
      _1554: (x0,x1) => { x0.lastIndex = x1 },
      _1555: (o, p) => p in o,
      _1556: (o, p) => o[p],
      _1557: (o, p, v) => o[p] = v,
      _1559: x0 => x0.arrayBuffer(),
      _1560: (x0,x1) => x0.sqlite3changeset_finalize(x1),
      _1561: (x0,x1) => x0.sqlite3session_delete(x1),
      _1562: (x0,x1) => x0.sqlite3_close_v2(x1),
      _1563: (x0,x1) => x0.sqlite3_finalize(x1),
      _1564: (x0,x1) => x0.dart_sqlite3_malloc(x1),
      _1565: (x0,x1) => x0.dart_sqlite3_free(x1),
      _1567: x0 => x0.sqlite3_initialize(),
      _1573: (x0,x1,x2,x3,x4) => x0.sqlite3_open_v2(x1,x2,x3,x4),
      _1574: (x0,x1) => x0.sqlite3_extended_errcode(x1),
      _1575: (x0,x1) => x0.sqlite3_errmsg(x1),
      _1576: (x0,x1) => x0.sqlite3_errstr(x1),
      _1577: (x0,x1) => x0.sqlite3_error_offset(x1),
      _1578: (x0,x1,x2) => x0.sqlite3_extended_result_codes(x1,x2),
      _1582: (x0,x1,x2,x3,x4,x5) => x0.sqlite3_exec(x1,x2,x3,x4,x5),
      _1583: (x0,x1,x2,x3,x4,x5,x6) => x0.sqlite3_prepare_v3(x1,x2,x3,x4,x5,x6),
      _1584: (x0,x1) => x0.sqlite3_bind_parameter_count(x1),
      _1585: (x0,x1,x2) => x0.sqlite3_bind_null(x1,x2),
      _1586: (x0,x1,x2,x3) => x0.sqlite3_bind_int64(x1,x2,x3),
      _1587: (x0,x1,x2,x3) => x0.sqlite3_bind_double(x1,x2,x3),
      _1588: (x0,x1,x2,x3,x4) => x0.dart_sqlite3_bind_text(x1,x2,x3,x4),
      _1589: (x0,x1,x2,x3,x4) => x0.dart_sqlite3_bind_blob(x1,x2,x3,x4),
      _1591: (x0,x1) => x0.sqlite3_column_count(x1),
      _1592: (x0,x1,x2) => x0.sqlite3_column_name(x1,x2),
      _1593: (x0,x1,x2) => x0.sqlite3_column_type(x1,x2),
      _1594: (x0,x1,x2) => x0.sqlite3_column_int64(x1,x2),
      _1595: (x0,x1,x2) => x0.sqlite3_column_double(x1,x2),
      _1596: (x0,x1,x2) => x0.sqlite3_column_bytes(x1,x2),
      _1597: (x0,x1,x2) => x0.sqlite3_column_text(x1,x2),
      _1598: (x0,x1,x2) => x0.sqlite3_column_blob(x1,x2),
      _1599: (x0,x1) => x0.sqlite3_value_type(x1),
      _1601: (x0,x1) => x0.sqlite3_value_int64(x1),
      _1602: (x0,x1) => x0.sqlite3_value_double(x1),
      _1603: (x0,x1) => x0.sqlite3_value_bytes(x1),
      _1604: (x0,x1) => x0.sqlite3_value_text(x1),
      _1605: (x0,x1) => x0.sqlite3_value_blob(x1),
      _1606: (x0,x1) => x0.sqlite3_result_null(x1),
      _1607: (x0,x1,x2) => x0.sqlite3_result_int64(x1,x2),
      _1608: (x0,x1,x2) => x0.sqlite3_result_double(x1,x2),
      _1609: (x0,x1,x2,x3,x4) => x0.sqlite3_result_text(x1,x2,x3,x4),
      _1610: (x0,x1,x2,x3,x4) => x0.sqlite3_result_blob64(x1,x2,x3,x4),
      _1611: (x0,x1,x2,x3) => x0.sqlite3_result_error(x1,x2,x3),
      _1612: (x0,x1,x2) => x0.sqlite3_result_subtype(x1,x2),
      _1615: (x0,x1) => x0.sqlite3_step(x1),
      _1616: (x0,x1) => x0.sqlite3_reset(x1),
      _1618: (x0,x1) => x0.sqlite3_stmt_isexplain(x1),
      _1620: (x0,x1) => x0.sqlite3_last_insert_rowid(x1),
      _1637: (x0,x1,x2,x3) => x0.dart_sqlite3_register_vfs(x1,x2,x3),
      _1640: (x0,x1,x2,x3,x4,x5,x6) => x0.dart_sqlite3_create_function_v2(x1,x2,x3,x4,x5,x6),
      _1645: (x0,x1) => new URL(x0,x1),
      _1646: (x0,x1) => globalThis.fetch(x0,x1),
      _1647: (x0,x1,x2) => x0.postMessage(x1,x2),
      _1648: (x0,x1,x2) => x0.postMessage(x1,x2),
      _1650: (x0,x1) => ({i: x0,p: x1}),
      _1651: (x0,x1) => ({c: x0,r: x1}),
      _1652: x0 => x0.i,
      _1653: x0 => x0.p,
      _1654: x0 => x0.c,
      _1655: x0 => x0.r,
      _1656: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1656(f,arguments.length,x0) }),
      _1657: (x0,x1) => x0.postMessage(x1),
      _1658: x0 => x0.close(),
      _1660: x0 => new Worker(x0),
      _1662: x0 => x0.getDirectory(),
      _1663: x0 => ({create: x0}),
      _1664: (x0,x1,x2) => x0.getFileHandle(x1,x2),
      _1665: x0 => x0.createSyncAccessHandle(),
      _1666: x0 => x0.close(),
      _1669: x0 => x0.close(),
      _1672: (x0,x1,x2) => x0.open(x1,x2),
      _1673: x0 => x0.abort(),
      _1676: (x0,x1,x2) => x0.getDirectoryHandle(x1,x2),
      _1681: x0 => ({create: x0}),
      _1686: (x0,x1) => new SharedWorker(x0,x1),
      _1687: x0 => x0.start(),
      _1688: x0 => x0.terminate(),
      _1689: () => new MessageChannel(),
      _1694: x0 => globalThis.BigInt(x0),
      _1695: x0 => globalThis.Number(x0),
      _1703: () => globalThis.navigator,
      _1704: (x0,x1) => x0.read(x1),
      _1705: (x0,x1,x2) => x0.read(x1,x2),
      _1706: (x0,x1) => x0.write(x1),
      _1707: (x0,x1,x2) => x0.write(x1,x2),
      _1710: x0 => ({at: x0}),
      _1711: x0 => x0.getSize(),
      _1712: (x0,x1) => x0.truncate(x1),
      _1713: x0 => x0.flush(),
      _1716: x0 => x0.synchronizationBuffer,
      _1717: x0 => x0.communicationBuffer,
      _1718: (x0,x1,x2,x3) => ({clientVersion: x0,root: x1,synchronizationBuffer: x2,communicationBuffer: x3}),
      _1719: x0 => new SharedArrayBuffer(x0),
      _1720: x0 => ({autoIncrement: x0}),
      _1721: (x0,x1,x2) => x0.createObjectStore(x1,x2),
      _1722: x0 => ({unique: x0}),
      _1723: (x0,x1,x2,x3) => x0.createIndex(x1,x2,x3),
      _1724: (x0,x1) => x0.createObjectStore(x1),
      _1725: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1725(f,arguments.length,x0) }),
      _1726: (x0,x1,x2) => x0.transaction(x1,x2),
      _1727: x0 => x0.commit(),
      _1728: (x0,x1) => x0.objectStore(x1),
      _1729: (module,f) => finalizeWrapper(f, function() { return module.exports._1729(f,arguments.length) }),
      _1730: x0 => new DOMException(x0),
      _1731: (module,f) => finalizeWrapper(f, function() { return module.exports._1731(f,arguments.length) }),
      _1732: (x0,x1) => globalThis.IDBKeyRange.bound(x0,x1),
      _1734: (x0,x1) => x0.index(x1),
      _1735: x0 => x0.openKeyCursor(),
      _1736: (x0,x1) => x0.getKey(x1),
      _1737: (x0,x1) => x0.get(x1),
      _1738: (x0,x1) => x0.openCursor(x1),
      _1739: (x0,x1) => ({name: x0,length: x1}),
      _1740: (x0,x1) => x0.put(x1),
      _1741: x0 => globalThis.IDBKeyRange.only(x0),
      _1742: (x0,x1,x2) => x0.put(x1,x2),
      _1743: (x0,x1) => x0.update(x1),
      _1744: (x0,x1) => x0.delete(x1),
      _1745: x0 => x0.name,
      _1746: x0 => x0.length,
      _1747: x0 => new BroadcastChannel(x0),
      _1748: x0 => globalThis.Array.isArray(x0),
      _1749: (x0,x1) => x0.postMessage(x1),
      _1750: x0 => x0.close(),
      _1751: (x0,x1) => ({kind: x0,table: x1}),
      _1752: x0 => x0.kind,
      _1753: x0 => x0.table,
      _1754: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1754(f,arguments.length,x0) }),
      _1755: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1755(f,arguments.length,x0,x1) }),
      _1756: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3,x4) { return module.exports._1756(f,arguments.length,x0,x1,x2,x3,x4) }),
      _1757: (module,f) => finalizeWrapper(f, function(x0,x1,x2) { return module.exports._1757(f,arguments.length,x0,x1,x2) }),
      _1758: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._1758(f,arguments.length,x0,x1,x2,x3) }),
      _1759: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._1759(f,arguments.length,x0,x1,x2,x3) }),
      _1760: (module,f) => finalizeWrapper(f, function(x0,x1,x2) { return module.exports._1760(f,arguments.length,x0,x1,x2) }),
      _1761: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1761(f,arguments.length,x0,x1) }),
      _1762: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1762(f,arguments.length,x0,x1) }),
      _1763: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1763(f,arguments.length,x0) }),
      _1764: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._1764(f,arguments.length,x0,x1,x2,x3) }),
      _1765: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._1765(f,arguments.length,x0,x1,x2,x3) }),
      _1766: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1766(f,arguments.length,x0,x1) }),
      _1767: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1767(f,arguments.length,x0,x1) }),
      _1768: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1768(f,arguments.length,x0,x1) }),
      _1769: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1769(f,arguments.length,x0,x1) }),
      _1770: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1770(f,arguments.length,x0,x1) }),
      _1771: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1771(f,arguments.length,x0,x1) }),
      _1772: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1772(f,arguments.length,x0) }),
      _1773: (module,f) => finalizeWrapper(f, function(x0,x1,x2) { return module.exports._1773(f,arguments.length,x0,x1,x2) }),
      _1774: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1774(f,arguments.length,x0) }),
      _1775: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1775(f,arguments.length,x0) }),
      _1776: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1776(f,arguments.length,x0) }),
      _1777: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3,x4) { return module.exports._1777(f,arguments.length,x0,x1,x2,x3,x4) }),
      _1778: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._1778(f,arguments.length,x0,x1,x2,x3) }),
      _1779: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._1779(f,arguments.length,x0,x1,x2,x3) }),
      _1780: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3) { return module.exports._1780(f,arguments.length,x0,x1,x2,x3) }),
      _1781: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1781(f,arguments.length,x0,x1) }),
      _1782: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1782(f,arguments.length,x0,x1) }),
      _1783: (module,f) => finalizeWrapper(f, function(x0,x1,x2,x3,x4) { return module.exports._1783(f,arguments.length,x0,x1,x2,x3,x4) }),
      _1784: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1784(f,arguments.length,x0,x1) }),
      _1785: (module,f) => finalizeWrapper(f, function(x0,x1) { return module.exports._1785(f,arguments.length,x0,x1) }),
      _1786: (module,f) => finalizeWrapper(f, function(x0,x1,x2) { return module.exports._1786(f,arguments.length,x0,x1,x2) }),
      _1787: (x0,x1,x2) => x0.instantiateStreaming(x1,x2),
      _1788: x0 => x0.continue(),
      _1789: () => globalThis.indexedDB,
      _1790: (x0,x1,x2) => globalThis.Atomics.wait(x0,x1,x2),
      _1792: (x0,x1,x2) => globalThis.Atomics.notify(x0,x1,x2),
      _1793: (x0,x1,x2) => globalThis.Atomics.store(x0,x1,x2),
      _1794: (x0,x1) => globalThis.Atomics.load(x0,x1),
      _1795: () => globalThis.Int32Array,
      _1797: () => globalThis.Uint8Array,
      _1799: () => globalThis.DataView,
      _1801: x0 => x0.byteLength,
      _1810: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1810(f,arguments.length,x0) }),
      _1811: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1811(f,arguments.length,x0) }),
      _1816: (x0,x1) => new WebSocket(x0,x1),
      _1817: (x0,x1) => x0.send(x1),
      _1818: (x0,x1,x2) => x0.close(x1,x2),
      _1819: (x0,x1) => x0.close(x1),
      _1820: x0 => x0.close(),
      _1824: () => new AbortController(),
      _1825: x0 => x0.abort(),
      _1826: (x0,x1,x2,x3,x4,x5) => ({method: x0,headers: x1,body: x2,credentials: x3,redirect: x4,signal: x5}),
      _1827: (x0,x1) => globalThis.fetch(x0,x1),
      _1828: (x0,x1) => x0.get(x1),
      _1829: (module,f) => finalizeWrapper(f, function(x0,x1,x2) { return module.exports._1829(f,arguments.length,x0,x1,x2) }),
      _1830: (x0,x1) => x0.forEach(x1),
      _1831: x0 => x0.getReader(),
      _1832: x0 => x0.cancel(),
      _1833: x0 => x0.read(),
      _1834: (module,f) => finalizeWrapper(f, function(x0) { return module.exports._1834(f,arguments.length,x0) }),
      _1835: (x0,x1,x2,x3) => x0.replaceState(x1,x2,x3),
      _1836: (x0,x1) => x0.key(x1),
      _1837: o => o instanceof Array,
      _1840: (a, l) => a.length = l,
      _1841: a => a.pop(),
      _1842: (a, i) => a.splice(i, 1),
      _1843: (a, s) => a.join(s),
      _1844: (a, s, e) => a.slice(s, e),
      _1846: (a, b) => a == b ? 0 : (a > b ? 1 : -1),
      _1847: a => a.length,
      _1848: (a, l) => a.length = l,
      _1849: (a, i) => a[i],
      _1850: (a, i, v) => a[i] = v,
      _1852: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof ArrayBuffer) return 1;
        if (globalThis.SharedArrayBuffer !== undefined &&
            o instanceof SharedArrayBuffer) {
          return 2;
        }
        return 3;
      },
      _1853: (o, offsetInBytes, lengthInBytes) => {
        var dst = new ArrayBuffer(lengthInBytes);
        new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
        return new DataView(dst);
      },
      _1854: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof DataView) return 1;
        return 2;
      },
      _1855: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint8Array) return 1;
        return 2;
      },
      _1856: (o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length),
      _1857: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int8Array) return 1;
        return 2;
      },
      _1858: (o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length),
      _1859: o => o instanceof Uint8ClampedArray,
      _1860: (o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length),
      _1861: o => o instanceof Uint16Array,
      _1862: (o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length),
      _1863: o => o instanceof Int16Array,
      _1864: (o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length),
      _1865: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Uint32Array) return 1;
        return 2;
      },
      _1866: (o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length),
      _1867: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Int32Array) return 1;
        return 2;
      },
      _1868: (o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length),
      _1870: (o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length),
      _1871: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float32Array) return 1;
        return 2;
      },
      _1872: (o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length),
      _1873: o => {
        if (o === null || o === undefined) return 0;
        if (o instanceof Float64Array) return 1;
        return 2;
      },
      _1874: (o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length),
      _1875: (a, i) => a.push(i),
      _1876: (t, s) => t.set(s),
      _1877: l => new DataView(new ArrayBuffer(l)),
      _1878: (o) => new DataView(o.buffer, o.byteOffset, o.byteLength),
      _1879: o => o.byteLength,
      _1880: o => o.buffer,
      _1881: o => o.byteOffset,
      _1882: Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get),
      _1883: (b, o) => new DataView(b, o),
      _1884: (b, o, l) => new DataView(b, o, l),
      _1885: Function.prototype.call.bind(DataView.prototype.getUint8),
      _1886: Function.prototype.call.bind(DataView.prototype.setUint8),
      _1887: Function.prototype.call.bind(DataView.prototype.getInt8),
      _1888: Function.prototype.call.bind(DataView.prototype.setInt8),
      _1889: Function.prototype.call.bind(DataView.prototype.getUint16),
      _1890: Function.prototype.call.bind(DataView.prototype.setUint16),
      _1891: Function.prototype.call.bind(DataView.prototype.getInt16),
      _1892: Function.prototype.call.bind(DataView.prototype.setInt16),
      _1893: Function.prototype.call.bind(DataView.prototype.getUint32),
      _1894: Function.prototype.call.bind(DataView.prototype.setUint32),
      _1895: Function.prototype.call.bind(DataView.prototype.getInt32),
      _1896: Function.prototype.call.bind(DataView.prototype.setInt32),
      _1899: Function.prototype.call.bind(DataView.prototype.getBigInt64),
      _1900: Function.prototype.call.bind(DataView.prototype.setBigInt64),
      _1901: Function.prototype.call.bind(DataView.prototype.getFloat32),
      _1902: Function.prototype.call.bind(DataView.prototype.setFloat32),
      _1903: Function.prototype.call.bind(DataView.prototype.getFloat64),
      _1904: Function.prototype.call.bind(DataView.prototype.setFloat64),
      _1905: Function.prototype.call.bind(Number.prototype.toString),
      _1906: Function.prototype.call.bind(BigInt.prototype.toString),
      _1907: Function.prototype.call.bind(Number.prototype.toString),
      _1908: (d, digits) => d.toFixed(digits),
      _1912: (module,f) => finalizeWrapper(f, function() { return module.exports._1912(f,arguments.length) }),
      _1913: () => globalThis.Promise.resolve(),
      _1914: (x0,x1) => x0.then(x1),
      _1927: () => globalThis.console,
      _1966: (x0,x1) => x0.error(x1),
      _3811: () => globalThis.window,
      _3854: x0 => x0.location,
      _3855: x0 => x0.history,
      _3873: x0 => x0.navigator,
      _4137: x0 => x0.localStorage,
      _4145: x0 => x0.href,
      _4261: x0 => x0.userAgent,
      _4274: x0 => x0.storage,
      _4312: x0 => x0.data,
      _4342: x0 => x0.port1,
      _4343: x0 => x0.port2,
      _4345: (x0,x1) => { x0.onmessage = x1 },
      _4355: (x0,x1) => { x0.onmessage = x1 },
      _4423: x0 => x0.port,
      _4458: x0 => x0.length,
      _4675: x0 => x0.readyState,
      _4688: (x0,x1) => { x0.binaryType = x1 },
      _4691: x0 => x0.code,
      _4692: x0 => x0.reason,
      _6400: x0 => x0.signal,
      _8236: x0 => x0.value,
      _8238: x0 => x0.done,
      _8918: x0 => x0.url,
      _8920: x0 => x0.status,
      _8922: x0 => x0.statusText,
      _8923: x0 => x0.headers,
      _8924: x0 => x0.body,
      _8936: x0 => x0.instance,
      _8938: () => globalThis.WebAssembly,
      _8960: x0 => x0.exports,
      _8968: x0 => x0.buffer,
      _10379: x0 => x0.result,
      _10380: x0 => x0.error,
      _10391: (x0,x1) => { x0.onupgradeneeded = x1 },
      _10393: x0 => x0.oldVersion,
      _10472: x0 => x0.key,
      _10473: x0 => x0.primaryKey,
      _10475: x0 => x0.value,
      _10480: x0 => x0.error,
      _10482: (x0,x1) => { x0.onabort = x1 },
      _10484: (x0,x1) => { x0.oncomplete = x1 },
      _10486: (x0,x1) => { x0.onerror = x1 },
      _12534: x0 => x0.name,
      _12633: x0 => x0.href,
      _12648: x0 => x0.pathname,

    };

    const baseImports = {
      dart2wasm: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      WebAssembly: {
        JSTag: WebAssembly.JSTag,
      },
      "": new Proxy({}, { get(_, prop) { return prop; } }),

    };

    const jsStringPolyfill = {
      "charCodeAt": (s, i) => s.charCodeAt(i),
      "compare": (s1, s2) => {
        if (s1 < s2) return -1;
        if (s1 > s2) return 1;
        return 0;
      },
      "concat": (s1, s2) => s1 + s2,
      "equals": (s1, s2) => s1 === s2,
      "fromCharCode": (i) => String.fromCharCode(i),
      "length": (s) => s.length,
      "substring": (s, a, b) => s.substring(a, b),
      "fromCharCodeArray": (a, start, end) => {
        if (end <= start) return '';

        const read = dartInstance.exports.$wasmI16ArrayGet;
        let result = '';
        let index = start;
        const chunkLength = Math.min(end - index, 500);
        let array = new Array(chunkLength);
        while (index < end) {
          const newChunkLength = Math.min(end - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(a, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      "intoCharCodeArray": (s, a, start) => {
        if (s === '') return 0;

        const write = dartInstance.exports.$wasmI16ArraySet;
        for (var i = 0; i < s.length; ++i) {
          write(a, start++, s.charCodeAt(i));
        }
        return s.length;
      },
      "test": (s) => typeof s == "string",
    };


    

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      
      "wasm:js-string": jsStringPolyfill,
    });
    dartInstance.exports.$setThisModule(dartInstance);

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}
