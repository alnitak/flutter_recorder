// This code implements the `-sMODULARIZE` settings by taking the generated
// JS program code (INNER_JS_CODE) and wrapping it in a factory function.

// Single threaded MINIMAL_RUNTIME programs do not need access to
// document.currentScript, so a simple export declaration is enough.
var RecorderModule = (() => {
  // When MODULARIZE this JS may be executed later,
  // after document.currentScript is gone, so we save it.
  // In EXPORT_ES6 mode we can just use 'import.meta.url'.
  var _scriptName = globalThis.document?.currentScript?.src;
  return async function(moduleArg = {}) {
    var moduleRtn;

// include: shell.js
// include: minimum_runtime_check.js
(function() {
  // "30.0.0" -> 300000
  function humanReadableVersionToPacked(str) {
    str = str.split("-")[0];
    // Remove any trailing part from e.g. "12.53.3-alpha"
    var vers = str.split(".").slice(0, 3);
    while (vers.length < 3) vers.push("00");
    vers = vers.map((n, i, arr) => n.padStart(2, "0"));
    return vers.join("");
  }
  // 300000 -> "30.0.0"
  var packedVersionToHumanReadable = n => [ n / 1e4 | 0, (n / 100 | 0) % 100, n % 100 ].join(".");
  var TARGET_NOT_SUPPORTED = 2147483647;
  // Note: We use a typeof check here instead of optional chaining using
  // globalThis because older browsers might not have globalThis defined.
  var currentNodeVersion = typeof process !== "undefined" && process.versions?.node ? humanReadableVersionToPacked(process.versions.node) : TARGET_NOT_SUPPORTED;
  if (currentNodeVersion < 160400) {
    throw new Error(`This emscripten-generated code requires node v${packedVersionToHumanReadable(160400)} (detected v${packedVersionToHumanReadable(currentNodeVersion)})`);
  }
  var userAgent = typeof navigator !== "undefined" && navigator.userAgent;
  if (!userAgent) {
    return;
  }
  var currentSafariVersion = userAgent.includes("Safari/") && !userAgent.includes("Chrome/") && userAgent.match(/Version\/(\d+\.?\d*\.?\d*)/) ? humanReadableVersionToPacked(userAgent.match(/Version\/(\d+\.?\d*\.?\d*)/)[1]) : TARGET_NOT_SUPPORTED;
  if (currentSafariVersion < 15e4) {
    throw new Error(`This emscripten-generated code requires Safari v${packedVersionToHumanReadable(15e4)} (detected v${currentSafariVersion})`);
  }
  var currentFirefoxVersion = userAgent.match(/Firefox\/(\d+(?:\.\d+)?)/) ? parseFloat(userAgent.match(/Firefox\/(\d+(?:\.\d+)?)/)[1]) : TARGET_NOT_SUPPORTED;
  if (currentFirefoxVersion < 79) {
    throw new Error(`This emscripten-generated code requires Firefox v79 (detected v${currentFirefoxVersion})`);
  }
  var currentChromeVersion = userAgent.match(/Chrome\/(\d+(?:\.\d+)?)/) ? parseFloat(userAgent.match(/Chrome\/(\d+(?:\.\d+)?)/)[1]) : TARGET_NOT_SUPPORTED;
  if (currentChromeVersion < 85) {
    throw new Error(`This emscripten-generated code requires Chrome v85 (detected v${currentChromeVersion})`);
  }
})();

// end include: minimum_runtime_check.js
// The Module object: Our interface to the outside world. We import
// and export values on it. There are various ways Module can be used:
// 1. Not defined. We create it here
// 2. A function parameter, function(moduleArg) => Promise<Module>
// 3. pre-run appended it, var Module = {}; ..generated code..
// 4. External script tag defines var Module.
// We need to check if Module already exists (e.g. case 3 above).
// Substitution will be replaced with actual code on later stage of the build,
// this way Closure Compiler will not mangle it (e.g. case 4. above).
// Note that if you want to run closure, and also to use Module
// after the generated code, you will need to define   var Module = {};
// before the code. Then that object will be used in the code, and you
// can continue to use Module afterwards as well.
var Module = moduleArg;

// The way we signal to a worker that it is hosting a pthread is to construct
// it with a specific name.
var ENVIRONMENT_IS_WASM_WORKER = globalThis.name == "em-ww";

var ENVIRONMENT_IS_AUDIO_WORKLET = !!globalThis.AudioWorkletGlobalScope;

// Audio worklets behave as wasm workers.
if (ENVIRONMENT_IS_AUDIO_WORKLET) ENVIRONMENT_IS_WASM_WORKER = true;

// Determine the runtime environment we are in. You can customize this by
// setting the ENVIRONMENT setting at compile time (see settings.js).
// Attempt to auto-detect the environment
var ENVIRONMENT_IS_WEB = !!globalThis.window;

var ENVIRONMENT_IS_WORKER = !!globalThis.WorkerGlobalScope;

// N.b. Electron.js environment is simultaneously a NODE-environment, but
// also a web environment.
var ENVIRONMENT_IS_NODE = globalThis.process?.versions?.node && globalThis.process?.type != "renderer";

var ENVIRONMENT_IS_SHELL = !ENVIRONMENT_IS_WEB && !ENVIRONMENT_IS_NODE && !ENVIRONMENT_IS_WORKER && !ENVIRONMENT_IS_AUDIO_WORKLET;

// Three configurations we can be running in:
// 1) We could be the application main() thread running in the main JS UI thread. (ENVIRONMENT_IS_WORKER == false and ENVIRONMENT_IS_PTHREAD == false)
// 2) We could be the application main() running directly in a worker. (ENVIRONMENT_IS_WORKER == true, ENVIRONMENT_IS_PTHREAD == false)
// 3) We could be an application pthread running in a worker. (ENVIRONMENT_IS_WORKER == true and ENVIRONMENT_IS_PTHREAD == true)
// The way we signal to a worker that it is hosting a pthread is to construct
// it with a specific name.
var ENVIRONMENT_IS_PTHREAD = ENVIRONMENT_IS_WORKER && self.name?.startsWith("em-pthread");

if (ENVIRONMENT_IS_PTHREAD) {
  assert(!globalThis.moduleLoaded, "module should only be loaded once on each pthread worker");
  globalThis.moduleLoaded = true;
}

if (ENVIRONMENT_IS_NODE) {
  var worker_threads = require("worker_threads");
  global.Worker = worker_threads.Worker;
  ENVIRONMENT_IS_WORKER = !worker_threads.isMainThread;
  // Under node we set `workerData` to `em-pthread` to signal that the worker
  // is hosting a pthread.
  ENVIRONMENT_IS_PTHREAD = ENVIRONMENT_IS_WORKER && worker_threads["workerData"] == "em-pthread";
  ENVIRONMENT_IS_WASM_WORKER = ENVIRONMENT_IS_WORKER && worker_threads["workerData"] == "em-ww";
}

// --pre-jses are emitted after the Module integration code, so that they can
// refer to Module (if they choose; they can also define Module)
var arguments_ = [];

var thisProgram = "./this.program";

var quit_ = (status, toThrow) => {
  throw toThrow;
};

if (typeof __filename != "undefined") {
  // Node
  _scriptName = __filename;
} else if (ENVIRONMENT_IS_WORKER) {
  _scriptName = self.location.href;
}

// `/` should be present at the end if `scriptDirectory` is not empty
var scriptDirectory = "";

function locateFile(path) {
  if (Module["locateFile"]) {
    return Module["locateFile"](path, scriptDirectory);
  }
  return scriptDirectory + path;
}

// Hooks that are implemented differently in different runtime environments.
var readAsync, readBinary;

if (ENVIRONMENT_IS_NODE) {
  const isNode = globalThis.process?.versions?.node && globalThis.process?.type != "renderer";
  if (!isNode) throw new Error("not compiled for this environment (did you build to HTML and try to run it not on the web, or set ENVIRONMENT to something - like node - and run it someplace else - like on the web?)");
  // These modules will usually be used on Node.js. Load them eagerly to avoid
  // the complexity of lazy-loading.
  var fs = require("fs");
  scriptDirectory = __dirname + "/";
  // include: node_shell_read.js
  readBinary = filename => {
    // We need to re-wrap `file://` strings to URLs.
    filename = isFileURI(filename) ? new URL(filename) : filename;
    var ret = fs.readFileSync(filename);
    assert(Buffer.isBuffer(ret));
    return ret;
  };
  readAsync = async (filename, binary = true) => {
    // See the comment in the `readBinary` function.
    filename = isFileURI(filename) ? new URL(filename) : filename;
    var ret = fs.readFileSync(filename, binary ? undefined : "utf8");
    assert(binary ? Buffer.isBuffer(ret) : typeof ret == "string");
    return ret;
  };
  // end include: node_shell_read.js
  if (process.argv.length > 1) {
    thisProgram = process.argv[1].replace(/\\/g, "/");
  }
  arguments_ = process.argv.slice(2);
  quit_ = (status, toThrow) => {
    process.exitCode = status;
    throw toThrow;
  };
} else if (ENVIRONMENT_IS_SHELL) {} else // Note that this includes Node.js workers when relevant (pthreads is enabled).
// Node.js workers are detected as a combination of ENVIRONMENT_IS_WORKER and
// ENVIRONMENT_IS_NODE.
if (ENVIRONMENT_IS_WEB || ENVIRONMENT_IS_WORKER) {
  try {
    scriptDirectory = new URL(".", _scriptName).href;
  } catch {}
  if (!(globalThis.window || globalThis.WorkerGlobalScope)) throw new Error("not compiled for this environment (did you build to HTML and try to run it not on the web, or set ENVIRONMENT to something - like node - and run it someplace else - like on the web?)");
  // Differentiate the Web Worker from the Node Worker case, as reading must
  // be done differently.
  if (!ENVIRONMENT_IS_NODE) {
    // include: web_or_worker_shell_read.js
    if (ENVIRONMENT_IS_WORKER) {
      readBinary = url => {
        var xhr = new XMLHttpRequest;
        xhr.open("GET", url, false);
        xhr.responseType = "arraybuffer";
        xhr.send(null);
        return new Uint8Array(/** @type{!ArrayBuffer} */ (xhr.response));
      };
    }
    readAsync = async url => {
      // Fetch has some additional restrictions over XHR, like it can't be used on a file:// url.
      // See https://github.com/github/fetch/pull/92#issuecomment-140665932
      // Cordova or Electron apps are typically loaded from a file:// url.
      // So use XHR on webview if URL is a file URL.
      if (isFileURI(url)) {
        return new Promise((resolve, reject) => {
          var xhr = new XMLHttpRequest;
          xhr.open("GET", url, true);
          xhr.responseType = "arraybuffer";
          xhr.onload = () => {
            if (xhr.status == 200 || (xhr.status == 0 && xhr.response)) {
              // file URLs can return 0
              resolve(xhr.response);
              return;
            }
            reject(xhr.status);
          };
          xhr.onerror = reject;
          xhr.send(null);
        });
      }
      var response = await fetch(url, {
        credentials: "same-origin"
      });
      if (response.ok) {
        return response.arrayBuffer();
      }
      throw new Error(response.status + " : " + response.url);
    };
  }
} else if (!ENVIRONMENT_IS_AUDIO_WORKLET) {
  throw new Error("environment detection error");
}

// Set up the out() and err() hooks, which are how we can print to stdout or
// stderr, respectively.
// Normally just binding console.log/console.error here works fine, but
// under node (with workers) we see missing/out-of-order messages so route
// directly to stdout and stderr.
// See https://github.com/emscripten-core/emscripten/issues/14804
var defaultPrint = console.log.bind(console);

var defaultPrintErr = console.error.bind(console);

if (ENVIRONMENT_IS_NODE) {
  var utils = require("util");
  var stringify = a => typeof a == "object" ? utils.inspect(a) : a;
  defaultPrint = (...args) => fs.writeSync(1, args.map(stringify).join(" ") + "\n");
  defaultPrintErr = (...args) => fs.writeSync(2, args.map(stringify).join(" ") + "\n");
}

var out = defaultPrint;

var err = defaultPrintErr;

var IDBFS = "IDBFS is no longer included by default; build with -lidbfs.js";

var PROXYFS = "PROXYFS is no longer included by default; build with -lproxyfs.js";

var WORKERFS = "WORKERFS is no longer included by default; build with -lworkerfs.js";

var FETCHFS = "FETCHFS is no longer included by default; build with -lfetchfs.js";

var ICASEFS = "ICASEFS is no longer included by default; build with -licasefs.js";

var JSFILEFS = "JSFILEFS is no longer included by default; build with -ljsfilefs.js";

var OPFS = "OPFS is no longer included by default; build with -lopfs.js";

var NODEFS = "NODEFS is no longer included by default; build with -lnodefs.js";

// perform assertions in shell.js after we set up out() and err(), as otherwise
// if an assertion fails it cannot print the message
assert(ENVIRONMENT_IS_AUDIO_WORKLET || ENVIRONMENT_IS_WEB || ENVIRONMENT_IS_WORKER || ENVIRONMENT_IS_NODE, "Pthreads do not work in this environment yet (need Web Workers, or an alternative to them)");

assert(!ENVIRONMENT_IS_SHELL, "shell environment detected but not enabled at build time.  Add `shell` to `-sENVIRONMENT` to enable.");

// end include: shell.js
// include: preamble.js
// === Preamble library stuff ===
// Documentation for the public APIs defined in this file must be updated in:
//    site/source/docs/api_reference/preamble.js.rst
// A prebuilt local version of the documentation is available at:
//    site/build/text/docs/api_reference/preamble.js.txt
// You can also build docs locally as HTML or other formats in site/
// An online HTML version (which may be of a different version of Emscripten)
//    is up at http://kripken.github.io/emscripten-site/docs/api_reference/preamble.js.html
var wasmBinary;

if (!globalThis.WebAssembly) {
  err("no native wasm support detected");
}

// Wasm globals
// For sending to workers.
var wasmModule;

//========================================
// Runtime essentials
//========================================
// whether we are quitting the application. no code should run after this.
// set in exit() and abort()
var ABORT = false;

// set by exit() and abort().  Passed to 'onExit' handler.
// NOTE: This is also used as the process return code code in shell environments
// but only when noExitRuntime is false.
var EXITSTATUS;

// In STRICT mode, we only define assert() when ASSERTIONS is set.  i.e. we
// don't define it at all in release modes.  This matches the behaviour of
// MINIMAL_RUNTIME.
// TODO(sbc): Make this the default even without STRICT enabled.
/** @type {function(*, string=)} */ function assert(condition, text) {
  if (!condition) {
    abort("Assertion failed" + (text ? ": " + text : ""));
  }
}

// We used to include malloc/free by default in the past. Show a helpful error in
// builds with assertions.
/**
 * Indicates whether filename is delivered via file protocol (as opposed to http/https)
 * @noinline
 */ var isFileURI = filename => filename.startsWith("file://");

// include: runtime_common.js
// include: runtime_stack_check.js
// Initializes the stack cookie. Called at the startup of main and at the startup of each thread in pthreads mode.
function writeStackCookie() {
  var max = _emscripten_stack_get_end();
  assert((max & 3) == 0);
  // If the stack ends at address zero we write our cookies 4 bytes into the
  // stack.  This prevents interference with SAFE_HEAP and ASAN which also
  // monitor writes to address zero.
  if (max == 0) {
    max += 4;
  }
  // The stack grow downwards towards _emscripten_stack_get_end.
  // We write cookies to the final two words in the stack and detect if they are
  // ever overwritten.
  (growMemViews(), HEAPU32)[((max) >> 2)] = 34821223;
  (growMemViews(), HEAPU32)[(((max) + (4)) >> 2)] = 2310721022;
  // Also test the global address 0 for integrity.
  (growMemViews(), HEAPU32)[((0) >> 2)] = 1668509029;
}

function checkStackCookie() {
  if (ABORT) return;
  var max = _emscripten_stack_get_end();
  // See writeStackCookie().
  if (max == 0) {
    max += 4;
  }
  var cookie1 = (growMemViews(), HEAPU32)[((max) >> 2)];
  var cookie2 = (growMemViews(), HEAPU32)[(((max) + (4)) >> 2)];
  if (cookie1 != 34821223 || cookie2 != 2310721022) {
    abort(`Stack overflow! Stack cookie has been overwritten at ${ptrToString(max)}, expected hex dwords 0x89BACDFE and 0x2135467, but received ${ptrToString(cookie2)} ${ptrToString(cookie1)}`);
  }
  // Also test the global address 0 for integrity.
  if ((growMemViews(), HEAPU32)[((0) >> 2)] != 1668509029) {
    abort("Runtime error: The application has corrupted its heap memory area (address zero)!");
  }
}

// end include: runtime_stack_check.js
// include: runtime_exceptions.js
// end include: runtime_exceptions.js
// include: runtime_debug.js
var runtimeDebug = true;

// Switch to false at runtime to disable logging at the right times
// Used by XXXXX_DEBUG settings to output debug messages.
function dbg(...args) {
  if (!runtimeDebug && typeof runtimeDebug != "undefined") return;
  // Avoid using the console for debugging in multi-threaded node applications
  // See https://github.com/emscripten-core/emscripten/issues/14804
  if (ENVIRONMENT_IS_NODE) {
    // TODO(sbc): Unify with err/out implementation in shell.sh.
    var fs = require("fs");
    var utils = require("util");
    function stringify(a) {
      switch (typeof a) {
       case "object":
        return utils.inspect(a);

       case "undefined":
        return "undefined";
      }
      return a;
    }
    fs.writeSync(2, args.map(stringify).join(" ") + "\n");
  } else // TODO(sbc): Make this configurable somehow.  Its not always convenient for
  // logging to show up as warnings.
  console.warn(...args);
}

// Endianness check
(() => {
  var h16 = new Int16Array(1);
  var h8 = new Int8Array(h16.buffer);
  h16[0] = 25459;
  if (h8[0] !== 115 || h8[1] !== 99) abort("Runtime error: expected the system to be little-endian! (Run with -sSUPPORT_BIG_ENDIAN to bypass)");
})();

function consumedModuleProp(prop) {
  if (!Object.getOwnPropertyDescriptor(Module, prop)) {
    Object.defineProperty(Module, prop, {
      configurable: true,
      set() {
        abort(`Attempt to set \`Module.${prop}\` after it has already been processed.  This can happen, for example, when code is injected via '--post-js' rather than '--pre-js'`);
      }
    });
  }
}

function makeInvalidEarlyAccess(name) {
  return () => assert(false, `call to '${name}' via reference taken before Wasm module initialization`);
}

function ignoredModuleProp(prop) {
  if (Object.getOwnPropertyDescriptor(Module, prop)) {
    abort(`\`Module.${prop}\` was supplied but \`${prop}\` not included in INCOMING_MODULE_JS_API`);
  }
}

// forcing the filesystem exports a few things by default
function isExportedByForceFilesystem(name) {
  return name === "FS_createPath" || name === "FS_createDataFile" || name === "FS_createPreloadedFile" || name === "FS_preloadFile" || name === "FS_unlink" || name === "addRunDependency" || // The old FS has some functionality that WasmFS lacks.
  name === "FS_createLazyFile" || name === "FS_createDevice" || name === "removeRunDependency";
}

function missingLibrarySymbol(sym) {
  // Any symbol that is not included from the JS library is also (by definition)
  // not exported on the Module object.
  unexportedRuntimeSymbol(sym);
}

function unexportedRuntimeSymbol(sym) {
  if (ENVIRONMENT_IS_PTHREAD) {
    return;
  }
  if (!Object.getOwnPropertyDescriptor(Module, sym)) {
    Object.defineProperty(Module, sym, {
      configurable: true,
      get() {
        var msg = `'${sym}' was not exported. add it to EXPORTED_RUNTIME_METHODS (see the Emscripten FAQ)`;
        if (isExportedByForceFilesystem(sym)) {
          msg += ". Alternatively, forcing filesystem support (-sFORCE_FILESYSTEM) can export this for you";
        }
        abort(msg);
      }
    });
  }
}

/**
 * Override `err`/`out`/`dbg` to report thread / worker information
 */ function initWorkerLogging() {
  function getLogPrefix() {
    if (wwParams?.wwID) {
      return `ww:${wwParams?.wwID}:`;
    }
    var t = 0;
    if (runtimeInitialized && typeof _pthread_self != "undefined") {
      t = _pthread_self();
    }
    return `w:${workerID},t:${ptrToString(t)}:`;
  }
  // Prefix all dbg() messages with the calling thread info.
  var origDbg = dbg;
  dbg = (...args) => origDbg(getLogPrefix(), ...args);
}

initWorkerLogging();

// end include: runtime_debug.js
// Support for growable heap + pthreads, where the buffer may change, so JS views
// must be updated.
function growMemViews() {
  // `updateMemoryViews` updates all the views simultaneously, so it's enough to check any of them.
  if (wasmMemory.buffer != HEAP8.buffer) {
    updateMemoryViews();
  }
}

var readyPromiseResolve, readyPromiseReject;

if (ENVIRONMENT_IS_NODE && (ENVIRONMENT_IS_PTHREAD || ENVIRONMENT_IS_WASM_WORKER)) {
  // Create as web-worker-like an environment as we can.
  var parentPort = worker_threads["parentPort"];
  parentPort.on("message", msg => global.onmessage?.({
    data: msg
  }));
  Object.assign(globalThis, {
    self: global,
    postMessage: msg => parentPort["postMessage"](msg)
  });
  // Node.js Workers do not pass postMessage()s and uncaught exception events to the parent
  // thread necessarily in the same order where they were generated in sequential program order.
  // See https://github.com/nodejs/node/issues/59617
  // To remedy this, capture all uncaughtExceptions in the Worker, and sequentialize those over
  // to the same postMessage pipe that other messages use.
  process.on("uncaughtException", err => {
    postMessage({
      cmd: "uncaughtException",
      error: err
    });
    // Also shut down the Worker to match the same semantics as if this uncaughtException
    // handler was not registered.
    // (n.b. this will not shut down the whole Node.js app process, but just the Worker)
    process.exit(1);
  });
}

// include: runtime_pthread.js
// Pthread Web Worker handling code.
// This code runs only on pthread web workers and handles pthread setup
// and communication with the main thread via postMessage.
// Unique ID of the current pthread worker (zero on non-pthread-workers
// including the main thread).
var workerID = 0;

var startWorker;

if (ENVIRONMENT_IS_PTHREAD) {
  // Thread-local guard variable for one-time init of the JS state
  var initializedJS = false;
  // Turn unhandled rejected promises into errors so that the main thread will be
  // notified about them.
  self.onunhandledrejection = e => {
    throw e.reason || e;
  };
  function handleMessage(e) {
    try {
      var msgData = e["data"];
      //dbg('msgData: ' + Object.keys(msgData));
      var cmd = msgData.cmd;
      if (cmd === "load") {
        // Preload command that is called once per worker to parse and load the Emscripten code.
        workerID = msgData.workerID;
        // Until we initialize the runtime, queue up any further incoming messages.
        let messageQueue = [];
        self.onmessage = e => messageQueue.push(e);
        // And add a callback for when the runtime is initialized.
        startWorker = () => {
          // Notify the main thread that this thread has loaded.
          postMessage({
            cmd: "loaded"
          });
          // Process any messages that were queued before the thread was ready.
          for (let msg of messageQueue) {
            handleMessage(msg);
          }
          // Restore the real message handler.
          self.onmessage = handleMessage;
        };
        // Use `const` here to ensure that the variable is scoped only to
        // that iteration, allowing safe reference from a closure.
        for (const handler of msgData.handlers) {
          // The the main module has a handler for a certain even, but no
          // handler exists on the pthread worker, then proxy that handler
          // back to the main thread.
          if (!Module[handler] || Module[handler].proxy) {
            Module[handler] = (...args) => {
              postMessage({
                cmd: "callHandler",
                handler,
                args
              });
            };
            // Rebind the out / err handlers if needed
            if (handler == "print") out = Module[handler];
            if (handler == "printErr") err = Module[handler];
          }
        }
        wasmMemory = msgData.wasmMemory;
        updateMemoryViews();
        wasmModule = msgData.wasmModule;
        createWasm();
        run();
      } else if (cmd === "run") {
        assert(msgData.pthread_ptr);
        // Call inside JS module to set up the stack frame for this pthread in JS module scope.
        // This needs to be the first thing that we do, as we cannot call to any C/C++ functions
        // until the thread stack is initialized.
        establishStackSpace(msgData.pthread_ptr);
        // Pass the thread address to wasm to store it for fast access.
        __emscripten_thread_init(msgData.pthread_ptr, /*is_main=*/ 0, /*is_runtime=*/ 0, /*can_block=*/ 1, 0, 0);
        PThread.threadInitTLS();
        // Await mailbox notifications with `Atomics.waitAsync` so we can start
        // using the fast `Atomics.notify` notification path.
        __emscripten_thread_mailbox_await(msgData.pthread_ptr);
        if (!initializedJS) {
          initializedJS = true;
        }
        try {
          invokeEntryPoint(msgData.start_routine, msgData.arg);
        } catch (ex) {
          if (ex != "unwind") {
            // The pthread "crashed".  Do not call `_emscripten_thread_exit` (which
            // would make this thread joinable).  Instead, re-throw the exception
            // and let the top level handler propagate it back to the main thread.
            throw ex;
          }
        }
      } else if (msgData.target === "setimmediate") {} else if (cmd === "checkMailbox") {
        if (initializedJS) {
          checkMailbox();
        }
      } else if (cmd) {
        // The received message looks like something that should be handled by this message
        // handler, (since there is a cmd field present), but is not one of the
        // recognized commands:
        err(`worker: received unknown command ${cmd}`);
        err(msgData);
      }
    } catch (ex) {
      err(`worker: onmessage() captured an uncaught exception: ${ex}`);
      if (ex?.stack) err(ex.stack);
      __emscripten_thread_crashed();
      throw ex;
    }
  }
  self.onmessage = handleMessage;
}

// ENVIRONMENT_IS_PTHREAD
// end include: runtime_pthread.js
// include: wasm_worker.js
var wwParams;

/**
 * Called once the intiial message has been recieved from the creating thread.
 * The `props` object is property bag sent via postMessage to create the worker.
 *
 * This function is called both in normal wasm workers and in audio worklets.
 */ function startWasmWorker(props) {
  wwParams = props;
  wasmMemory = props.wasmMemory;
  updateMemoryViews();
  wasmModule = props.wasm;
  createWasm();
  run();
  // Drop now unneeded references to from the Module object in this Worker,
  // these are not needed anymore.
  props.wasm = props.memMemory = 0;
}

if (ENVIRONMENT_IS_WASM_WORKER && !ENVIRONMENT_IS_AUDIO_WORKLET) {
  // Node.js support
  if (ENVIRONMENT_IS_NODE) {
    // Weak map of handle functions to their wrapper. Used to implement
    // addEventListener/removeEventListener.
    var wrappedHandlers = new WeakMap;
    /** @suppress {checkTypes} */ globalThis.onmessage = null;
    function wrapMsgHandler(h) {
      var f = wrappedHandlers.get(h);
      if (!f) {
        f = msg => h({
          data: msg
        });
        wrappedHandlers.set(h, f);
      }
      return f;
    }
    Object.assign(globalThis, {
      addEventListener: (name, handler) => parentPort["on"](name, wrapMsgHandler(handler)),
      removeEventListener: (name, handler) => parentPort["off"](name, wrapMsgHandler(handler))
    });
  }
  onmessage = d => {
    // The first message sent to the Worker is always the bootstrap message.
    // Drop this message listener, it served its purpose of bootstrapping
    // the Wasm Module load, and is no longer needed. Let user code register
    // any desired message handlers from now on.
    /** @suppress {checkTypes} */ onmessage = null;
    startWasmWorker(d.data);
  };
}

// end include: wasm_worker.js
// include: audio_worklet.js
// This file is the main bootstrap script for Wasm Audio Worklets loaded in an
// Emscripten application.  Build with -sAUDIO_WORKLET linker flag to enable
// targeting Audio Worklets.
// AudioWorkletGlobalScope does not have a onmessage/postMessage() functionality
// at the global scope, which means that after creating an
// AudioWorkletGlobalScope and loading this script into it, we cannot
// postMessage() information into it like one would do with Web Workers.
// Instead, we must create an AudioWorkletProcessor class, then instantiate a
// Web Audio graph node from it on the main thread. Using its message port and
// the node constructor's "processorOptions" field, we can share the necessary
// bootstrap information from the main thread to the AudioWorkletGlobalScope.
if (ENVIRONMENT_IS_AUDIO_WORKLET) {
  function createWasmAudioWorkletProcessor(audioParams) {
    class WasmAudioWorkletProcessor extends AudioWorkletProcessor {
      constructor(args) {
        super();
        // Capture the Wasm function callback to invoke.
        let opts = args.processorOptions;
        assert(opts.callback);
        assert(opts.samplesPerChannel);
        this.callback = ((a1, a2, a3, a4, a5, a6, a7) => dynCall_iiiiiiii(opts.callback, a1, a2, a3, a4, a5, a6, a7));
        this.userData = opts.userData;
        // Then the samples per channel to process, fixed for the lifetime of the
        // context that created this processor. Even though this 'render quantum
        // size' is fixed at 128 samples in the 1.0 spec, it will be variable in
        // the 1.1 spec. It's passed in now, just to prove it's settable, but will
        // eventually be a property of the  AudioWorkletGlobalScope (globalThis).
        this.samplesPerChannel = opts.samplesPerChannel;
        this.bytesPerChannel = this.samplesPerChannel * 4;
        // Prepare the output views; see createOutputViews(). The 'STACK_ALIGN'
        // deduction stops the STACK_OVERFLOW_CHECK failing (since the stack will
        // be full if we allocate all the available space) leaving room for a
        // single AudioSampleFrame as a minumum. There's an arbitrary maximum of
        // 64 frames, for the case where a multi-MB stack is passed.
        this.outputViews = new Array(Math.min(((wwParams.stackSize - 16) / this.bytesPerChannel) | 0, /*sensible limit*/ 64));
        assert(this.outputViews.length > 0, `AudioWorklet needs more stack allocating (at least ${this.bytesPerChannel})`);
        this.createOutputViews();
        // Explicitly verify this later in process(). Note to self, stackSave is a
        // bit of a misnomer as it simply gets the stack address.
        this.ctorOldStackPtr = stackSave();
      }
      /**
     * Create up-front as many typed views for marshalling the output data as
     * may be required, allocated at the *top* of the worklet's stack (and whose
     * addresses are fixed). 
     */ createOutputViews() {
        // These are still alloc'd to take advantage of the overflow checks, etc.
        var oldStackPtr = stackSave();
        var viewDataIdx = ((stackAlloc(this.outputViews.length * this.bytesPerChannel)) >> 2);
        // Inserted in reverse so the lowest indices are closest to the stack top
        for (var n = this.outputViews.length - 1; n >= 0; n--) {
          this.outputViews[n] = (growMemViews(), HEAPF32).subarray(viewDataIdx, viewDataIdx += this.samplesPerChannel);
        }
        stackRestore(oldStackPtr);
      }
      static get parameterDescriptors() {
        return audioParams;
      }
      /**
     * Marshals all inputs and parameters to the Wasm memory on the thread's
     * stack, then performs the wasm audio worklet call, and finally marshals
     * audio output data back.
     *
     * @param {Object} parameters
     */ process(inputList, outputList, parameters) {
        // Recreate the output views if the heap has changed
        // TODO: add support for GROWABLE_ARRAYBUFFERS
        if ((growMemViews(), HEAPF32).buffer != this.outputViews[0].buffer) {
          this.createOutputViews();
        }
        var numInputs = inputList.length;
        var numOutputs = outputList.length;
        var entry;
        // reused list entry or index
        var subentry;
        // reused channel or other array in each list entry or index
        // Calculate the required stack and output buffer views (stack is further
        // split into aligned structs and the raw float data).
        var stackMemoryStruct = (numInputs + numOutputs) * 12;
        var stackMemoryData = 0;
        for (entry of inputList) {
          stackMemoryData += entry.length;
        }
        stackMemoryData *= this.bytesPerChannel;
        // Collect the total number of output channels (mapped to array views)
        var outputViewsNeeded = 0;
        for (entry of outputList) {
          outputViewsNeeded += entry.length;
        }
        stackMemoryData += outputViewsNeeded * this.bytesPerChannel;
        var numParams = 0;
        for (entry in parameters) {
          ++numParams;
          stackMemoryStruct += 8;
          stackMemoryData += parameters[entry].byteLength;
        }
        var oldStackPtr = stackSave();
        assert(oldStackPtr == this.ctorOldStackPtr, "AudioWorklet stack address has unexpectedly moved");
        assert(outputViewsNeeded <= this.outputViews.length, `Too many AudioWorklet outputs (need ${outputViewsNeeded} but have stack space for ${this.outputViews.length})`);
        // Allocate the necessary stack space. All pointer variables are in bytes;
        // 'structPtr' starts at the first struct entry (all run sequentially)
        // and is the working start to each record; 'dataPtr' is the same for the
        // audio/params data, starting after *all* the structs.
        // 'structPtr' begins 16-byte aligned, allocated from the internal
        // _emscripten_stack_alloc(), as are the output views, and so to ensure
        // the views fall on the correct addresses (and we finish at stacktop) we
        // request additional bytes, taking this alignment into account, then
        // offset `dataPtr` by the difference.
        var stackMemoryAligned = (stackMemoryStruct + stackMemoryData + 15) & ~15;
        var structPtr = stackAlloc(stackMemoryAligned);
        var dataPtr = structPtr + (stackMemoryAligned - stackMemoryData);
        // TODO: look at why stackAlloc isn't tripping the assertions
        assert(stackMemoryAligned <= wwParams.stackSize, `Not enough stack allocated to the AudioWorklet (need ${stackMemoryAligned}, got ${wwParams.stackSize})`);
        // Copy input audio descriptor structs and data to Wasm (recall, structs
        // first, audio data after). 'inputsPtr' is the start of the C callback's
        // input AudioSampleFrame.
        var /*const*/ inputsPtr = structPtr;
        for (entry of inputList) {
          // Write the AudioSampleFrame struct instance
          (growMemViews(), HEAPU32)[((structPtr) >> 2)] = entry.length;
          (growMemViews(), HEAPU32)[(((structPtr) + (4)) >> 2)] = this.samplesPerChannel;
          (growMemViews(), HEAPU32)[(((structPtr) + (8)) >> 2)] = dataPtr;
          structPtr += 12;
          // Marshal the input audio sample data for each audio channel of this input
          for (subentry of entry) {
            (growMemViews(), HEAPF32).set(subentry, ((dataPtr) >> 2));
            dataPtr += this.bytesPerChannel;
          }
        }
        // Copy parameters descriptor structs and data to Wasm. 'paramsPtr' is the
        // start of the C callback's input AudioParamFrame.
        var /*const*/ paramsPtr = structPtr;
        for (entry = 0; subentry = parameters[entry++]; ) {
          // Write the AudioParamFrame struct instance
          (growMemViews(), HEAPU32)[((structPtr) >> 2)] = subentry.length;
          (growMemViews(), HEAPU32)[(((structPtr) + (4)) >> 2)] = dataPtr;
          structPtr += 8;
          // Marshal the audio parameters array
          (growMemViews(), HEAPF32).set(subentry, ((dataPtr) >> 2));
          dataPtr += subentry.length * 4;
        }
        // Copy output audio descriptor structs to Wasm. 'outputsPtr' is the start
        // of the C callback's output AudioSampleFrame. 'dataPtr' will now be
        // aligned with the output views, ending at stacktop (which is why this
        // needs to be last).
        var /*const*/ outputsPtr = structPtr;
        for (entry of outputList) {
          // Write the AudioSampleFrame struct instance
          (growMemViews(), HEAPU32)[((structPtr) >> 2)] = entry.length;
          (growMemViews(), HEAPU32)[(((structPtr) + (4)) >> 2)] = this.samplesPerChannel;
          (growMemViews(), HEAPU32)[(((structPtr) + (8)) >> 2)] = dataPtr;
          structPtr += 12;
          // Advance the output pointer to the next output (matching the pre-allocated views)
          dataPtr += this.bytesPerChannel * entry.length;
        }
        // If all the maths worked out, we arrived at the original stack address
        console.assert(dataPtr == oldStackPtr, `AudioWorklet stack missmatch (audio data finishes at ${dataPtr} instead of ${oldStackPtr})`);
        // Sanity checks. If these trip the most likely cause, beyond unforeseen
        // stack shenanigans, is that the 'render quantum size' changed after
        // construction (which shouldn't be possible).
        if (numOutputs) {
          // First that the output view addresses match the stack positions
          dataPtr -= this.bytesPerChannel;
          for (entry = 0; entry < outputViewsNeeded; entry++) {
            console.assert(dataPtr == this.outputViews[entry].byteOffset, "AudioWorklet internal error in addresses of the output array views");
            dataPtr -= this.bytesPerChannel;
          }
          // And that the views' size match the passed in output buffers
          for (entry of outputList) {
            for (subentry of entry) {
              assert(subentry.byteLength == this.bytesPerChannel, `AudioWorklet unexpected output buffer size (expected ${this.bytesPerChannel} got ${subentry.byteLength})`);
            }
          }
        }
        // Call out to Wasm callback to perform audio processing
        var didProduceAudio = this.callback(numInputs, inputsPtr, numOutputs, outputsPtr, numParams, paramsPtr, this.userData);
        if (didProduceAudio) {
          // Read back the produced audio data to all outputs and their channels.
          // The preallocated 'outputViews' already have the correct offsets and
          // sizes into the stack (recall from createOutputViews() that they run
          // backwards).
          for (entry of outputList) {
            for (subentry of entry) {
              subentry.set(this.outputViews[--outputViewsNeeded]);
            }
          }
        }
        stackRestore(oldStackPtr);
        // Return 'true' to tell the browser to continue running this processor.
        // (Returning 1 or any other truthy value won't work in Chrome)
        return !!didProduceAudio;
      }
    }
    return WasmAudioWorkletProcessor;
  }
  // If this browser does not support the up-to-date AudioWorklet standard
  // that has a MessagePort over to the AudioWorklet, then polyfill that by
  // a hacky AudioWorkletProcessor that provides the MessagePort.
  // Firefox added support in https://hg-edge.mozilla.org/integration/autoland/rev/ab38a1796126f2b3fc06475ffc5a625059af59c1
  // Chrome ticket: https://crbug.com/446920095
  // Safari ticket: https://webkit.org/b/299386
  /**
 * @suppress {duplicate, checkTypes}
 */ var port = globalThis.port || {};
  // Specify a worklet processor that will be used to receive messages to this
  // AudioWorkletGlobalScope.  We never connect this initial AudioWorkletProcessor
  // to the audio graph to do any audio processing.
  class BootstrapMessages extends AudioWorkletProcessor {
    constructor(arg) {
      super();
      startWasmWorker(arg.processorOptions);
      // Listen to messages from the main thread. These messages will ask this
      // scope to create the real AudioWorkletProcessors that call out to Wasm to
      // do audio processing.
      if (!(port instanceof MessagePort)) {
        this.port.onmessage = port.onmessage;
        /** @suppress {checkTypes} */ port = this.port;
      }
    }
    // No-op, not doing audio processing in this processor. It is just for
    // receiving bootstrap messages.  However browsers require it to still be
    // present. It should never be called because we never add a node to the graph
    // with this processor, although it does look like Chrome does still call this
    // function.
    process() {}
  }
  // Register the dummy processor that will just receive messages.
  registerProcessor("em-bootstrap", BootstrapMessages);
  port.onmessage = async msg => {
    let d = msg.data;
    if (d["_boot"]) {
      startWasmWorker(d);
    } else if (d["_wpn"]) {
      // '_wpn' is short for 'Worklet Processor Node', using an identifier
      // that will never conflict with user messages
      // Register a real AudioWorkletProcessor that will actually do audio processing.
      registerProcessor(d["_wpn"], createWasmAudioWorkletProcessor(d.audioParams));
      // Post a Wasm Call message back telling that we have now registered the
      // AudioWorkletProcessor, and should trigger the user onSuccess callback
      // of the emscripten_create_wasm_audio_worklet_processor_async() call.
      // '_wsc' is short for 'wasm call', using an identifier that will never
      // conflict with user messages.
      // Note: we convert the pointer arg manually here since the call site
      // ($_EmAudioDispatchProcessorCallback) is used with various signatures
      // and we do not know the types in advance.
      port.postMessage({
        "_wsc": d.callback,
        args: [ d.contextHandle, 1, d.userData ]
      });
    } else if (d["_wsc"]) {
      getWasmTableEntry(d["_wsc"])(...d.args);
    }
  };
}

// ENVIRONMENT_IS_AUDIO_WORKLET
// end include: audio_worklet.js
// Memory management
var /** @type {!Int8Array} */ HEAP8, /** @type {!Uint8Array} */ HEAPU8, /** @type {!Int16Array} */ HEAP16, /** @type {!Uint16Array} */ HEAPU16, /** @type {!Int32Array} */ HEAP32, /** @type {!Uint32Array} */ HEAPU32, /** @type {!Float32Array} */ HEAPF32, /** @type {!Float64Array} */ HEAPF64;

// BigInt64Array type is not correctly defined in closure
var /** not-@type {!BigInt64Array} */ HEAP64, /* BigUint64Array type is not correctly defined in closure
/** not-@type {!BigUint64Array} */ HEAPU64;

var runtimeInitialized = false;

function updateMemoryViews() {
  var b = wasmMemory.buffer;
  Module["HEAP8"] = HEAP8 = new Int8Array(b);
  Module["HEAP16"] = HEAP16 = new Int16Array(b);
  Module["HEAPU8"] = HEAPU8 = new Uint8Array(b);
  Module["HEAPU16"] = HEAPU16 = new Uint16Array(b);
  Module["HEAP32"] = HEAP32 = new Int32Array(b);
  Module["HEAPU32"] = HEAPU32 = new Uint32Array(b);
  Module["HEAPF32"] = HEAPF32 = new Float32Array(b);
  Module["HEAPF64"] = HEAPF64 = new Float64Array(b);
  Module["HEAP64"] = HEAP64 = new BigInt64Array(b);
  Module["HEAPU64"] = HEAPU64 = new BigUint64Array(b);
}

// In non-standalone/normal mode, we create the memory here.
// include: runtime_init_memory.js
// Create the wasm memory. (Note: this only applies if IMPORTED_MEMORY is defined)
// check for full engine support (use string 'subarray' to avoid closure compiler confusion)
function initMemory() {
  if ((ENVIRONMENT_IS_PTHREAD || ENVIRONMENT_IS_WASM_WORKER)) {
    return;
  }
  if (Module["wasmMemory"]) {
    wasmMemory = Module["wasmMemory"];
  } else {
    var INITIAL_MEMORY = Module["INITIAL_MEMORY"] || 67108864;
    assert(INITIAL_MEMORY >= 4194304, "INITIAL_MEMORY should be larger than STACK_SIZE, was " + INITIAL_MEMORY + "! (STACK_SIZE=" + 4194304 + ")");
    /** @suppress {checkTypes} */ wasmMemory = new WebAssembly.Memory({
      "initial": INITIAL_MEMORY / 65536,
      // In theory we should not need to emit the maximum if we want "unlimited"
      // or 4GB of memory, but VMs error on that atm, see
      // https://github.com/emscripten-core/emscripten/issues/14130
      // And in the pthreads case we definitely need to emit a maximum. So
      // always emit one.
      "maximum": 32768,
      "shared": true
    });
  }
  updateMemoryViews();
}

// end include: runtime_init_memory.js
// include: memoryprofiler.js
// end include: memoryprofiler.js
// end include: runtime_common.js
assert(globalThis.Int32Array && globalThis.Float64Array && Int32Array.prototype.subarray && Int32Array.prototype.set, "JS engine does not provide full typed array support");

function preRun() {
  assert(!ENVIRONMENT_IS_PTHREAD);
  // PThreads reuse the runtime from the main thread.
  if (Module["preRun"]) {
    if (typeof Module["preRun"] == "function") Module["preRun"] = [ Module["preRun"] ];
    while (Module["preRun"].length) {
      addOnPreRun(Module["preRun"].shift());
    }
  }
  consumedModuleProp("preRun");
  // Begin ATPRERUNS hooks
  callRuntimeCallbacks(onPreRuns);
}

function initRuntime() {
  assert(!runtimeInitialized);
  runtimeInitialized = true;
  if (ENVIRONMENT_IS_WASM_WORKER) return _wasmWorkerInitializeRuntime();
  if (ENVIRONMENT_IS_PTHREAD) return startWorker();
  checkStackCookie();
  // No ATINITS hooks
  wasmExports["__wasm_call_ctors"]();
}

function postRun() {
  checkStackCookie();
  if ((ENVIRONMENT_IS_PTHREAD || ENVIRONMENT_IS_WASM_WORKER)) {
    return;
  }
  // PThreads reuse the runtime from the main thread.
  if (Module["postRun"]) {
    if (typeof Module["postRun"] == "function") Module["postRun"] = [ Module["postRun"] ];
    while (Module["postRun"].length) {
      addOnPostRun(Module["postRun"].shift());
    }
  }
  consumedModuleProp("postRun");
  // Begin ATPOSTRUNS hooks
  callRuntimeCallbacks(onPostRuns);
}

/** @param {string|number=} what */ function abort(what) {
  Module["onAbort"]?.(what);
  what = "Aborted(" + what + ")";
  // TODO(sbc): Should we remove printing and leave it up to whoever
  // catches the exception?
  err(what);
  ABORT = true;
  if (what.indexOf("RuntimeError: unreachable") >= 0) {
    what += '. "unreachable" may be due to ASYNCIFY_STACK_SIZE not being large enough (try increasing it)';
  }
  // Use a wasm runtime error, because a JS error might be seen as a foreign
  // exception, which means we'd run destructors on it. We need the error to
  // simply make the program stop.
  // FIXME This approach does not work in Wasm EH because it currently does not assume
  // all RuntimeErrors are from traps; it decides whether a RuntimeError is from
  // a trap or not based on a hidden field within the object. So at the moment
  // we don't have a way of throwing a wasm trap from JS. TODO Make a JS API that
  // allows this in the wasm spec.
  // Suppress closure compiler warning here. Closure compiler's builtin extern
  // definition for WebAssembly.RuntimeError claims it takes no arguments even
  // though it can.
  // TODO(https://github.com/google/closure-compiler/pull/3913): Remove if/when upstream closure gets fixed.
  /** @suppress {checkTypes} */ var e = new WebAssembly.RuntimeError(what);
  readyPromiseReject?.(e);
  // Throw the error whether or not MODULARIZE is set because abort is used
  // in code paths apart from instantiation where an exception is expected
  // to be thrown when abort is called.
  throw e;
}

// show errors on likely calls to FS when it was not included
var FS = {
  error() {
    abort("Filesystem support (FS) was not included. The problem is that you are using files from JS, but files were not used from C/C++, so filesystem support was not auto-included. You can force-include filesystem support with -sFORCE_FILESYSTEM");
  },
  init() {
    FS.error();
  },
  createDataFile() {
    FS.error();
  },
  createPreloadedFile() {
    FS.error();
  },
  createLazyFile() {
    FS.error();
  },
  open() {
    FS.error();
  },
  mkdev() {
    FS.error();
  },
  registerDevice() {
    FS.error();
  },
  analyzePath() {
    FS.error();
  },
  ErrnoError() {
    FS.error();
  }
};

function createExportWrapper(name, nargs) {
  return (...args) => {
    assert(runtimeInitialized, `native function \`${name}\` called before runtime initialization`);
    var f = wasmExports[name];
    assert(f, `exported native function \`${name}\` not found`);
    // Only assert for too many arguments. Too few can be valid since the missing arguments will be zero filled.
    assert(args.length <= nargs, `native function \`${name}\` called with ${args.length} args but expects ${nargs}`);
    return f(...args);
  };
}

var wasmBinaryFile;

function findWasmBinary() {
  return locateFile("libflutter_recorder_plugin_mt.wasm");
}

function getBinarySync(file) {
  if (file == wasmBinaryFile && wasmBinary) {
    return new Uint8Array(wasmBinary);
  }
  if (readBinary) {
    return readBinary(file);
  }
  // Throwing a plain string here, even though it not normally adviables since
  // this gets turning into an `abort` in instantiateArrayBuffer.
  throw "both async and sync fetching of the wasm failed";
}

async function getWasmBinary(binaryFile) {
  // If we don't have the binary yet, load it asynchronously using readAsync.
  if (!wasmBinary) {
    // Fetch the binary using readAsync
    try {
      var response = await readAsync(binaryFile);
      return new Uint8Array(response);
    } catch {}
  }
  // Otherwise, getBinarySync should be able to get it synchronously
  return getBinarySync(binaryFile);
}

async function instantiateArrayBuffer(binaryFile, imports) {
  try {
    var binary = await getWasmBinary(binaryFile);
    var instance = await WebAssembly.instantiate(binary, imports);
    return instance;
  } catch (reason) {
    err(`failed to asynchronously prepare wasm: ${reason}`);
    // Warn on some common problems.
    if (isFileURI(binaryFile)) {
      err(`warning: Loading from a file URI (${binaryFile}) is not supported in most browsers. See https://emscripten.org/docs/getting_started/FAQ.html#how-do-i-run-a-local-webserver-for-testing-why-does-my-program-stall-in-downloading-or-preparing`);
    }
    abort(reason);
  }
}

async function instantiateAsync(binary, binaryFile, imports) {
  if (!binary && !isFileURI(binaryFile) && !ENVIRONMENT_IS_NODE) {
    try {
      var response = fetch(binaryFile, {
        credentials: "same-origin"
      });
      var instantiationResult = await WebAssembly.instantiateStreaming(response, imports);
      return instantiationResult;
    } catch (reason) {
      // We expect the most common failure cause to be a bad MIME type for the binary,
      // in which case falling back to ArrayBuffer instantiation should work.
      err(`wasm streaming compile failed: ${reason}`);
      err("falling back to ArrayBuffer instantiation");
    }
  }
  return instantiateArrayBuffer(binaryFile, imports);
}

function getWasmImports() {
  assignWasmImports();
  // instrumenting imports is used in asyncify in two ways: to add assertions
  // that check for proper import use, and for ASYNCIFY=2 we use them to set up
  // the Promise API on the import side.
  // In pthreads builds getWasmImports is called more than once but we only
  // and the instrument the imports once.
  if (!wasmImports.__instrumented) {
    wasmImports.__instrumented = true;
    Asyncify.instrumentWasmImports(wasmImports);
  }
  // prepare imports
  var imports = {
    "env": wasmImports,
    "wasi_snapshot_preview1": wasmImports
  };
  return imports;
}

// Create the wasm instance.
// Receives the wasm imports, returns the exports.
async function createWasm() {
  // Load the wasm module and create an instance of using native support in the JS engine.
  // handle a generated wasm instance, receiving its exports and
  // performing other necessary setup
  /** @param {WebAssembly.Module=} module*/ function receiveInstance(instance, module) {
    wasmExports = instance.exports;
    wasmExports = Asyncify.instrumentWasmExports(wasmExports);
    registerTLSInit(wasmExports["_emscripten_tls_init"]);
    assignWasmExports(wasmExports);
    // We now have the Wasm module loaded up, keep a reference to the compiled module so we can post it to the workers.
    wasmModule = module;
    return wasmExports;
  }
  // Prefer streaming instantiation if available.
  // Async compilation can be confusing when an error on the page overwrites Module
  // (for example, if the order of elements is wrong, and the one defining Module is
  // later), so we save Module and check it later.
  var trueModule = Module;
  function receiveInstantiationResult(result) {
    // 'result' is a ResultObject object which has both the module and instance.
    // receiveInstance() will swap in the exports (to Module.asm) so they can be called
    assert(Module === trueModule, "the Module object should not be replaced during async compilation - perhaps the order of HTML elements is wrong?");
    trueModule = null;
    return receiveInstance(result["instance"], result["module"]);
  }
  var info = getWasmImports();
  // User shell pages can write their own Module.instantiateWasm = function(imports, successCallback) callback
  // to manually instantiate the Wasm module themselves. This allows pages to
  // run the instantiation parallel to any other async startup actions they are
  // performing.
  // Also pthreads and wasm workers initialize the wasm instance through this
  // path.
  if (Module["instantiateWasm"]) {
    return new Promise((resolve, reject) => {
      try {
        Module["instantiateWasm"](info, (inst, mod) => {
          resolve(receiveInstance(inst, mod));
        });
      } catch (e) {
        err(`Module.instantiateWasm callback failed with error: ${e}`);
        reject(e);
      }
    });
  }
  if ((ENVIRONMENT_IS_PTHREAD || ENVIRONMENT_IS_WASM_WORKER)) {
    // Instantiate from the module that was recieved via postMessage from
    // the main thread. We can just use sync instantiation in the worker.
    assert(wasmModule, "wasmModule should have been received via postMessage");
    var instance = new WebAssembly.Instance(wasmModule, getWasmImports());
    return receiveInstance(instance, wasmModule);
  }
  wasmBinaryFile ??= findWasmBinary();
  var result = await instantiateAsync(wasmBinary, wasmBinaryFile, info);
  var exports = receiveInstantiationResult(result);
  return exports;
}

// end include: preamble.js
// Begin JS library code
class ExitStatus {
  name="ExitStatus";
  constructor(status) {
    this.message = `Program terminated with exit(${status})`;
    this.status = status;
  }
}

var terminateWorker = worker => {
  worker.terminate();
  // terminate() can be asynchronous, so in theory the worker can continue
  // to run for some amount of time after termination.  However from our POV
  // the worker now dead and we don't want to hear from it again, so we stub
  // out its message handler here.  This avoids having to check in each of
  // the onmessage handlers if the message was coming from valid worker.
  worker.onmessage = e => {
    var cmd = e["data"].cmd;
    err(`received "${cmd}" command from terminated worker: ${worker.workerID}`);
  };
};

var cleanupThread = pthread_ptr => {
  assert(!ENVIRONMENT_IS_PTHREAD, "Internal Error! cleanupThread() can only ever be called from main application thread!");
  assert(pthread_ptr, "Internal Error! Null pthread_ptr in cleanupThread!");
  var worker = PThread.pthreads[pthread_ptr];
  assert(worker);
  PThread.returnWorkerToPool(worker);
};

var callRuntimeCallbacks = callbacks => {
  while (callbacks.length > 0) {
    // Pass the module as the first argument.
    callbacks.shift()(Module);
  }
};

var onPreRuns = [];

var addOnPreRun = cb => onPreRuns.push(cb);

var runDependencies = 0;

var dependenciesFulfilled = null;

var runDependencyTracking = {};

var runDependencyWatcher = null;

var removeRunDependency = id => {
  runDependencies--;
  Module["monitorRunDependencies"]?.(runDependencies);
  assert(id, "removeRunDependency requires an ID");
  assert(runDependencyTracking[id]);
  delete runDependencyTracking[id];
  if (runDependencies == 0) {
    if (runDependencyWatcher !== null) {
      clearInterval(runDependencyWatcher);
      runDependencyWatcher = null;
    }
    if (dependenciesFulfilled) {
      var callback = dependenciesFulfilled;
      dependenciesFulfilled = null;
      callback();
    }
  }
};

var addRunDependency = id => {
  runDependencies++;
  Module["monitorRunDependencies"]?.(runDependencies);
  assert(id, "addRunDependency requires an ID");
  assert(!runDependencyTracking[id]);
  runDependencyTracking[id] = 1;
  if (runDependencyWatcher === null && globalThis.setInterval) {
    // Check for missing dependencies every few seconds
    runDependencyWatcher = setInterval(() => {
      if (ABORT) {
        clearInterval(runDependencyWatcher);
        runDependencyWatcher = null;
        return;
      }
      var shown = false;
      for (var dep in runDependencyTracking) {
        if (!shown) {
          shown = true;
          err("still waiting on run dependencies:");
        }
        err(`dependency: ${dep}`);
      }
      if (shown) {
        err("(end of list)");
      }
    }, 1e4);
    // Prevent this timer from keeping the runtime alive if nothing
    // else is.
    runDependencyWatcher.unref?.();
  }
};

var spawnThread = threadParams => {
  assert(!ENVIRONMENT_IS_PTHREAD, "Internal Error! spawnThread() can only ever be called from main application thread!");
  assert(threadParams.pthread_ptr, "Internal error, no pthread ptr!");
  var worker = PThread.getNewWorker();
  if (!worker) {
    // No available workers in the PThread pool.
    return 6;
  }
  assert(!worker.pthread_ptr, "Internal error!");
  PThread.runningWorkers.push(worker);
  // Add to pthreads map
  PThread.pthreads[threadParams.pthread_ptr] = worker;
  worker.pthread_ptr = threadParams.pthread_ptr;
  var msg = {
    cmd: "run",
    start_routine: threadParams.startRoutine,
    arg: threadParams.arg,
    pthread_ptr: threadParams.pthread_ptr
  };
  if (ENVIRONMENT_IS_NODE) {
    // Mark worker as weakly referenced once we start executing a pthread,
    // so that its existence does not prevent Node.js from exiting.  This
    // has no effect if the worker is already weakly referenced (e.g. if
    // this worker was previously idle/unused).
    worker.unref();
  }
  // Ask the worker to start executing its pthread entry point function.
  worker.postMessage(msg, threadParams.transferList);
  return 0;
};

var runtimeKeepaliveCounter = 0;

var keepRuntimeAlive = () => noExitRuntime || runtimeKeepaliveCounter > 0;

var stackSave = () => _emscripten_stack_get_current();

var stackRestore = val => __emscripten_stack_restore(val);

var stackAlloc = sz => __emscripten_stack_alloc(sz);

/** @type{function(number, (number|boolean), ...number)} */ var proxyToMainThread = (funcIndex, emAsmAddr, sync, ...callArgs) => {
  // EM_ASM proxying is done by passing a pointer to the address of the EM_ASM
  // content as `emAsmAddr`.  JS library proxying is done by passing an index
  // into `proxiedJSCallArgs` as `funcIndex`. If `emAsmAddr` is non-zero then
  // `funcIndex` will be ignored.
  // Additional arguments are passed after the first three are the actual
  // function arguments.
  // The serialization buffer contains the number of call params, and then
  // all the args here.
  // We also pass 'sync' to C separately, since C needs to look at it.
  // Allocate a buffer, which will be copied by the C code.
  // First passed parameter specifies the number of arguments to the function.
  // When BigInt support is enabled, we must handle types in a more complex
  // way, detecting at runtime if a value is a BigInt or not (as we have no
  // type info here). To do that, add a "prefix" before each value that
  // indicates if it is a BigInt, which effectively doubles the number of
  // values we serialize for proxying. TODO: pack this?
  var serializedNumCallArgs = callArgs.length * 2;
  var sp = stackSave();
  var args = stackAlloc(serializedNumCallArgs * 8);
  var b = ((args) >> 3);
  for (var i = 0; i < callArgs.length; i++) {
    var arg = callArgs[i];
    if (typeof arg == "bigint") {
      // The prefix is non-zero to indicate a bigint.
      (growMemViews(), HEAP64)[b + 2 * i] = 1n;
      (growMemViews(), HEAP64)[b + 2 * i + 1] = arg;
    } else {
      // The prefix is zero to indicate a JS Number.
      (growMemViews(), HEAP64)[b + 2 * i] = 0n;
      (growMemViews(), HEAPF64)[b + 2 * i + 1] = arg;
    }
  }
  var rtn = __emscripten_run_js_on_main_thread(funcIndex, emAsmAddr, serializedNumCallArgs, args, sync);
  stackRestore(sp);
  return rtn;
};

function _proc_exit(code) {
  if (ENVIRONMENT_IS_PTHREAD) return proxyToMainThread(0, 0, 1, code);
  EXITSTATUS = code;
  if (!keepRuntimeAlive()) {
    PThread.terminateAllThreads();
    Module["onExit"]?.(code);
    ABORT = true;
  }
  quit_(code, new ExitStatus(code));
}

function exitOnMainThread(returnCode) {
  if (ENVIRONMENT_IS_PTHREAD) return proxyToMainThread(1, 0, 0, returnCode);
  _exit(returnCode);
}

/** @param {boolean|number=} implicit */ var exitJS = (status, implicit) => {
  EXITSTATUS = status;
  checkUnflushedContent();
  if (ENVIRONMENT_IS_PTHREAD) {
    // implicit exit can never happen on a pthread
    assert(!implicit);
    // When running in a pthread we propagate the exit back to the main thread
    // where it can decide if the whole process should be shut down or not.
    // The pthread may have decided not to exit its own runtime, for example
    // because it runs a main loop, but that doesn't affect the main thread.
    exitOnMainThread(status);
    throw "unwind";
  }
  // if exit() was called explicitly, warn the user if the runtime isn't actually being shut down
  if (keepRuntimeAlive() && !implicit) {
    var msg = `program exited (with status: ${status}), but keepRuntimeAlive() is set (counter=${runtimeKeepaliveCounter}) due to an async operation, so halting execution but not exiting the runtime or preventing further async execution (you can use emscripten_force_exit, if you want to force a true shutdown)`;
    readyPromiseReject?.(msg);
    err(msg);
  }
  _proc_exit(status);
};

var _exit = exitJS;

var ptrToString = ptr => {
  assert(typeof ptr === "number", `ptrToString expects a number, got ${typeof ptr}`);
  // Convert to 32-bit unsigned value
  ptr >>>= 0;
  return "0x" + ptr.toString(16).padStart(8, "0");
};

var PThread = {
  unusedWorkers: [],
  runningWorkers: [],
  tlsInitFunctions: [],
  pthreads: {},
  nextWorkerID: 1,
  init() {
    if ((!(ENVIRONMENT_IS_PTHREAD || ENVIRONMENT_IS_WASM_WORKER))) {
      PThread.initMainThread();
    }
  },
  initMainThread() {
    var pthreadPoolSize = 8;
    // Start loading up the Worker pool, if requested.
    while (pthreadPoolSize--) {
      PThread.allocateUnusedWorker();
    }
    // MINIMAL_RUNTIME takes care of calling loadWasmModuleToAllWorkers
    // in postamble_minimal.js
    addOnPreRun(async () => {
      var pthreadPoolReady = PThread.loadWasmModuleToAllWorkers();
      addRunDependency("loading-workers");
      await pthreadPoolReady;
      removeRunDependency("loading-workers");
    });
  },
  terminateAllThreads: () => {
    assert(!ENVIRONMENT_IS_PTHREAD, "Internal Error! terminateAllThreads() can only ever be called from main application thread!");
    // Attempt to kill all workers.  Sadly (at least on the web) there is no
    // way to terminate a worker synchronously, or to be notified when a
    // worker in actually terminated.  This means there is some risk that
    // pthreads will continue to be executing after `worker.terminate` has
    // returned.  For this reason, we don't call `returnWorkerToPool` here or
    // free the underlying pthread data structures.
    for (var worker of PThread.runningWorkers) {
      terminateWorker(worker);
    }
    for (var worker of PThread.unusedWorkers) {
      terminateWorker(worker);
    }
    PThread.unusedWorkers = [];
    PThread.runningWorkers = [];
    PThread.pthreads = {};
  },
  returnWorkerToPool: worker => {
    // We don't want to run main thread queued calls here, since we are doing
    // some operations that leave the worker queue in an invalid state until
    // we are completely done (it would be bad if free() ends up calling a
    // queued pthread_create which looks at the global data structures we are
    // modifying). To achieve that, defer the free() til the very end, when
    // we are all done.
    var pthread_ptr = worker.pthread_ptr;
    delete PThread.pthreads[pthread_ptr];
    // Note: worker is intentionally not terminated so the pool can
    // dynamically grow.
    PThread.unusedWorkers.push(worker);
    PThread.runningWorkers.splice(PThread.runningWorkers.indexOf(worker), 1);
    // Not a running Worker anymore
    // Detach the worker from the pthread object, and return it to the
    // worker pool as an unused worker.
    worker.pthread_ptr = 0;
    // Finally, free the underlying (and now-unused) pthread structure in
    // linear memory.
    __emscripten_thread_free_data(pthread_ptr);
  },
  threadInitTLS() {
    // Call thread init functions (these are the _emscripten_tls_init for each
    // module loaded.
    PThread.tlsInitFunctions.forEach(f => f());
  },
  loadWasmModuleToWorker: worker => new Promise(onFinishedLoading => {
    worker.onmessage = e => {
      var d = e["data"];
      var cmd = d.cmd;
      // If this message is intended to a recipient that is not the main
      // thread, forward it to the target thread.
      if (d.targetThread && d.targetThread != _pthread_self()) {
        var targetWorker = PThread.pthreads[d.targetThread];
        if (targetWorker) {
          targetWorker.postMessage(d, d.transferList);
        } else {
          err(`Internal error! Worker sent a message "${cmd}" to target pthread ${d.targetThread}, but that thread no longer exists!`);
        }
        return;
      }
      if (cmd === "checkMailbox") {
        checkMailbox();
      } else if (cmd === "spawnThread") {
        spawnThread(d);
      } else if (cmd === "cleanupThread") {
        // cleanupThread needs to be run via callUserCallback since it calls
        // back into user code to free thread data. Without this it's possible
        // the unwind or ExitStatus exception could escape here.
        callUserCallback(() => cleanupThread(d.thread));
      } else if (cmd === "loaded") {
        worker.loaded = true;
        // Check that this worker doesn't have an associated pthread.
        if (ENVIRONMENT_IS_NODE && !worker.pthread_ptr) {
          // Once worker is loaded & idle, mark it as weakly referenced,
          // so that mere existence of a Worker in the pool does not prevent
          // Node.js from exiting the app.
          worker.unref();
        }
        onFinishedLoading(worker);
      } else if (d.target === "setimmediate") {
        // Worker wants to postMessage() to itself to implement setImmediate()
        // emulation.
        worker.postMessage(d);
      } else if (cmd === "uncaughtException") {
        // Message handler for Node.js specific out-of-order behavior:
        // https://github.com/nodejs/node/issues/59617
        // A pthread sent an uncaught exception event. Re-raise it on the main thread.
        worker.onerror(d.error);
      } else if (cmd === "callHandler") {
        Module[d.handler](...d.args);
      } else if (cmd) {
        // The received message looks like something that should be handled by this message
        // handler, (since there is a e.data.cmd field present), but is not one of the
        // recognized commands:
        err(`worker sent an unknown command ${cmd}`);
      }
    };
    worker.onerror = e => {
      var message = "worker sent an error!";
      if (worker.pthread_ptr) {
        message = `Pthread ${ptrToString(worker.pthread_ptr)} sent an error!`;
      }
      err(`${message} ${e.filename}:${e.lineno}: ${e.message}`);
      throw e;
    };
    if (ENVIRONMENT_IS_NODE) {
      worker.on("message", data => worker.onmessage({
        data
      }));
      worker.on("error", e => worker.onerror(e));
    }
    assert(wasmMemory instanceof WebAssembly.Memory, "WebAssembly memory should have been loaded by now!");
    assert(wasmModule instanceof WebAssembly.Module, "WebAssembly Module should have been loaded by now!");
    // When running on a pthread, none of the incoming parameters on the module
    // object are present. Proxy known handlers back to the main thread if specified.
    var handlers = [];
    var knownHandlers = [ "onExit", "onAbort", "print", "printErr" ];
    for (var handler of knownHandlers) {
      if (Module.propertyIsEnumerable(handler)) {
        handlers.push(handler);
      }
    }
    // Ask the new worker to load up the Emscripten-compiled page. This is a heavy operation.
    worker.postMessage({
      cmd: "load",
      handlers,
      wasmMemory,
      wasmModule,
      "workerID": worker.workerID
    });
  }),
  async loadWasmModuleToAllWorkers() {
    // Instantiation is synchronous in pthreads.
    if (ENVIRONMENT_IS_PTHREAD || ENVIRONMENT_IS_WASM_WORKER) {
      return;
    }
    let pthreadPoolReady = Promise.all(PThread.unusedWorkers.map(PThread.loadWasmModuleToWorker));
    return pthreadPoolReady;
  },
  allocateUnusedWorker() {
    var worker;
    var pthreadMainJs = _scriptName;
    // We can't use makeModuleReceiveWithVar here since we want to also
    // call URL.createObjectURL on the mainScriptUrlOrBlob.
    if (Module["mainScriptUrlOrBlob"]) {
      pthreadMainJs = Module["mainScriptUrlOrBlob"];
      if (typeof pthreadMainJs != "string") {
        pthreadMainJs = URL.createObjectURL(pthreadMainJs);
      }
    }
    worker = new Worker(pthreadMainJs, {
      // This is the way that we signal to the node worker that it is hosting
      // a pthread.
      "workerData": "em-pthread",
      // This is the way that we signal to the Web Worker that it is hosting
      // a pthread.
      "name": "em-pthread-" + PThread.nextWorkerID
    });
    worker.workerID = PThread.nextWorkerID++;
    PThread.unusedWorkers.push(worker);
  },
  getNewWorker() {
    if (PThread.unusedWorkers.length == 0) {
      // PTHREAD_POOL_SIZE_STRICT should show a warning and, if set to level `2`, return from the function.
      // However, if we're in Node.js, then we can create new workers on the fly and PTHREAD_POOL_SIZE_STRICT
      // should be ignored altogether.
      if (!ENVIRONMENT_IS_NODE) {
        err("Tried to spawn a new thread, but the thread pool is exhausted.\n" + "This might result in a deadlock unless some threads eventually exit or the code explicitly breaks out to the event loop.\n" + "If you want to increase the pool size, use setting `-sPTHREAD_POOL_SIZE=...`." + "\nIf you want to throw an explicit error instead of the risk of deadlocking in those cases, use setting `-sPTHREAD_POOL_SIZE_STRICT=2`.");
      }
      PThread.allocateUnusedWorker();
      PThread.loadWasmModuleToWorker(PThread.unusedWorkers[0]);
    }
    return PThread.unusedWorkers.pop();
  }
};

var _wasmWorkerDelayedMessageQueue = [];

var handleException = e => {
  // Certain exception types we do not treat as errors since they are used for
  // internal control flow.
  // 1. ExitStatus, which is thrown by exit()
  // 2. "unwind", which is thrown by emscripten_unwind_to_js_event_loop() and others
  //    that wish to return to JS event loop.
  if (e instanceof ExitStatus || e == "unwind") {
    return EXITSTATUS;
  }
  checkStackCookie();
  if (e instanceof WebAssembly.RuntimeError) {
    if (_emscripten_stack_get_current() <= 0) {
      err("Stack overflow detected.  You can try increasing -sSTACK_SIZE (currently set to 4194304)");
    }
  }
  quit_(1, e);
};

var maybeExit = () => {
  if (!keepRuntimeAlive()) {
    try {
      if (ENVIRONMENT_IS_PTHREAD) {
        // exit the current thread, but only if there is one active.
        // TODO(https://github.com/emscripten-core/emscripten/issues/25076):
        // Unify this check with the runtimeExited check above
        if (_pthread_self()) __emscripten_thread_exit(EXITSTATUS);
        return;
      }
      _exit(EXITSTATUS);
    } catch (e) {
      handleException(e);
    }
  }
};

var callUserCallback = func => {
  if (ABORT) {
    err("user callback triggered after runtime exited or application aborted.  Ignoring.");
    return;
  }
  try {
    func();
    maybeExit();
  } catch (e) {
    handleException(e);
  }
};

var wasmTableMirror = [];

var getWasmTableEntry = funcPtr => {
  var func = wasmTableMirror[funcPtr];
  if (!func) {
    /** @suppress {checkTypes} */ wasmTableMirror[funcPtr] = func = wasmTable.get(funcPtr);
  }
  /** @suppress {checkTypes} */ assert(wasmTable.get(funcPtr) == func, "JavaScript-side Wasm function table mirror is out of date!");
  return func;
};

var _wasmWorkerRunPostMessage = e => {
  // '_wsc' is short for 'wasm call', trying to use an identifier name that
  // will never conflict with user code
  let data = e.data;
  let wasmCall = data["_wsc"];
  wasmCall && callUserCallback(() => getWasmTableEntry(wasmCall)(...data["x"]));
};

var _wasmWorkerAppendToQueue = e => {
  _wasmWorkerDelayedMessageQueue.push(e);
};

var _wasmWorkerInitializeRuntime = () => {
  assert(wwParams);
  assert(wwParams.wwID);
  assert(wwParams.stackLowestAddress % 16 == 0);
  assert(wwParams.stackSize % 16 == 0);
  // Wasm workers basically never exit their runtime
  noExitRuntime = 1;
  // Run the C side Worker initialization for stack and TLS.
  __emscripten_wasm_worker_initialize(wwParams.stackLowestAddress, wwParams.stackSize);
  // Record the pthread configuration, and whether this Wasm Worker supports synchronous blocking in emscripten_futex_wait().
  // (regular Wasm Workers do, AudioWorklets don't)
  ___set_thread_state(/*thread_ptr=*/ 0, /*is_main_thread=*/ 0, /*is_runtime_thread=*/ 0, /*supports_wait=*/ !ENVIRONMENT_IS_AUDIO_WORKLET);
  // Write the stack cookie last, after we have set up the proper bounds and
  // current position of the stack.
  writeStackCookie();
  // Audio Worklets do not have postMessage()ing capabilities.
  if (!ENVIRONMENT_IS_AUDIO_WORKLET) {
    // The Wasm Worker runtime is now up, so we can start processing
    // any postMessage function calls that have been received. Drop the temp
    // message handler that queued any pending incoming postMessage function calls ...
    removeEventListener("message", _wasmWorkerAppendToQueue);
    // ... then flush whatever messages we may have already gotten in the queue,
    //     and clear _wasmWorkerDelayedMessageQueue to undefined ...
    _wasmWorkerDelayedMessageQueue = _wasmWorkerDelayedMessageQueue.forEach(_wasmWorkerRunPostMessage);
    // ... and finally register the proper postMessage handler that immediately
    // dispatches incoming function calls without queueing them.
    addEventListener("message", _wasmWorkerRunPostMessage);
  }
};

var onPostRuns = [];

var addOnPostRun = cb => onPostRuns.push(cb);

var dynCalls = {};

var dynCallLegacy = (sig, ptr, args) => {
  sig = sig.replace(/p/g, "i");
  assert(sig in dynCalls, `bad function pointer type - sig is not in dynCalls: '${sig}'`);
  if (args?.length) {
    // j (64-bit integer) is fine, and is implemented as a BigInt. Without
    // legalization, the number of parameters should match (j is not expanded
    // into two i's).
    assert(args.length === sig.length - 1);
  } else {
    assert(sig.length == 1);
  }
  var f = dynCalls[sig];
  return f(ptr, ...args);
};

var dynCall = (sig, ptr, args = [], promising = false) => {
  assert(ptr, `null function pointer in dynCall`);
  assert(!promising, "async dynCall is not supported in this mode");
  var rtn = dynCallLegacy(sig, ptr, args);
  function convert(rtn) {
    return rtn;
  }
  return convert(rtn);
};

function establishStackSpace(pthread_ptr) {
  var stackHigh = (growMemViews(), HEAPU32)[(((pthread_ptr) + (52)) >> 2)];
  var stackSize = (growMemViews(), HEAPU32)[(((pthread_ptr) + (56)) >> 2)];
  var stackLow = stackHigh - stackSize;
  assert(stackHigh != 0);
  assert(stackLow != 0);
  assert(stackHigh > stackLow, "stackHigh must be higher then stackLow");
  // Set stack limits used by `emscripten/stack.h` function.  These limits are
  // cached in wasm-side globals to make checks as fast as possible.
  _emscripten_stack_set_limits(stackHigh, stackLow);
  // Call inside wasm module to set up the stack frame for this pthread in wasm module scope
  stackRestore(stackHigh);
  // Write the stack cookie last, after we have set up the proper bounds and
  // current position of the stack.
  writeStackCookie();
}

/**
     * @param {number} ptr
     * @param {string} type
     */ function getValue(ptr, type = "i8") {
  if (type.endsWith("*")) type = "*";
  switch (type) {
   case "i1":
    return (growMemViews(), HEAP8)[ptr];

   case "i8":
    return (growMemViews(), HEAP8)[ptr];

   case "i16":
    return (growMemViews(), HEAP16)[((ptr) >> 1)];

   case "i32":
    return (growMemViews(), HEAP32)[((ptr) >> 2)];

   case "i64":
    return (growMemViews(), HEAP64)[((ptr) >> 3)];

   case "float":
    return (growMemViews(), HEAPF32)[((ptr) >> 2)];

   case "double":
    return (growMemViews(), HEAPF64)[((ptr) >> 3)];

   case "*":
    return (growMemViews(), HEAPU32)[((ptr) >> 2)];

   default:
    abort(`invalid type for getValue: ${type}`);
  }
}

var invokeEntryPoint = (ptr, arg) => {
  // An old thread on this worker may have been canceled without returning the
  // `runtimeKeepaliveCounter` to zero. Reset it now so the new thread won't
  // be affected.
  runtimeKeepaliveCounter = 0;
  // Same for noExitRuntime.  The default for pthreads should always be false
  // otherwise pthreads would never complete and attempts to pthread_join to
  // them would block forever.
  // pthreads can still choose to set `noExitRuntime` explicitly, or
  // call emscripten_unwind_to_js_event_loop to extend their lifetime beyond
  // their main function.  See comment in src/runtime_pthread.js for more.
  noExitRuntime = 0;
  // pthread entry points are always of signature 'void *ThreadMain(void *arg)'
  // Native codebases sometimes spawn threads with other thread entry point
  // signatures, such as void ThreadMain(void *arg), void *ThreadMain(), or
  // void ThreadMain().  That is not acceptable per C/C++ specification, but
  // x86 compiler ABI extensions enable that to work. If you find the
  // following line to crash, either change the signature to "proper" void
  // *ThreadMain(void *arg) form, or try linking with the Emscripten linker
  // flag -sEMULATE_FUNCTION_POINTER_CASTS to add in emulation for this x86
  // ABI extension.
  var result = (a1 => dynCall_ii(ptr, a1))(arg);
  checkStackCookie();
  function finish(result) {
    // In MINIMAL_RUNTIME the noExitRuntime concept does not apply to
    // pthreads. To exit a pthread with live runtime, use the function
    // emscripten_unwind_to_js_event_loop() in the pthread body.
    if (keepRuntimeAlive()) {
      EXITSTATUS = result;
      return;
    }
    __emscripten_thread_exit(result);
  }
  finish(result);
};

invokeEntryPoint.isAsync = true;

var noExitRuntime = true;

var registerTLSInit = tlsInitFunc => PThread.tlsInitFunctions.push(tlsInitFunc);

/**
     * @param {number} ptr
     * @param {number} value
     * @param {string} type
     */ function setValue(ptr, value, type = "i8") {
  if (type.endsWith("*")) type = "*";
  switch (type) {
   case "i1":
    (growMemViews(), HEAP8)[ptr] = value;
    break;

   case "i8":
    (growMemViews(), HEAP8)[ptr] = value;
    break;

   case "i16":
    (growMemViews(), HEAP16)[((ptr) >> 1)] = value;
    break;

   case "i32":
    (growMemViews(), HEAP32)[((ptr) >> 2)] = value;
    break;

   case "i64":
    (growMemViews(), HEAP64)[((ptr) >> 3)] = BigInt(value);
    break;

   case "float":
    (growMemViews(), HEAPF32)[((ptr) >> 2)] = value;
    break;

   case "double":
    (growMemViews(), HEAPF64)[((ptr) >> 3)] = value;
    break;

   case "*":
    (growMemViews(), HEAPU32)[((ptr) >> 2)] = value;
    break;

   default:
    abort(`invalid type for setValue: ${type}`);
  }
}

var warnOnce = text => {
  warnOnce.shown ||= {};
  if (!warnOnce.shown[text]) {
    warnOnce.shown[text] = 1;
    if (ENVIRONMENT_IS_NODE) text = "warning: " + text;
    err(text);
  }
};

var wasmMemory;

var UTF8Decoder = globalThis.TextDecoder && new TextDecoder;

var findStringEnd = (heapOrArray, idx, maxBytesToRead, ignoreNul) => {
  var maxIdx = idx + maxBytesToRead;
  if (ignoreNul) return maxIdx;
  // TextDecoder needs to know the byte length in advance, it doesn't stop on
  // null terminator by itself.
  // As a tiny code save trick, compare idx against maxIdx using a negation,
  // so that maxBytesToRead=undefined/NaN means Infinity.
  while (heapOrArray[idx] && !(idx >= maxIdx)) ++idx;
  return idx;
};

/**
     * Given a pointer 'idx' to a null-terminated UTF8-encoded string in the given
     * array that contains uint8 values, returns a copy of that string as a
     * Javascript String object.
     * heapOrArray is either a regular array, or a JavaScript typed array view.
     * @param {number=} idx
     * @param {number=} maxBytesToRead
     * @param {boolean=} ignoreNul - If true, the function will not stop on a NUL character.
     * @return {string}
     */ var UTF8ArrayToString = (heapOrArray, idx = 0, maxBytesToRead, ignoreNul) => {
  var endPtr = findStringEnd(heapOrArray, idx, maxBytesToRead, ignoreNul);
  // When using conditional TextDecoder, skip it for short strings as the overhead of the native call is not worth it.
  if (endPtr - idx > 16 && heapOrArray.buffer && UTF8Decoder) {
    return UTF8Decoder.decode(heapOrArray.buffer instanceof ArrayBuffer ? heapOrArray.subarray(idx, endPtr) : heapOrArray.slice(idx, endPtr));
  }
  var str = "";
  while (idx < endPtr) {
    // For UTF8 byte structure, see:
    // http://en.wikipedia.org/wiki/UTF-8#Description
    // https://www.ietf.org/rfc/rfc2279.txt
    // https://tools.ietf.org/html/rfc3629
    var u0 = heapOrArray[idx++];
    if (!(u0 & 128)) {
      str += String.fromCharCode(u0);
      continue;
    }
    var u1 = heapOrArray[idx++] & 63;
    if ((u0 & 224) == 192) {
      str += String.fromCharCode(((u0 & 31) << 6) | u1);
      continue;
    }
    var u2 = heapOrArray[idx++] & 63;
    if ((u0 & 240) == 224) {
      u0 = ((u0 & 15) << 12) | (u1 << 6) | u2;
    } else {
      if ((u0 & 248) != 240) warnOnce("Invalid UTF-8 leading byte " + ptrToString(u0) + " encountered when deserializing a UTF-8 string in wasm memory to a JS string!");
      u0 = ((u0 & 7) << 18) | (u1 << 12) | (u2 << 6) | (heapOrArray[idx++] & 63);
    }
    if (u0 < 65536) {
      str += String.fromCharCode(u0);
    } else {
      var ch = u0 - 65536;
      str += String.fromCharCode(55296 | (ch >> 10), 56320 | (ch & 1023));
    }
  }
  return str;
};

/**
     * Given a pointer 'ptr' to a null-terminated UTF8-encoded string in the
     * emscripten HEAP, returns a copy of that string as a Javascript String object.
     *
     * @param {number} ptr
     * @param {number=} maxBytesToRead - An optional length that specifies the
     *   maximum number of bytes to read. You can omit this parameter to scan the
     *   string until the first 0 byte. If maxBytesToRead is passed, and the string
     *   at [ptr, ptr+maxBytesToReadr[ contains a null byte in the middle, then the
     *   string will cut short at that byte index.
     * @param {boolean=} ignoreNul - If true, the function will not stop on a NUL character.
     * @return {string}
     */ var UTF8ToString = (ptr, maxBytesToRead, ignoreNul) => {
  assert(typeof ptr == "number", `UTF8ToString expects a number (got ${typeof ptr})`);
  return ptr ? UTF8ArrayToString((growMemViews(), HEAPU8), ptr, maxBytesToRead, ignoreNul) : "";
};

var ___assert_fail = (condition, filename, line, func) => abort(`Assertion failed: ${UTF8ToString(condition)}, at: ` + [ filename ? UTF8ToString(filename) : "unknown filename", line, func ? UTF8ToString(func) : "unknown function" ]);

class ExceptionInfo {
  // excPtr - Thrown object pointer to wrap. Metadata pointer is calculated from it.
  constructor(excPtr) {
    this.excPtr = excPtr;
    this.ptr = excPtr - 24;
  }
  set_type(type) {
    (growMemViews(), HEAPU32)[(((this.ptr) + (4)) >> 2)] = type;
  }
  get_type() {
    return (growMemViews(), HEAPU32)[(((this.ptr) + (4)) >> 2)];
  }
  set_destructor(destructor) {
    (growMemViews(), HEAPU32)[(((this.ptr) + (8)) >> 2)] = destructor;
  }
  get_destructor() {
    return (growMemViews(), HEAPU32)[(((this.ptr) + (8)) >> 2)];
  }
  set_caught(caught) {
    caught = caught ? 1 : 0;
    (growMemViews(), HEAP8)[(this.ptr) + (12)] = caught;
  }
  get_caught() {
    return (growMemViews(), HEAP8)[(this.ptr) + (12)] != 0;
  }
  set_rethrown(rethrown) {
    rethrown = rethrown ? 1 : 0;
    (growMemViews(), HEAP8)[(this.ptr) + (13)] = rethrown;
  }
  get_rethrown() {
    return (growMemViews(), HEAP8)[(this.ptr) + (13)] != 0;
  }
  // Initialize native structure fields. Should be called once after allocated.
  init(type, destructor) {
    this.set_adjusted_ptr(0);
    this.set_type(type);
    this.set_destructor(destructor);
  }
  set_adjusted_ptr(adjustedPtr) {
    (growMemViews(), HEAPU32)[(((this.ptr) + (16)) >> 2)] = adjustedPtr;
  }
  get_adjusted_ptr() {
    return (growMemViews(), HEAPU32)[(((this.ptr) + (16)) >> 2)];
  }
}

var exceptionLast = 0;

var uncaughtExceptionCount = 0;

var ___cxa_throw = (ptr, type, destructor) => {
  var info = new ExceptionInfo(ptr);
  // Initialize ExceptionInfo content after it was allocated in __cxa_allocate_exception.
  info.init(type, destructor);
  exceptionLast = ptr;
  uncaughtExceptionCount++;
  assert(false, "Exception thrown, but exception catching is not enabled. Compile with -sNO_DISABLE_EXCEPTION_CATCHING or -sEXCEPTION_CATCHING_ALLOWED=[..] to catch.");
};

function pthreadCreateProxied(pthread_ptr, attr, startRoutine, arg) {
  if (ENVIRONMENT_IS_PTHREAD) return proxyToMainThread(2, 0, 1, pthread_ptr, attr, startRoutine, arg);
  return ___pthread_create_js(pthread_ptr, attr, startRoutine, arg);
}

var _emscripten_has_threading_support = () => !!globalThis.SharedArrayBuffer;

var ___pthread_create_js = (pthread_ptr, attr, startRoutine, arg) => {
  if (!_emscripten_has_threading_support()) {
    dbg("pthread_create: environment does not support SharedArrayBuffer, pthreads are not available");
    return 6;
  }
  // List of JS objects that will transfer ownership to the Worker hosting the thread
  var transferList = [];
  var error = 0;
  // Synchronously proxy the thread creation to main thread if possible. If we
  // need to transfer ownership of objects, then proxy asynchronously via
  // postMessage.
  if (ENVIRONMENT_IS_PTHREAD && (transferList.length === 0 || error)) {
    return pthreadCreateProxied(pthread_ptr, attr, startRoutine, arg);
  }
  // If on the main thread, and accessing Canvas/OffscreenCanvas failed, abort
  // with the detected error.
  if (error) return error;
  var threadParams = {
    startRoutine,
    pthread_ptr,
    arg,
    transferList
  };
  if (ENVIRONMENT_IS_PTHREAD) {
    // The prepopulated pool of web workers that can host pthreads is stored
    // in the main JS thread. Therefore if a pthread is attempting to spawn a
    // new thread, the thread creation must be deferred to the main JS thread.
    threadParams.cmd = "spawnThread";
    postMessage(threadParams, transferList);
    // When we defer thread creation this way, we have no way to detect thread
    // creation synchronously today, so we have to assume success and return 0.
    return 0;
  }
  // We are the main thread, so we have the pthread warmup pool in this
  // thread and can fire off JS thread creation directly ourselves.
  return spawnThread(threadParams);
};

var __abort_js = () => abort("native code called abort()");

var __emscripten_init_main_thread_js = tb => {
  // Pass the thread address to the native code where they stored in wasm
  // globals which act as a form of TLS. Global constructors trying
  // to access this value will read the wrong value, but that is UB anyway.
  __emscripten_thread_init(tb, /*is_main=*/ !ENVIRONMENT_IS_WORKER, /*is_runtime=*/ 1, /*can_block=*/ !ENVIRONMENT_IS_WEB, /*default_stacksize=*/ 4194304, /*start_profiling=*/ false);
  PThread.threadInitTLS();
};

var waitAsyncPolyfilled = (!Atomics.waitAsync || (globalThis.navigator?.userAgent && Number((navigator.userAgent.match(/Chrom(e|ium)\/([0-9]+)\./) || [])[2]) < 91));

var __emscripten_thread_mailbox_await = pthread_ptr => {
  if (!waitAsyncPolyfilled) {
    // Wait on the pthread's initial self-pointer field because it is easy and
    // safe to access from sending threads that need to notify the waiting
    // thread.
    // TODO: How to make this work with wasm64?
    var wait = Atomics.waitAsync((growMemViews(), HEAP32), ((pthread_ptr) >> 2), pthread_ptr);
    assert(wait.async);
    wait.value.then(checkMailbox);
    var waitingAsync = pthread_ptr + 128;
    Atomics.store((growMemViews(), HEAP32), ((waitingAsync) >> 2), 1);
  }
};

var checkMailbox = () => callUserCallback(() => {
  // Only check the mailbox if we have a live pthread runtime. We implement
  // pthread_self to return 0 if there is no live runtime.
  // TODO(https://github.com/emscripten-core/emscripten/issues/25076):
  // Is this check still needed?  `callUserCallback` is supposed to
  // ensure the runtime is alive, and if `_pthread_self` is NULL then the
  // runtime certainly is *not* alive, so this should be a redundant check.
  var pthread_ptr = _pthread_self();
  if (pthread_ptr) {
    // If we are using Atomics.waitAsync as our notification mechanism, wait
    // for a notification before processing the mailbox to avoid missing any
    // work that could otherwise arrive after we've finished processing the
    // mailbox and before we're ready for the next notification.
    __emscripten_thread_mailbox_await(pthread_ptr);
    __emscripten_check_mailbox();
  }
});

var __emscripten_notify_mailbox_postmessage = (targetThread, currThreadId) => {
  if (targetThread == currThreadId) {
    setTimeout(checkMailbox);
  } else if (ENVIRONMENT_IS_PTHREAD) {
    postMessage({
      targetThread,
      cmd: "checkMailbox"
    });
  } else {
    var worker = PThread.pthreads[targetThread];
    if (!worker) {
      err(`Cannot send message to thread with ID ${targetThread}, unknown thread ID!`);
      return;
    }
    worker.postMessage({
      cmd: "checkMailbox"
    });
  }
};

var proxiedJSCallArgs = [];

var __emscripten_receive_on_main_thread_js = (funcIndex, emAsmAddr, callingThread, numCallArgs, args) => {
  // Sometimes we need to backproxy events to the calling thread (e.g.
  // HTML5 DOM events handlers such as
  // emscripten_set_mousemove_callback()), so keep track in a globally
  // accessible variable about the thread that initiated the proxying.
  numCallArgs /= 2;
  proxiedJSCallArgs.length = numCallArgs;
  var b = ((args) >> 3);
  for (var i = 0; i < numCallArgs; i++) {
    if ((growMemViews(), HEAP64)[b + 2 * i]) {
      // It's a BigInt.
      proxiedJSCallArgs[i] = (growMemViews(), HEAP64)[b + 2 * i + 1];
    } else {
      // It's a Number.
      proxiedJSCallArgs[i] = (growMemViews(), HEAPF64)[b + 2 * i + 1];
    }
  }
  // Proxied JS library funcs use funcIndex and EM_ASM functions use emAsmAddr
  var func = emAsmAddr ? ASM_CONSTS[emAsmAddr] : proxiedFunctionTable[funcIndex];
  assert(!(funcIndex && emAsmAddr));
  assert(func.length == numCallArgs, "Call args mismatch in _emscripten_receive_on_main_thread_js");
  PThread.currentProxiedOperationCallerThread = callingThread;
  var rtn = func(...proxiedJSCallArgs);
  PThread.currentProxiedOperationCallerThread = 0;
  // Proxied functions can return any type except bigint.  All other types
  // cooerce to f64/double (the return type of this function in C) but not
  // bigint.
  assert(typeof rtn != "bigint");
  return rtn;
};

var __emscripten_thread_cleanup = thread => {
  // Called when a thread needs to be cleaned up so it can be reused.
  // A thread is considered reusable when it either returns from its
  // entry point, calls pthread_exit, or acts upon a cancellation.
  // Detached threads are responsible for calling this themselves,
  // otherwise pthread_join is responsible for calling this.
  if (!ENVIRONMENT_IS_PTHREAD) cleanupThread(thread); else postMessage({
    cmd: "cleanupThread",
    thread
  });
};

var __emscripten_thread_set_strongref = thread => {
  // Called when a thread needs to be strongly referenced.
  // Currently only used for:
  // - keeping the "main" thread alive in PROXY_TO_PTHREAD mode;
  // - crashed threads that needs to propagate the uncaught exception
  //   back to the main thread.
  if (ENVIRONMENT_IS_NODE) {
    PThread.pthreads[thread].ref();
  }
};

var _emscripten_get_now;

// AudioWorkletGlobalScope does not have performance.now()
// (https://github.com/WebAudio/web-audio-api/issues/2527), so if building
// with
// Audio Worklets enabled, do a dynamic check for its presence.
if (globalThis.performance && performance.now) {
  _emscripten_get_now = () => performance.timeOrigin + performance.now();
} else {
  _emscripten_get_now = Date.now;
}

var _emscripten_date_now = () => Date.now();

var nowIsMonotonic = !!globalThis.performance?.now;

var checkWasiClock = clock_id => clock_id >= 0 && clock_id <= 3;

var INT53_MAX = 9007199254740992;

var INT53_MIN = -9007199254740992;

var bigintToI53Checked = num => (num < INT53_MIN || num > INT53_MAX) ? NaN : Number(num);

function _clock_time_get(clk_id, ignored_precision, ptime) {
  ignored_precision = bigintToI53Checked(ignored_precision);
  if (!checkWasiClock(clk_id)) {
    return 28;
  }
  var now;
  // all wasi clocks but realtime are monotonic
  if (clk_id === 0) {
    now = _emscripten_date_now();
  } else if (nowIsMonotonic) {
    now = _emscripten_get_now();
  } else {
    return 52;
  }
  // "now" is in ms, and wasi times are in ns.
  var nsec = Math.round(now * 1e3 * 1e3);
  (growMemViews(), HEAP64)[((ptime) >> 3)] = BigInt(nsec);
  return 0;
}

var readEmAsmArgsArray = [];

var readEmAsmArgs = (sigPtr, buf) => {
  // Nobody should have mutated _readEmAsmArgsArray underneath us to be something else than an array.
  assert(Array.isArray(readEmAsmArgsArray));
  // The input buffer is allocated on the stack, so it must be stack-aligned.
  assert(buf % 16 == 0);
  readEmAsmArgsArray.length = 0;
  var ch;
  // Most arguments are i32s, so shift the buffer pointer so it is a plain
  // index into HEAP32.
  while (ch = (growMemViews(), HEAPU8)[sigPtr++]) {
    var chr = String.fromCharCode(ch);
    var validChars = [ "d", "f", "i", "p" ];
    // In WASM_BIGINT mode we support passing i64 values as bigint.
    validChars.push("j");
    assert(validChars.includes(chr), `Invalid character ${ch}("${chr}") in readEmAsmArgs! Use only [${validChars}], and do not specify "v" for void return argument.`);
    // Floats are always passed as doubles, so all types except for 'i'
    // are 8 bytes and require alignment.
    var wide = (ch != 105);
    wide &= (ch != 112);
    buf += wide && (buf % 8) ? 4 : 0;
    readEmAsmArgsArray.push(// Special case for pointers under wasm64 or CAN_ADDRESS_2GB mode.
    ch == 112 ? (growMemViews(), HEAPU32)[((buf) >> 2)] : ch == 106 ? (growMemViews(), 
    HEAP64)[((buf) >> 3)] : ch == 105 ? (growMemViews(), HEAP32)[((buf) >> 2)] : (growMemViews(), 
    HEAPF64)[((buf) >> 3)]);
    buf += wide ? 8 : 4;
  }
  return readEmAsmArgsArray;
};

var runEmAsmFunction = (code, sigPtr, argbuf) => {
  var args = readEmAsmArgs(sigPtr, argbuf);
  assert(ASM_CONSTS.hasOwnProperty(code), `No EM_ASM constant found at address ${code}.  The loaded WebAssembly file is likely out of sync with the generated JavaScript.`);
  return ASM_CONSTS[code](...args);
};

var _emscripten_asm_const_int = (code, sigPtr, argbuf) => runEmAsmFunction(code, sigPtr, argbuf);

var emAudioExpectNodeOrContext = (handle, methodName) => {
  var obj = _emAudioExpectHandle(handle, methodName);
  assert(obj instanceof window.AudioNode || obj instanceof (window.AudioContext || window.webkitAudioContext), `${methodName}() called with a handle ${handle} that is not an AudioContext or AudioNode, but of type ${typeof obj}`);
};

var emAudioExpectContext = (handle, methodName) => {
  var obj = _emAudioExpectHandle(handle, methodName);
  assert(obj instanceof (window.AudioContext || window.webkitAudioContext), `${methodName}() called with ${handle} that is not an AudioContext, but of type ${typeof obj}`);
};

var emAudioExpectNode = (handle, methodName) => {
  var obj = _emAudioExpectHandle(handle, methodName);
  assert(obj instanceof window.AudioNode, `${methodName}() called with a handle ${handle} that is not an AudioNode, but of type ${typeof obj}`);
};

var _emAudioExpectHandle = (handle, methodName) => {
  var obj = emAudio[handle];
  assert(obj, `Called ${methodName}() on a nonexisting handle ${handle}`);
  return obj;
};

var emscriptenGetContextQuantumSize = contextHandle => emAudio[contextHandle]["renderQuantumSize"] || 128;

var _emscripten_audio_context_quantum_size = contextHandle => {
  emAudioExpectContext(contextHandle, "emscripten_audio_context_quantum_size");
  return emscriptenGetContextQuantumSize(contextHandle);
};

function emAudioWorkletPostFunction(audioContext, funcPtr, args) {
  assert(funcPtr);
  if (audioContext) emAudioExpectContext(audioContext, "emAudioWorkletPostFunction");
  // _wsc = "WaSm Call"
  (audioContext ? emAudio[audioContext].audioWorklet["port"] : port).postMessage({
    "_wsc": funcPtr,
    args
  });
}

var _emscripten_audio_worklet_post_function_sig = (audioContext, funcPtr, sigPtr, varargs) => {
  assert(sigPtr);
  assert(UTF8ToString(sigPtr)[0] != "v", "Do NOT specify the return argument in the signature string for a call to emscripten_audio_worklet_post_function_sig(), just pass the function arguments.");
  assert(varargs);
  emAudioWorkletPostFunction(audioContext, funcPtr, readEmAsmArgs(sigPtr, varargs));
};

var emscripten_audio_worklet_post_function_3 = (audioContext, funcPtr, arg0, arg1, arg2) => {
  emAudioWorkletPostFunction(audioContext, funcPtr, [ arg0, arg1, arg2 ]);
};

var _emscripten_audio_worklet_post_function_viii = (audioContext, funcPtr, arg0, arg1, arg2) => {
  emscripten_audio_worklet_post_function_3(audioContext, funcPtr, arg0, arg1, arg2);
};

var _emscripten_check_blocking_allowed = () => {
  if (ENVIRONMENT_IS_NODE) return;
  if (ENVIRONMENT_IS_WORKER) return;
  // Blocking in a worker/pthread is fine.
  warnOnce("Blocking on the main thread is very dangerous, see https://emscripten.org/docs/porting/pthreads.html#blocking-on-the-main-browser-thread");
};

var emAudio = {};

var emAudioCounter = 0;

var emscriptenRegisterAudioObject = object => {
  assert(object, "Called emscriptenRegisterAudioObject() with a null object handle!");
  emAudio[++emAudioCounter] = object;
  return emAudioCounter;
};

var emscriptenGetAudioObject = objectHandle => emAudio[objectHandle];

var _emscripten_create_audio_context = options => {
  // Safari added unprefixed AudioContext support in Safari 14.5 on iOS: https://caniuse.com/audio-api
  var ctx = window.AudioContext || window.webkitAudioContext;
  if (!ctx) console.error("emscripten_create_audio_context failed! Web Audio is not supported.");
  // Converts AUDIO_CONTEXT_RENDER_SIZE_* into AudioContextRenderSizeCategory
  // enums, otherwise returns a positive int value.
  function readRenderSizeHint(val) {
    return (val < 0) ? "hardware" : (val || "default");
  }
  var opts = options ? {
    latencyHint: UTF8ToString((growMemViews(), HEAPU32)[((options) >> 2)]) || undefined,
    sampleRate: (growMemViews(), HEAPU32)[(((options) + (4)) >> 2)] || undefined,
    renderSizeHint: readRenderSizeHint((growMemViews(), HEAP32)[(((options) + (8)) >> 2)])
  } : undefined;
  return ctx && emscriptenRegisterAudioObject(new ctx(opts));
};

var _emscripten_create_wasm_audio_worklet_node = (contextHandle, name, options, callback, userData) => {
  emAudioExpectContext(contextHandle, "emscripten_create_wasm_audio_worklet_node");
  function readChannelCountArray(heapIndex, numOutputs) {
    if (!heapIndex) return undefined;
    heapIndex = ((heapIndex) >> 2);
    var channelCounts = [];
    while (numOutputs--) channelCounts.push((growMemViews(), HEAPU32)[heapIndex++]);
    return channelCounts;
  }
  var optionsOutputs = options ? (growMemViews(), HEAP32)[(((options) + (4)) >> 2)] : 0;
  var opts = options ? {
    numberOfInputs: (growMemViews(), HEAP32)[((options) >> 2)],
    numberOfOutputs: optionsOutputs,
    outputChannelCount: readChannelCountArray((growMemViews(), HEAPU32)[(((options) + (8)) >> 2)], optionsOutputs),
    channelCount: (growMemViews(), HEAPU32)[(((options) + (12)) >> 2)] || undefined,
    channelCountMode: [ , "clamped-max", "explicit" ][(growMemViews(), HEAP32)[(((options) + (16)) >> 2)]],
    channelInterpretation: [ , "discrete" ][(growMemViews(), HEAP32)[(((options) + (20)) >> 2)]],
    processorOptions: {
      callback,
      userData,
      samplesPerChannel: emscriptenGetContextQuantumSize(contextHandle)
    }
  } : undefined;
  return emscriptenRegisterAudioObject(new AudioWorkletNode(emAudio[contextHandle], UTF8ToString(name), opts));
};

var _emscripten_create_wasm_audio_worklet_processor_async = (contextHandle, options, callback, userData) => {
  emAudioExpectContext(contextHandle, "emscripten_create_wasm_audio_worklet_processor_async");
  var processorName = UTF8ToString((growMemViews(), HEAPU32)[((options) >> 2)]);
  var numAudioParams = (growMemViews(), HEAP32)[(((options) + (4)) >> 2)];
  var audioParamDescriptors = (growMemViews(), HEAPU32)[(((options) + (8)) >> 2)];
  var audioParams = [];
  var paramIndex = 0;
  while (numAudioParams--) {
    audioParams.push({
      name: paramIndex++,
      defaultValue: (growMemViews(), HEAPF32)[((audioParamDescriptors) >> 2)],
      minValue: (growMemViews(), HEAPF32)[(((audioParamDescriptors) + (4)) >> 2)],
      maxValue: (growMemViews(), HEAPF32)[(((audioParamDescriptors) + (8)) >> 2)],
      automationRate: ((growMemViews(), HEAP32)[(((audioParamDescriptors) + (12)) >> 2)] ? "k" : "a") + "-rate"
    });
    audioParamDescriptors += 16;
  }
  emAudio[contextHandle].audioWorklet["port"].postMessage({
    // Deliberately mangled and short names used here ('_wpn', the 'Worklet
    // Processor Name' used as a 'key' to verify the message type so as to
    // not get accidentally mixed with user submitted messages, the remainder
    // for space saving reasons, abbreviated from their variable names).
    "_wpn": processorName,
    audioParams,
    contextHandle,
    callback,
    userData
  });
};

var _emscripten_destroy_audio_context = contextHandle => {
  emAudioExpectContext(contextHandle, "emscripten_destroy_audio_context");
  emAudio[contextHandle].suspend();
  delete emAudio[contextHandle];
};

var _emscripten_destroy_web_audio_node = objectHandle => {
  emAudioExpectNode(objectHandle, "emscripten_destroy_web_audio_node");
  // Explicitly disconnect the node from Web Audio graph before letting it GC,
  // to work around browser bugs such as https://webkit.org/b/222098#c23
  emAudio[objectHandle].disconnect();
  delete emAudio[objectHandle];
};

var runtimeKeepalivePush = () => {
  runtimeKeepaliveCounter += 1;
};

var _emscripten_exit_with_live_runtime = () => {
  runtimeKeepalivePush();
  throw "unwind";
};

var getHeapMax = () => // Stay one Wasm page short of 4GB: while e.g. Chrome is able to allocate
// full 4GB Wasm memories, the size will wrap back to 0 bytes in Wasm side
// for any code that deals with heap sizes, which would require special
// casing all heap size related code to treat 0 specially.
2147483648;

var alignMemory = (size, alignment) => {
  assert(alignment, "alignment argument is required");
  return Math.ceil(size / alignment) * alignment;
};

var growMemory = size => {
  var oldHeapSize = wasmMemory.buffer.byteLength;
  var pages = ((size - oldHeapSize + 65535) / 65536) | 0;
  try {
    // round size grow request up to wasm page size (fixed 64KB per spec)
    wasmMemory.grow(pages);
    // .grow() takes a delta compared to the previous size
    updateMemoryViews();
    return 1;
  } catch (e) {
    err(`growMemory: Attempted to grow heap from ${oldHeapSize} bytes to ${size} bytes, but got error: ${e}`);
  }
};

var _emscripten_resize_heap = requestedSize => {
  var oldSize = (growMemViews(), HEAPU8).length;
  // With CAN_ADDRESS_2GB or MEMORY64, pointers are already unsigned.
  requestedSize >>>= 0;
  // With multithreaded builds, races can happen (another thread might increase the size
  // in between), so return a failure, and let the caller retry.
  if (requestedSize <= oldSize) {
    return false;
  }
  // Memory resize rules:
  // 1.  Always increase heap size to at least the requested size, rounded up
  //     to next page multiple.
  // 2a. If MEMORY_GROWTH_LINEAR_STEP == -1, excessively resize the heap
  //     geometrically: increase the heap size according to
  //     MEMORY_GROWTH_GEOMETRIC_STEP factor (default +20%), At most
  //     overreserve by MEMORY_GROWTH_GEOMETRIC_CAP bytes (default 96MB).
  // 2b. If MEMORY_GROWTH_LINEAR_STEP != -1, excessively resize the heap
  //     linearly: increase the heap size by at least
  //     MEMORY_GROWTH_LINEAR_STEP bytes.
  // 3.  Max size for the heap is capped at 2048MB-WASM_PAGE_SIZE, or by
  //     MAXIMUM_MEMORY, or by ASAN limit, depending on which is smallest
  // 4.  If we were unable to allocate as much memory, it may be due to
  //     over-eager decision to excessively reserve due to (3) above.
  //     Hence if an allocation fails, cut down on the amount of excess
  //     growth, in an attempt to succeed to perform a smaller allocation.
  // A limit is set for how much we can grow. We should not exceed that
  // (the wasm binary specifies it, so if we tried, we'd fail anyhow).
  var maxHeapSize = getHeapMax();
  if (requestedSize > maxHeapSize) {
    err(`Cannot enlarge memory, requested ${requestedSize} bytes, but the limit is ${maxHeapSize} bytes!`);
    return false;
  }
  // Loop through potential heap size increases. If we attempt a too eager
  // reservation that fails, cut down on the attempted size and reserve a
  // smaller bump instead. (max 3 times, chosen somewhat arbitrarily)
  for (var cutDown = 1; cutDown <= 4; cutDown *= 2) {
    var overGrownHeapSize = oldSize * (1 + .2 / cutDown);
    // ensure geometric growth
    // but limit overreserving (default to capping at +96MB overgrowth at most)
    overGrownHeapSize = Math.min(overGrownHeapSize, requestedSize + 100663296);
    var newSize = Math.min(maxHeapSize, alignMemory(Math.max(requestedSize, overGrownHeapSize), 65536));
    var replacement = growMemory(newSize);
    if (replacement) {
      return true;
    }
  }
  err(`Failed to grow the heap from ${oldSize} bytes to ${newSize} bytes, not enough memory!`);
  return false;
};

var runtimeKeepalivePop = () => {
  assert(runtimeKeepaliveCounter > 0);
  runtimeKeepaliveCounter -= 1;
};

/** @param {number=} timeout */ var safeSetTimeout = (func, timeout) => {
  runtimeKeepalivePush();
  return setTimeout(() => {
    runtimeKeepalivePop();
    callUserCallback(func);
  }, timeout);
};

var _emscripten_sleep = ms => Asyncify.handleSleep(wakeUp => safeSetTimeout(wakeUp, ms));

_emscripten_sleep.isAsync = true;

var _wasmWorkersID = 1;

var _emAudioDispatchProcessorCallback = e => {
  var data = e.data;
  // '_wsc' is short for 'wasm call', trying to use an identifier name that
  // will never conflict with user code. This is used to call both the 3-param
  // call (handle, true, userData) and the variable argument post functions.
  var wasmCall = data["_wsc"];
  wasmCall && getWasmTableEntry(wasmCall)(...data.args);
};

var _emscripten_start_wasm_audio_worklet_thread_async = (contextHandle, stackLowestAddress, stackSize, callback, userData) => {
  emAudioExpectContext(contextHandle, "emscripten_start_wasm_audio_worklet_thread_async");
  var audioContext = emAudio[contextHandle];
  var audioWorklet = audioContext.audioWorklet;
  assert(stackLowestAddress != 0, "AudioWorklets require a dedicated stack space for audio data marshalling between Wasm and JS!");
  assert(stackLowestAddress % 16 == 0, `AudioWorklet stack should be aligned to 16 bytes! (was ${stackLowestAddress} == ${stackLowestAddress % 16} mod 16) Use e.g. memalign(16, stackSize) to align the stack!`);
  assert(stackSize != 0, "AudioWorklets require a dedicated stack space for audio data marshalling between Wasm and JS!");
  assert(stackSize % 16 == 0, `AudioWorklet stack size should be a multiple of 16 bytes! (was ${stackSize} == ${stackSize % 16} mod 16)`);
  assert(!audioContext.audioWorkletInitialized, "emscripten_create_wasm_audio_worklet() was already called for AudioContext " + contextHandle + "! Only call this function once per AudioContext!");
  audioContext.audioWorkletInitialized = 1;
  var audioWorkletCreationFailed = () => {
    dbg(`emscripten_start_wasm_audio_worklet_thread_async() addModule() failed!`);
    ((a1, a2, a3) => dynCall_viii(callback, a1, a2, a3))(contextHandle, 0, userData);
  };
  // Does browser not support AudioWorklets?
  if (!audioWorklet) {
    if (location.protocol == "http:") {
      console.error(`AudioWorklets are not supported. This is possibly due to running the page over unsecure http:// protocol. Try running over https://, or debug via a localhost-based server, which should also allow AudioWorklets to function.`);
    } else {
      console.error(`AudioWorklets are not supported by current browser.`);
    }
    return audioWorkletCreationFailed();
  }
  audioWorklet.addModule(locateFile("libflutter_recorder_plugin_mt.js")).then(() => {
    // If this browser does not support the up-to-date AudioWorklet standard
    // that has a MessagePort over to the AudioWorklet, then polyfill that by
    // instantiating a dummy AudioWorkletNode to get a MessagePort over.
    // Firefox added support in https://hg-edge.mozilla.org/integration/autoland/rev/ab38a1796126f2b3fc06475ffc5a625059af59c1
    // Chrome ticket: https://crbug.com/446920095
    // Safari ticket: https://webkit.org/b/299386
    if (!audioWorklet["port"]) {
      audioWorklet["port"] = {
        postMessage: msg => {
          if (msg["_boot"]) {
            audioWorklet.bootstrapMessage = new AudioWorkletNode(audioContext, "em-bootstrap", {
              processorOptions: msg
            });
            audioWorklet.bootstrapMessage["port"].onmessage = msg => {
              audioWorklet["port"].onmessage(msg);
            };
          } else {
            audioWorklet.bootstrapMessage["port"].postMessage(msg);
          }
        }
      };
    }
    audioWorklet["port"].postMessage({
      // This is the bootstrap message to the Audio Worklet.
      "_boot": 1,
      // Assign the loaded AudioWorkletGlobalScope a Wasm Worker ID so that
      // it can utilized its own TLS slots, and it is recognized to not be
      // the main browser thread.
      wwID: _wasmWorkersID++,
      wasm: wasmModule,
      wasmMemory,
      stackLowestAddress,
      // sb = stack base
      stackSize
    });
    audioWorklet["port"].onmessage = _emAudioDispatchProcessorCallback;
    ((a1, a2, a3) => dynCall_viii(callback, a1, a2, a3))(contextHandle, 1, userData);
  }).catch(audioWorkletCreationFailed);
};

var SYSCALLS = {
  varargs: undefined,
  getStr(ptr) {
    var ret = UTF8ToString(ptr);
    return ret;
  }
};

function _fd_close(fd) {
  if (ENVIRONMENT_IS_PTHREAD) return proxyToMainThread(3, 0, 1, fd);
  abort("fd_close called without SYSCALLS_REQUIRE_FILESYSTEM");
}

function _fd_seek(fd, offset, whence, newOffset) {
  if (ENVIRONMENT_IS_PTHREAD) return proxyToMainThread(4, 0, 1, fd, offset, whence, newOffset);
  offset = bigintToI53Checked(offset);
  return 70;
}

var printCharBuffers = [ null, [], [] ];

var printChar = (stream, curr) => {
  var buffer = printCharBuffers[stream];
  assert(buffer);
  if (curr === 0 || curr === 10) {
    (stream === 1 ? out : err)(UTF8ArrayToString(buffer));
    buffer.length = 0;
  } else {
    buffer.push(curr);
  }
};

var flush_NO_FILESYSTEM = () => {
  // flush anything remaining in the buffers during shutdown
  _fflush(0);
  if (printCharBuffers[1].length) printChar(1, 10);
  if (printCharBuffers[2].length) printChar(2, 10);
};

function _fd_write(fd, iov, iovcnt, pnum) {
  if (ENVIRONMENT_IS_PTHREAD) return proxyToMainThread(5, 0, 1, fd, iov, iovcnt, pnum);
  // hack to support printf in SYSCALLS_REQUIRE_FILESYSTEM=0
  var num = 0;
  for (var i = 0; i < iovcnt; i++) {
    var ptr = (growMemViews(), HEAPU32)[((iov) >> 2)];
    var len = (growMemViews(), HEAPU32)[(((iov) + (4)) >> 2)];
    iov += 8;
    for (var j = 0; j < len; j++) {
      printChar(fd, (growMemViews(), HEAPU8)[ptr + j]);
    }
    num += len;
  }
  (growMemViews(), HEAPU32)[((pnum) >> 2)] = num;
  return 0;
}

var runAndAbortIfError = func => {
  try {
    return func();
  } catch (e) {
    abort(e);
  }
};

var createNamedFunction = (name, func) => Object.defineProperty(func, "name", {
  value: name
});

var Asyncify = {
  instrumentWasmImports(imports) {
    var importPattern = /^(invoke_.*|__asyncjs__.*)$/;
    for (let [x, original] of Object.entries(imports)) {
      if (typeof original == "function") {
        let isAsyncifyImport = original.isAsync || importPattern.test(x);
        imports[x] = (...args) => {
          var originalAsyncifyState = Asyncify.state;
          try {
            return original(...args);
          } finally {
            // Only asyncify-declared imports are allowed to change the
            // state.
            // Changing the state from normal to disabled is allowed (in any
            // function) as that is what shutdown does (and we don't have an
            // explicit list of shutdown imports).
            var changedToDisabled = originalAsyncifyState === Asyncify.State.Normal && Asyncify.state === Asyncify.State.Disabled;
            // invoke_* functions are allowed to change the state if we do
            // not ignore indirect calls.
            var ignoredInvoke = x.startsWith("invoke_") && true;
            if (Asyncify.state !== originalAsyncifyState && !isAsyncifyImport && !changedToDisabled && !ignoredInvoke) {
              abort(`import ${x} was not in ASYNCIFY_IMPORTS, but changed the state`);
            }
          }
        };
      }
    }
  },
  instrumentFunction(original) {
    var wrapper = (...args) => {
      Asyncify.exportCallStack.push(original);
      try {
        return original(...args);
      } finally {
        if (!ABORT) {
          var top = Asyncify.exportCallStack.pop();
          assert(top === original);
          Asyncify.maybeStopUnwind();
        }
      }
    };
    Asyncify.funcWrappers.set(original, wrapper);
    wrapper = createNamedFunction(`__asyncify_wrapper_${original.name}`, wrapper);
    return wrapper;
  },
  instrumentWasmExports(exports) {
    var ret = {};
    for (let [x, original] of Object.entries(exports)) {
      if (typeof original == "function") {
        var wrapper = Asyncify.instrumentFunction(original);
        ret[x] = wrapper;
      } else {
        ret[x] = original;
      }
    }
    return ret;
  },
  State: {
    Normal: 0,
    Unwinding: 1,
    Rewinding: 2,
    Disabled: 3
  },
  state: 0,
  StackSize: 65536,
  currData: null,
  handleSleepReturnValue: 0,
  exportCallStack: [],
  callstackFuncToId: new Map,
  callStackIdToFunc: new Map,
  funcWrappers: new Map,
  callStackId: 0,
  asyncPromiseHandlers: null,
  sleepCallbacks: [],
  getCallStackId(func) {
    assert(func);
    if (!Asyncify.callstackFuncToId.has(func)) {
      var id = Asyncify.callStackId++;
      Asyncify.callstackFuncToId.set(func, id);
      Asyncify.callStackIdToFunc.set(id, func);
    }
    return Asyncify.callstackFuncToId.get(func);
  },
  maybeStopUnwind() {
    if (Asyncify.currData && Asyncify.state === Asyncify.State.Unwinding && Asyncify.exportCallStack.length === 0) {
      // We just finished unwinding.
      // Be sure to set the state before calling any other functions to avoid
      // possible infinite recursion here (For example in debug pthread builds
      // the dbg() function itself can call back into WebAssembly to get the
      // current pthread_self() pointer).
      Asyncify.state = Asyncify.State.Normal;
      runtimeKeepalivePush();
      // Keep the runtime alive so that a re-wind can be done later.
      runAndAbortIfError(_asyncify_stop_unwind);
      if (typeof Fibers != "undefined") {
        Fibers.trampoline();
      }
    }
  },
  whenDone() {
    assert(Asyncify.currData, "Tried to wait for an async operation when none is in progress.");
    assert(!Asyncify.asyncPromiseHandlers, "Cannot have multiple async operations in flight at once");
    return new Promise((resolve, reject) => {
      Asyncify.asyncPromiseHandlers = {
        resolve,
        reject
      };
    });
  },
  allocateData() {
    // An asyncify data structure has three fields:
    //  0  current stack pos
    //  4  max stack pos
    //  8  id of function at bottom of the call stack (callStackIdToFunc[id] == wasm func)
    // The Asyncify ABI only interprets the first two fields, the rest is for the runtime.
    // We also embed a stack in the same memory region here, right next to the structure.
    // This struct is also defined as asyncify_data_t in emscripten/fiber.h
    var ptr = _malloc(12 + Asyncify.StackSize);
    Asyncify.setDataHeader(ptr, ptr + 12, Asyncify.StackSize);
    Asyncify.setDataRewindFunc(ptr);
    return ptr;
  },
  setDataHeader(ptr, stack, stackSize) {
    (growMemViews(), HEAPU32)[((ptr) >> 2)] = stack;
    (growMemViews(), HEAPU32)[(((ptr) + (4)) >> 2)] = stack + stackSize;
  },
  setDataRewindFunc(ptr) {
    var bottomOfCallStack = Asyncify.exportCallStack[0];
    assert(bottomOfCallStack, "exportCallStack is empty");
    var rewindId = Asyncify.getCallStackId(bottomOfCallStack);
    (growMemViews(), HEAP32)[(((ptr) + (8)) >> 2)] = rewindId;
  },
  getDataRewindFunc(ptr) {
    var id = (growMemViews(), HEAP32)[(((ptr) + (8)) >> 2)];
    var func = Asyncify.callStackIdToFunc.get(id);
    assert(func, `id ${id} not found in callStackIdToFunc`);
    return func;
  },
  doRewind(ptr) {
    var original = Asyncify.getDataRewindFunc(ptr);
    var func = Asyncify.funcWrappers.get(original);
    assert(original);
    assert(func);
    // Once we have rewound and the stack we no longer need to artificially
    // keep the runtime alive.
    runtimeKeepalivePop();
    return func();
  },
  handleSleep(startAsync) {
    assert(Asyncify.state !== Asyncify.State.Disabled, "Asyncify cannot be done during or after the runtime exits");
    if (ABORT) return;
    if (Asyncify.state === Asyncify.State.Normal) {
      // Prepare to sleep. Call startAsync, and see what happens:
      // if the code decided to call our callback synchronously,
      // then no async operation was in fact begun, and we don't
      // need to do anything.
      var reachedCallback = false;
      var reachedAfterCallback = false;
      startAsync((handleSleepReturnValue = 0) => {
        assert(!handleSleepReturnValue || typeof handleSleepReturnValue == "number" || typeof handleSleepReturnValue == "boolean");
        // old emterpretify API supported other stuff
        if (ABORT) return;
        Asyncify.handleSleepReturnValue = handleSleepReturnValue;
        reachedCallback = true;
        if (!reachedAfterCallback) {
          // We are happening synchronously, so no need for async.
          return;
        }
        // This async operation did not happen synchronously, so we did
        // unwind. In that case there can be no compiled code on the stack,
        // as it might break later operations (we can rewind ok now, but if
        // we unwind again, we would unwind through the extra compiled code
        // too).
        assert(!Asyncify.exportCallStack.length, "Waking up (starting to rewind) must be done from JS, without compiled code on the stack.");
        Asyncify.state = Asyncify.State.Rewinding;
        runAndAbortIfError(() => _asyncify_start_rewind(Asyncify.currData));
        if (typeof MainLoop != "undefined" && MainLoop.func) {
          MainLoop.resume();
        }
        var asyncWasmReturnValue, isError = false;
        try {
          asyncWasmReturnValue = Asyncify.doRewind(Asyncify.currData);
        } catch (err) {
          asyncWasmReturnValue = err;
          isError = true;
        }
        // Track whether the return value was handled by any promise handlers.
        var handled = false;
        if (!Asyncify.currData) {
          // All asynchronous execution has finished.
          // `asyncWasmReturnValue` now contains the final
          // return value of the exported async WASM function.
          // Note: `asyncWasmReturnValue` is distinct from
          // `Asyncify.handleSleepReturnValue`.
          // `Asyncify.handleSleepReturnValue` contains the return
          // value of the last C function to have executed
          // `Asyncify.handleSleep()`, where as `asyncWasmReturnValue`
          // contains the return value of the exported WASM function
          // that may have called C functions that
          // call `Asyncify.handleSleep()`.
          var asyncPromiseHandlers = Asyncify.asyncPromiseHandlers;
          if (asyncPromiseHandlers) {
            Asyncify.asyncPromiseHandlers = null;
            (isError ? asyncPromiseHandlers.reject : asyncPromiseHandlers.resolve)(asyncWasmReturnValue);
            handled = true;
          }
        }
        if (isError && !handled) {
          // If there was an error and it was not handled by now, we have no choice but to
          // rethrow that error into the global scope where it can be caught only by
          // `onerror` or `onunhandledpromiserejection`.
          throw asyncWasmReturnValue;
        }
      });
      reachedAfterCallback = true;
      if (!reachedCallback) {
        // A true async operation was begun; start a sleep.
        Asyncify.state = Asyncify.State.Unwinding;
        // TODO: reuse, don't alloc/free every sleep
        Asyncify.currData = Asyncify.allocateData();
        if (typeof MainLoop != "undefined" && MainLoop.func) {
          MainLoop.pause();
        }
        runAndAbortIfError(() => _asyncify_start_unwind(Asyncify.currData));
      }
    } else if (Asyncify.state === Asyncify.State.Rewinding) {
      // Stop a resume.
      Asyncify.state = Asyncify.State.Normal;
      runAndAbortIfError(_asyncify_stop_rewind);
      _free(Asyncify.currData);
      Asyncify.currData = null;
      // Call all sleep callbacks now that the sleep-resume is all done.
      Asyncify.sleepCallbacks.forEach(callUserCallback);
    } else {
      abort(`invalid state: ${Asyncify.state}`);
    }
    return Asyncify.handleSleepReturnValue;
  },
  handleAsync: startAsync => Asyncify.handleSleep(wakeUp => {
    // TODO: add error handling as a second param when handleSleep implements it.
    startAsync().then(wakeUp);
  })
};

var getCFunc = ident => {
  var func = Module["_" + ident];
  // closure exported function
  assert(func, "Cannot call unknown function " + ident + ", make sure it is exported");
  return func;
};

var writeArrayToMemory = (array, buffer) => {
  assert(array.length >= 0, "writeArrayToMemory array must have a length (should be an array or typed array)");
  (growMemViews(), HEAP8).set(array, buffer);
};

var lengthBytesUTF8 = str => {
  var len = 0;
  for (var i = 0; i < str.length; ++i) {
    // Gotcha: charCodeAt returns a 16-bit word that is a UTF-16 encoded code
    // unit, not a Unicode code point of the character! So decode
    // UTF16->UTF32->UTF8.
    // See http://unicode.org/faq/utf_bom.html#utf16-3
    var c = str.charCodeAt(i);
    // possibly a lead surrogate
    if (c <= 127) {
      len++;
    } else if (c <= 2047) {
      len += 2;
    } else if (c >= 55296 && c <= 57343) {
      len += 4;
      ++i;
    } else {
      len += 3;
    }
  }
  return len;
};

var stringToUTF8Array = (str, heap, outIdx, maxBytesToWrite) => {
  assert(typeof str === "string", `stringToUTF8Array expects a string (got ${typeof str})`);
  // Parameter maxBytesToWrite is not optional. Negative values, 0, null,
  // undefined and false each don't write out any bytes.
  if (!(maxBytesToWrite > 0)) return 0;
  var startIdx = outIdx;
  var endIdx = outIdx + maxBytesToWrite - 1;
  // -1 for string null terminator.
  for (var i = 0; i < str.length; ++i) {
    // For UTF8 byte structure, see http://en.wikipedia.org/wiki/UTF-8#Description
    // and https://www.ietf.org/rfc/rfc2279.txt
    // and https://tools.ietf.org/html/rfc3629
    var u = str.codePointAt(i);
    if (u <= 127) {
      if (outIdx >= endIdx) break;
      heap[outIdx++] = u;
    } else if (u <= 2047) {
      if (outIdx + 1 >= endIdx) break;
      heap[outIdx++] = 192 | (u >> 6);
      heap[outIdx++] = 128 | (u & 63);
    } else if (u <= 65535) {
      if (outIdx + 2 >= endIdx) break;
      heap[outIdx++] = 224 | (u >> 12);
      heap[outIdx++] = 128 | ((u >> 6) & 63);
      heap[outIdx++] = 128 | (u & 63);
    } else {
      if (outIdx + 3 >= endIdx) break;
      if (u > 1114111) warnOnce("Invalid Unicode code point " + ptrToString(u) + " encountered when serializing a JS string to a UTF-8 string in wasm memory! (Valid unicode code points should be in range 0-0x10FFFF).");
      heap[outIdx++] = 240 | (u >> 18);
      heap[outIdx++] = 128 | ((u >> 12) & 63);
      heap[outIdx++] = 128 | ((u >> 6) & 63);
      heap[outIdx++] = 128 | (u & 63);
      // Gotcha: if codePoint is over 0xFFFF, it is represented as a surrogate pair in UTF-16.
      // We need to manually skip over the second code unit for correct iteration.
      i++;
    }
  }
  // Null-terminate the pointer to the buffer.
  heap[outIdx] = 0;
  return outIdx - startIdx;
};

var stringToUTF8 = (str, outPtr, maxBytesToWrite) => {
  assert(typeof maxBytesToWrite == "number", "stringToUTF8(str, outPtr, maxBytesToWrite) is missing the third parameter that specifies the length of the output buffer!");
  return stringToUTF8Array(str, (growMemViews(), HEAPU8), outPtr, maxBytesToWrite);
};

var stringToUTF8OnStack = str => {
  var size = lengthBytesUTF8(str) + 1;
  var ret = stackAlloc(size);
  stringToUTF8(str, ret, size);
  return ret;
};

/**
     * @param {string|null=} returnType
     * @param {Array=} argTypes
     * @param {Array=} args
     * @param {Object=} opts
     */ var ccall = (ident, returnType, argTypes, args, opts) => {
  // For fast lookup of conversion functions
  var toC = {
    "string": str => {
      var ret = 0;
      if (str !== null && str !== undefined && str !== 0) {
        // null string
        ret = stringToUTF8OnStack(str);
      }
      return ret;
    },
    "array": arr => {
      var ret = stackAlloc(arr.length);
      writeArrayToMemory(arr, ret);
      return ret;
    }
  };
  function convertReturnValue(ret) {
    if (returnType === "string") {
      return UTF8ToString(ret);
    }
    if (returnType === "boolean") return Boolean(ret);
    return ret;
  }
  var func = getCFunc(ident);
  var cArgs = [];
  var stack = 0;
  assert(returnType !== "array", 'Return type should not be "array".');
  if (args) {
    for (var i = 0; i < args.length; i++) {
      var converter = toC[argTypes[i]];
      if (converter) {
        if (stack === 0) stack = stackSave();
        cArgs[i] = converter(args[i]);
      } else {
        cArgs[i] = args[i];
      }
    }
  }
  // Data for a previous async operation that was in flight before us.
  var previousAsync = Asyncify.currData;
  var ret = func(...cArgs);
  function onDone(ret) {
    runtimeKeepalivePop();
    if (stack !== 0) stackRestore(stack);
    return convertReturnValue(ret);
  }
  var asyncMode = opts?.async;
  // Keep the runtime alive through all calls. Note that this call might not be
  // async, but for simplicity we push and pop in all calls.
  runtimeKeepalivePush();
  if (Asyncify.currData != previousAsync) {
    // A change in async operation happened. If there was already an async
    // operation in flight before us, that is an error: we should not start
    // another async operation while one is active, and we should not stop one
    // either. The only valid combination is to have no change in the async
    // data (so we either had one in flight and left it alone, or we didn't have
    // one), or to have nothing in flight and to start one.
    assert(!(previousAsync && Asyncify.currData), "We cannot start an async operation when one is already flight");
    assert(!(previousAsync && !Asyncify.currData), "We cannot stop an async operation in flight");
    // This is a new async operation. The wasm is paused and has unwound its stack.
    // We need to return a Promise that resolves the return value
    // once the stack is rewound and execution finishes.
    assert(asyncMode, "The call to " + ident + " is running asynchronously. If this was intended, add the async option to the ccall/cwrap call.");
    return Asyncify.whenDone().then(onDone);
  }
  ret = onDone(ret);
  // If this is an async ccall, ensure we return a promise
  if (asyncMode) return Promise.resolve(ret);
  return ret;
};

/**
     * @param {string=} returnType
     * @param {Array=} argTypes
     * @param {Object=} opts
     */ var cwrap = (ident, returnType, argTypes, opts) => (...args) => ccall(ident, returnType, argTypes, args, opts);

PThread.init();

// End JS library code
// include: postlibrary.js
// This file is included after the automatically-generated JS library code
// but before the wasm module is created.
{
  // With WASM_ESM_INTEGRATION this has to happen at the top level and not
  // delayed until processModuleArgs.
  initMemory();
  // Begin ATMODULES hooks
  if (Module["noExitRuntime"]) noExitRuntime = Module["noExitRuntime"];
  if (Module["print"]) out = Module["print"];
  if (Module["printErr"]) err = Module["printErr"];
  if (Module["wasmBinary"]) wasmBinary = Module["wasmBinary"];
  Module["FS_createDataFile"] = FS.createDataFile;
  Module["FS_createPreloadedFile"] = FS.createPreloadedFile;
  // End ATMODULES hooks
  checkIncomingModuleAPI();
  if (Module["arguments"]) arguments_ = Module["arguments"];
  if (Module["thisProgram"]) thisProgram = Module["thisProgram"];
  // Assertions on removed incoming Module JS APIs.
  assert(typeof Module["memoryInitializerPrefixURL"] == "undefined", "Module.memoryInitializerPrefixURL option was removed, use Module.locateFile instead");
  assert(typeof Module["pthreadMainPrefixURL"] == "undefined", "Module.pthreadMainPrefixURL option was removed, use Module.locateFile instead");
  assert(typeof Module["cdInitializerPrefixURL"] == "undefined", "Module.cdInitializerPrefixURL option was removed, use Module.locateFile instead");
  assert(typeof Module["filePackagePrefixURL"] == "undefined", "Module.filePackagePrefixURL option was removed, use Module.locateFile instead");
  assert(typeof Module["read"] == "undefined", "Module.read option was removed");
  assert(typeof Module["readAsync"] == "undefined", "Module.readAsync option was removed (modify readAsync in JS)");
  assert(typeof Module["readBinary"] == "undefined", "Module.readBinary option was removed (modify readBinary in JS)");
  assert(typeof Module["setWindowTitle"] == "undefined", "Module.setWindowTitle option was removed (modify emscripten_set_window_title in JS)");
  assert(typeof Module["TOTAL_MEMORY"] == "undefined", "Module.TOTAL_MEMORY has been renamed Module.INITIAL_MEMORY");
  assert(typeof Module["ENVIRONMENT"] == "undefined", "Module.ENVIRONMENT has been deprecated. To force the environment, use the ENVIRONMENT compile-time option (for example, -sENVIRONMENT=web or -sENVIRONMENT=node)");
  assert(typeof Module["STACK_SIZE"] == "undefined", "STACK_SIZE can no longer be set at runtime.  Use -sSTACK_SIZE at link time");
  if (Module["preInit"]) {
    if (typeof Module["preInit"] == "function") Module["preInit"] = [ Module["preInit"] ];
    while (Module["preInit"].length > 0) {
      Module["preInit"].shift()();
    }
  }
  consumedModuleProp("preInit");
}

// Begin runtime exports
Module["ccall"] = ccall;

Module["cwrap"] = cwrap;

Module["setValue"] = setValue;

Module["getValue"] = getValue;

Module["UTF8ToString"] = UTF8ToString;

// End runtime exports
// Begin JS library exports
Module["ExitStatus"] = ExitStatus;

Module["PThread"] = PThread;

Module["terminateWorker"] = terminateWorker;

Module["cleanupThread"] = cleanupThread;

Module["addOnPreRun"] = addOnPreRun;

Module["onPreRuns"] = onPreRuns;

Module["callRuntimeCallbacks"] = callRuntimeCallbacks;

Module["addRunDependency"] = addRunDependency;

Module["runDependencies"] = runDependencies;

Module["removeRunDependency"] = removeRunDependency;

Module["dependenciesFulfilled"] = dependenciesFulfilled;

Module["runDependencyTracking"] = runDependencyTracking;

Module["runDependencyWatcher"] = runDependencyWatcher;

Module["spawnThread"] = spawnThread;

Module["_exit"] = _exit;

Module["exitJS"] = exitJS;

Module["_proc_exit"] = _proc_exit;

Module["keepRuntimeAlive"] = keepRuntimeAlive;

Module["runtimeKeepaliveCounter"] = runtimeKeepaliveCounter;

Module["proxyToMainThread"] = proxyToMainThread;

Module["stackSave"] = stackSave;

Module["stackRestore"] = stackRestore;

Module["stackAlloc"] = stackAlloc;

Module["exitOnMainThread"] = exitOnMainThread;

Module["ptrToString"] = ptrToString;

Module["_wasmWorkerInitializeRuntime"] = _wasmWorkerInitializeRuntime;

Module["_wasmWorkerDelayedMessageQueue"] = _wasmWorkerDelayedMessageQueue;

Module["_wasmWorkerRunPostMessage"] = _wasmWorkerRunPostMessage;

Module["callUserCallback"] = callUserCallback;

Module["handleException"] = handleException;

Module["maybeExit"] = maybeExit;

Module["getWasmTableEntry"] = getWasmTableEntry;

Module["wasmTableMirror"] = wasmTableMirror;

Module["_wasmWorkerAppendToQueue"] = _wasmWorkerAppendToQueue;

Module["addOnPostRun"] = addOnPostRun;

Module["onPostRuns"] = onPostRuns;

Module["dynCall"] = dynCall;

Module["dynCallLegacy"] = dynCallLegacy;

Module["dynCalls"] = dynCalls;

Module["establishStackSpace"] = establishStackSpace;

Module["getValue"] = getValue;

Module["invokeEntryPoint"] = invokeEntryPoint;

Module["noExitRuntime"] = noExitRuntime;

Module["registerTLSInit"] = registerTLSInit;

Module["setValue"] = setValue;

Module["warnOnce"] = warnOnce;

Module["wasmMemory"] = wasmMemory;

Module["___assert_fail"] = ___assert_fail;

Module["UTF8ToString"] = UTF8ToString;

Module["UTF8ArrayToString"] = UTF8ArrayToString;

Module["UTF8Decoder"] = UTF8Decoder;

Module["findStringEnd"] = findStringEnd;

Module["___cxa_throw"] = ___cxa_throw;

Module["ExceptionInfo"] = ExceptionInfo;

Module["exceptionLast"] = exceptionLast;

Module["uncaughtExceptionCount"] = uncaughtExceptionCount;

Module["___pthread_create_js"] = ___pthread_create_js;

Module["pthreadCreateProxied"] = pthreadCreateProxied;

Module["_emscripten_has_threading_support"] = _emscripten_has_threading_support;

Module["__abort_js"] = __abort_js;

Module["__emscripten_init_main_thread_js"] = __emscripten_init_main_thread_js;

Module["__emscripten_notify_mailbox_postmessage"] = __emscripten_notify_mailbox_postmessage;

Module["checkMailbox"] = checkMailbox;

Module["__emscripten_thread_mailbox_await"] = __emscripten_thread_mailbox_await;

Module["waitAsyncPolyfilled"] = waitAsyncPolyfilled;

Module["__emscripten_receive_on_main_thread_js"] = __emscripten_receive_on_main_thread_js;

Module["proxiedJSCallArgs"] = proxiedJSCallArgs;

Module["__emscripten_thread_cleanup"] = __emscripten_thread_cleanup;

Module["__emscripten_thread_set_strongref"] = __emscripten_thread_set_strongref;

Module["_clock_time_get"] = _clock_time_get;

Module["_emscripten_get_now"] = _emscripten_get_now;

Module["_emscripten_date_now"] = _emscripten_date_now;

Module["nowIsMonotonic"] = nowIsMonotonic;

Module["checkWasiClock"] = checkWasiClock;

Module["bigintToI53Checked"] = bigintToI53Checked;

Module["INT53_MAX"] = INT53_MAX;

Module["INT53_MIN"] = INT53_MIN;

Module["_emscripten_asm_const_int"] = _emscripten_asm_const_int;

Module["runEmAsmFunction"] = runEmAsmFunction;

Module["readEmAsmArgs"] = readEmAsmArgs;

Module["readEmAsmArgsArray"] = readEmAsmArgsArray;

Module["_emscripten_audio_context_quantum_size"] = _emscripten_audio_context_quantum_size;

Module["emscriptenGetContextQuantumSize"] = emscriptenGetContextQuantumSize;

Module["_emAudioExpectHandle"] = _emAudioExpectHandle;

Module["emAudioExpectNode"] = emAudioExpectNode;

Module["emAudioExpectContext"] = emAudioExpectContext;

Module["emAudioExpectNodeOrContext"] = emAudioExpectNodeOrContext;

Module["_emscripten_audio_worklet_post_function_sig"] = _emscripten_audio_worklet_post_function_sig;

Module["emAudioWorkletPostFunction"] = emAudioWorkletPostFunction;

Module["_emscripten_audio_worklet_post_function_viii"] = _emscripten_audio_worklet_post_function_viii;

Module["emscripten_audio_worklet_post_function_3"] = emscripten_audio_worklet_post_function_3;

Module["_emscripten_check_blocking_allowed"] = _emscripten_check_blocking_allowed;

Module["_emscripten_create_audio_context"] = _emscripten_create_audio_context;

Module["emscriptenRegisterAudioObject"] = emscriptenRegisterAudioObject;

Module["emAudio"] = emAudio;

Module["emAudioCounter"] = emAudioCounter;

Module["emscriptenGetAudioObject"] = emscriptenGetAudioObject;

Module["_emscripten_create_wasm_audio_worklet_node"] = _emscripten_create_wasm_audio_worklet_node;

Module["_emscripten_create_wasm_audio_worklet_processor_async"] = _emscripten_create_wasm_audio_worklet_processor_async;

Module["_emscripten_destroy_audio_context"] = _emscripten_destroy_audio_context;

Module["_emscripten_destroy_web_audio_node"] = _emscripten_destroy_web_audio_node;

Module["_emscripten_exit_with_live_runtime"] = _emscripten_exit_with_live_runtime;

Module["runtimeKeepalivePush"] = runtimeKeepalivePush;

Module["_emscripten_resize_heap"] = _emscripten_resize_heap;

Module["getHeapMax"] = getHeapMax;

Module["alignMemory"] = alignMemory;

Module["growMemory"] = growMemory;

Module["_emscripten_sleep"] = _emscripten_sleep;

Module["safeSetTimeout"] = safeSetTimeout;

Module["runtimeKeepalivePop"] = runtimeKeepalivePop;

Module["_emscripten_start_wasm_audio_worklet_thread_async"] = _emscripten_start_wasm_audio_worklet_thread_async;

Module["_wasmWorkersID"] = _wasmWorkersID;

Module["_emAudioDispatchProcessorCallback"] = _emAudioDispatchProcessorCallback;

Module["_fd_close"] = _fd_close;

Module["SYSCALLS"] = SYSCALLS;

Module["_fd_seek"] = _fd_seek;

Module["_fd_write"] = _fd_write;

Module["flush_NO_FILESYSTEM"] = flush_NO_FILESYSTEM;

Module["printChar"] = printChar;

Module["printCharBuffers"] = printCharBuffers;

Module["Asyncify"] = Asyncify;

Module["runAndAbortIfError"] = runAndAbortIfError;

Module["createNamedFunction"] = createNamedFunction;

Module["ccall"] = ccall;

Module["getCFunc"] = getCFunc;

Module["writeArrayToMemory"] = writeArrayToMemory;

Module["stringToUTF8OnStack"] = stringToUTF8OnStack;

Module["lengthBytesUTF8"] = lengthBytesUTF8;

Module["stringToUTF8"] = stringToUTF8;

Module["stringToUTF8Array"] = stringToUTF8Array;

Module["cwrap"] = cwrap;

// End JS library exports
// end include: postlibrary.js
// proxiedFunctionTable specifies the list of functions that can be called
// either synchronously or asynchronously from other threads in postMessage()d
// or internally queued events. This way a pthread in a Worker can synchronously
// access e.g. the DOM on the main thread.
var proxiedFunctionTable = [ _proc_exit, exitOnMainThread, pthreadCreateProxied, _fd_close, _fd_seek, _fd_write ];

function checkIncomingModuleAPI() {
  ignoredModuleProp("fetchSettings");
}

var ASM_CONSTS = {
  88356: ($0, $1, $2, $3, $4) => {
    if (typeof _wasmRecorderVisualizationCallback === "function") {
      _wasmRecorderVisualizationCallback($0, $1, $2, $3, $4);
    }
  },
  88482: ($0, $1, $2) => {
    const data = new Uint8Array((growMemViews(), HEAPU8).subarray($0, $0 + $1));
    const blob = new Blob([ data ], {
      type: "audio/wav"
    });
    const name = UTF8ToString($2) || "output.wav";
    if (window.showSaveFilePicker) {
      window.showSaveFilePicker({
        suggestedName: name,
        types: [ {
          description: "Audio WAV file",
          accept: {
            "audio/wav": [ ".wav" ]
          }
        } ]
      }).then(handle => handle.createWritable()).then(writable => writable.write(blob)).then(() => writable.close()).catch(err => console.error("Error saving WAV file:", err));
    } else {
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = name;
      link.click();
      URL.revokeObjectURL(url);
    }
  },
  89152: () => {
    if (!RecorderModule.wasmWorker) {
      var workerUri = "assets/packages/flutter_recorder/web/worker.dart.js";
      RecorderModule.wasmWorker = new Worker(workerUri);
      console.log("EM_ASM creating web worker! " + workerUri + "  " + RecorderModule.wasmWorker);
    } else {
      console.log("EM_ASM web worker already created!");
    }
  },
  89466: ($0, $1, $2) => {
    if (RecorderModule.wasmWorker) {
      RecorderModule.wasmWorker.postMessage({
        message: UTF8ToString($0),
        isSilent: $1,
        energyDb: $2
      });
    } else {
      console.error("Worker not found.");
    }
  },
  89652: ($0, $1, $2) => {
    if (RecorderModule.wasmWorker) {
      const audioDataArray = new Uint8Array(RecorderModule.HEAPU8.subarray($1, $1 + $2));
      RecorderModule.wasmWorker.postMessage({
        message: UTF8ToString($0),
        data: audioDataArray
      });
    } else {
      console.error("Worker not found.");
    }
  },
  89915: ($0, $1, $2, $3, $4) => {
    if (typeof window === "undefined" || (window.AudioContext || window.webkitAudioContext) === undefined) {
      return 0;
    }
    if (typeof (window.miniaudio) === "undefined") {
      window.miniaudio = {
        referenceCount: 0
      };
      window.miniaudio.device_type = {};
      window.miniaudio.device_type.playback = $0;
      window.miniaudio.device_type.capture = $1;
      window.miniaudio.device_type.duplex = $2;
      window.miniaudio.device_state = {};
      window.miniaudio.device_state.stopped = $3;
      window.miniaudio.device_state.started = $4;
      let miniaudio = window.miniaudio;
      miniaudio.devices = [];
      miniaudio.track_device = function(device) {
        for (var iDevice = 0; iDevice < miniaudio.devices.length; ++iDevice) {
          if (miniaudio.devices[iDevice] == null) {
            miniaudio.devices[iDevice] = device;
            return iDevice;
          }
        }
        miniaudio.devices.push(device);
        return miniaudio.devices.length - 1;
      };
      miniaudio.untrack_device_by_index = function(deviceIndex) {
        miniaudio.devices[deviceIndex] = null;
        while (miniaudio.devices.length > 0) {
          if (miniaudio.devices[miniaudio.devices.length - 1] == null) {
            miniaudio.devices.pop();
          } else {
            break;
          }
        }
      };
      miniaudio.untrack_device = function(device) {
        for (var iDevice = 0; iDevice < miniaudio.devices.length; ++iDevice) {
          if (miniaudio.devices[iDevice] == device) {
            return miniaudio.untrack_device_by_index(iDevice);
          }
        }
      };
      miniaudio.get_device_by_index = function(deviceIndex) {
        return miniaudio.devices[deviceIndex];
      };
      miniaudio.unlock_event_types = (function() {
        return [ "touchend", "click" ];
      })();
      miniaudio.unlock = function() {
        for (var i = 0; i < miniaudio.devices.length; ++i) {
          var device = miniaudio.devices[i];
          if (device != null && device.webaudio != null && device.state === miniaudio.device_state.started) {
            device.webaudio.resume().then(() => {
              _ma_device__on_notification_unlocked(device.pDevice);
            }, error => {
              console.error("Failed to resume audiocontext", error);
            });
          }
        }
        miniaudio.unlock_event_types.map(function(event_type) {
          document.removeEventListener(event_type, miniaudio.unlock, true);
        });
      };
      miniaudio.unlock_event_types.map(function(event_type) {
        document.addEventListener(event_type, miniaudio.unlock, true);
      });
    }
    window.miniaudio.referenceCount += 1;
    return 1;
  },
  92093: () => {
    if (typeof (window.miniaudio) !== "undefined") {
      window.miniaudio.unlock_event_types.map(function(event_type) {
        document.removeEventListener(event_type, window.miniaudio.unlock, true);
      });
      window.miniaudio.referenceCount -= 1;
      if (window.miniaudio.referenceCount === 0) {
        delete window.miniaudio;
      }
    }
  },
  92397: () => (navigator.mediaDevices !== undefined && navigator.mediaDevices.getUserMedia !== undefined),
  92501: () => {
    try {
      var temp = new (window.AudioContext || window.webkitAudioContext);
      var sampleRate = temp.sampleRate;
      temp.close();
      return sampleRate;
    } catch (e) {
      return 0;
    }
  },
  92672: ($0, $1) => window.miniaudio.track_device({
    webaudio: emscriptenGetAudioObject($0),
    state: 1,
    pDevice: $1
  }),
  92781: ($0, $1) => {
    var getUserMediaResult = 0;
    var audioWorklet = emscriptenGetAudioObject($0);
    var audioContext = emscriptenGetAudioObject($1);
    navigator.mediaDevices.getUserMedia({
      audio: true,
      video: false
    }).then(function(stream) {
      audioContext.streamNode = audioContext.createMediaStreamSource(stream);
      audioContext.streamNode.connect(audioWorklet);
      audioWorklet.connect(audioContext.destination);
      getUserMediaResult = 0;
    }).catch(function(error) {
      console.log("navigator.mediaDevices.getUserMedia Failed: " + error);
      getUserMediaResult = -1;
    });
    return getUserMediaResult;
  },
  93343: ($0, $1) => {
    var audioWorklet = emscriptenGetAudioObject($0);
    var audioContext = emscriptenGetAudioObject($1);
    audioWorklet.connect(audioContext.destination);
    return 0;
  },
  93503: $0 => emscriptenGetAudioObject($0).sampleRate,
  93555: $0 => {
    var device = window.miniaudio.get_device_by_index($0);
    if (device.streamNode !== undefined) {
      device.streamNode.disconnect();
      device.streamNode = undefined;
    }
    device.pDevice = undefined;
  },
  93746: $0 => {
    window.miniaudio.untrack_device_by_index($0);
  },
  93796: $0 => {
    var device = window.miniaudio.get_device_by_index($0);
    device.webaudio.resume();
    device.state = window.miniaudio.device_state.started;
  },
  93935: $0 => {
    var device = window.miniaudio.get_device_by_index($0);
    device.webaudio.suspend();
    device.state = window.miniaudio.device_state.stopped;
  },
  94075: ($0, $1, $2) => {
    const data = new Uint8Array((growMemViews(), HEAPU8).subarray($0, $0 + $1));
    const blob = new Blob([ data ], {
      type: "audio/ogg"
    });
    if (window.showSaveFilePicker) {
      window.showSaveFilePicker({
        suggestedName: UTF8ToString($2) || "output.opus",
        types: [ {
          description: "Ogg Opus file",
          accept: {
            "audio/ogg": [ ".opus", ".ogg" ]
          }
        } ]
      }).then(handle => handle.createWritable()).then(writable => writable.write(blob)).then(() => writable.close()).catch(err => console.error("Error saving Opus file:", err));
    } else {
      const url = URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;
      link.download = UTF8ToString($2) || "output.opus";
      link.click();
      URL.revokeObjectURL(url);
    }
  }
};

// Imports from the Wasm binary.
var _flutter_recorder_createWorkerInWasm = Module["_flutter_recorder_createWorkerInWasm"] = makeInvalidEarlyAccess("_flutter_recorder_createWorkerInWasm");

var __Z41flutter_recorder_sendSilenceEventToWorkerPKcbf = Module["__Z41flutter_recorder_sendSilenceEventToWorkerPKcbf"] = makeInvalidEarlyAccess("__Z41flutter_recorder_sendSilenceEventToWorkerPKcbf");

var __Z35flutter_recorder_sendStreamToWorkerPKcPKhi = Module["__Z35flutter_recorder_sendStreamToWorkerPKcPKhi"] = makeInvalidEarlyAccess("__Z35flutter_recorder_sendStreamToWorkerPKcPKhi");

var _flutter_recorder_setDartEventCallbackForEngine = Module["_flutter_recorder_setDartEventCallbackForEngine"] = makeInvalidEarlyAccess("_flutter_recorder_setDartEventCallbackForEngine");

var _flutter_recorder_setDartEventCallback = Module["_flutter_recorder_setDartEventCallback"] = makeInvalidEarlyAccess("_flutter_recorder_setDartEventCallback");

var _flutter_recorder_setDartVisualizationCallbackForEngine = Module["_flutter_recorder_setDartVisualizationCallbackForEngine"] = makeInvalidEarlyAccess("_flutter_recorder_setDartVisualizationCallbackForEngine");

var _flutter_recorder_setDartVisualizationCallback = Module["_flutter_recorder_setDartVisualizationCallback"] = makeInvalidEarlyAccess("_flutter_recorder_setDartVisualizationCallback");

var _flutter_recorder_prepareEngineInit = Module["_flutter_recorder_prepareEngineInit"] = makeInvalidEarlyAccess("_flutter_recorder_prepareEngineInit");

var _flutter_recorder_currentEngineShutdownEpoch = Module["_flutter_recorder_currentEngineShutdownEpoch"] = makeInvalidEarlyAccess("_flutter_recorder_currentEngineShutdownEpoch");

var _flutter_recorder_prepareEngineInitForRequest = Module["_flutter_recorder_prepareEngineInitForRequest"] = makeInvalidEarlyAccess("_flutter_recorder_prepareEngineInitForRequest");

var _flutter_recorder_clearDartCallbackRegistrationsForEngine = Module["_flutter_recorder_clearDartCallbackRegistrationsForEngine"] = makeInvalidEarlyAccess("_flutter_recorder_clearDartCallbackRegistrationsForEngine");

var _flutter_recorder_clearDartCallbackRegistrations = Module["_flutter_recorder_clearDartCallbackRegistrations"] = makeInvalidEarlyAccess("_flutter_recorder_clearDartCallbackRegistrations");

var _flutter_recorder_requestEngineTeardownForEngine = Module["_flutter_recorder_requestEngineTeardownForEngine"] = makeInvalidEarlyAccess("_flutter_recorder_requestEngineTeardownForEngine");

var _flutter_recorder_retireDartCallbacksFinalizer = Module["_flutter_recorder_retireDartCallbacksFinalizer"] = makeInvalidEarlyAccess("_flutter_recorder_retireDartCallbacksFinalizer");

var _flutter_recorder_nativeFree = Module["_flutter_recorder_nativeFree"] = makeInvalidEarlyAccess("_flutter_recorder_nativeFree");

var _free = Module["_free"] = makeInvalidEarlyAccess("_free");

var _flutter_recorder_listCaptureDevices = Module["_flutter_recorder_listCaptureDevices"] = makeInvalidEarlyAccess("_flutter_recorder_listCaptureDevices");

var _malloc = Module["_malloc"] = makeInvalidEarlyAccess("_malloc");

var _flutter_recorder_freeListCaptureDevices = Module["_flutter_recorder_freeListCaptureDevices"] = makeInvalidEarlyAccess("_flutter_recorder_freeListCaptureDevices");

var _flutter_recorder_init = Module["_flutter_recorder_init"] = makeInvalidEarlyAccess("_flutter_recorder_init");

var _flutter_recorder_deinit = Module["_flutter_recorder_deinit"] = makeInvalidEarlyAccess("_flutter_recorder_deinit");

var _flutter_recorder_isInited = Module["_flutter_recorder_isInited"] = makeInvalidEarlyAccess("_flutter_recorder_isInited");

var _flutter_recorder_isDeviceStarted = Module["_flutter_recorder_isDeviceStarted"] = makeInvalidEarlyAccess("_flutter_recorder_isDeviceStarted");

var _flutter_recorder_start = Module["_flutter_recorder_start"] = makeInvalidEarlyAccess("_flutter_recorder_start");

var _flutter_recorder_stop = Module["_flutter_recorder_stop"] = makeInvalidEarlyAccess("_flutter_recorder_stop");

var _flutter_recorder_startStreamingData = Module["_flutter_recorder_startStreamingData"] = makeInvalidEarlyAccess("_flutter_recorder_startStreamingData");

var _flutter_recorder_stopStreamingData = Module["_flutter_recorder_stopStreamingData"] = makeInvalidEarlyAccess("_flutter_recorder_stopStreamingData");

var _flutter_recorder_setSilenceDetection = Module["_flutter_recorder_setSilenceDetection"] = makeInvalidEarlyAccess("_flutter_recorder_setSilenceDetection");

var _flutter_recorder_setSilenceThresholdDb = Module["_flutter_recorder_setSilenceThresholdDb"] = makeInvalidEarlyAccess("_flutter_recorder_setSilenceThresholdDb");

var _flutter_recorder_setSilenceDuration = Module["_flutter_recorder_setSilenceDuration"] = makeInvalidEarlyAccess("_flutter_recorder_setSilenceDuration");

var _flutter_recorder_setSecondsOfAudioToWriteBefore = Module["_flutter_recorder_setSecondsOfAudioToWriteBefore"] = makeInvalidEarlyAccess("_flutter_recorder_setSecondsOfAudioToWriteBefore");

var _flutter_recorder_startRecording = Module["_flutter_recorder_startRecording"] = makeInvalidEarlyAccess("_flutter_recorder_startRecording");

var _flutter_recorder_setPauseRecording = Module["_flutter_recorder_setPauseRecording"] = makeInvalidEarlyAccess("_flutter_recorder_setPauseRecording");

var _flutter_recorder_stopRecording = Module["_flutter_recorder_stopRecording"] = makeInvalidEarlyAccess("_flutter_recorder_stopRecording");

var _flutter_recorder_getVolumeDb = Module["_flutter_recorder_getVolumeDb"] = makeInvalidEarlyAccess("_flutter_recorder_getVolumeDb");

var _flutter_recorder_setVisualizationEnabled = Module["_flutter_recorder_setVisualizationEnabled"] = makeInvalidEarlyAccess("_flutter_recorder_setVisualizationEnabled");

var _flutter_recorder_isVisualizationEnabled = Module["_flutter_recorder_isVisualizationEnabled"] = makeInvalidEarlyAccess("_flutter_recorder_isVisualizationEnabled");

var _flutter_recorder_setFftSmoothing = Module["_flutter_recorder_setFftSmoothing"] = makeInvalidEarlyAccess("_flutter_recorder_setFftSmoothing");

var _flutter_recorder_setLoopback = Module["_flutter_recorder_setLoopback"] = makeInvalidEarlyAccess("_flutter_recorder_setLoopback");

var _flutter_recorder_isLoopbackEnabled = Module["_flutter_recorder_isLoopbackEnabled"] = makeInvalidEarlyAccess("_flutter_recorder_isLoopbackEnabled");

var _flutter_recorder_isFilterActive = Module["_flutter_recorder_isFilterActive"] = makeInvalidEarlyAccess("_flutter_recorder_isFilterActive");

var _flutter_recorder_addFilter = Module["_flutter_recorder_addFilter"] = makeInvalidEarlyAccess("_flutter_recorder_addFilter");

var _flutter_recorder_removeFilter = Module["_flutter_recorder_removeFilter"] = makeInvalidEarlyAccess("_flutter_recorder_removeFilter");

var _flutter_recorder_getFilterParamNames = Module["_flutter_recorder_getFilterParamNames"] = makeInvalidEarlyAccess("_flutter_recorder_getFilterParamNames");

var _flutter_recorder_setFilterParams = Module["_flutter_recorder_setFilterParams"] = makeInvalidEarlyAccess("_flutter_recorder_setFilterParams");

var _flutter_recorder_getFilterParams = Module["_flutter_recorder_getFilterParams"] = makeInvalidEarlyAccess("_flutter_recorder_getFilterParams");

var _flutter_recorder_feedPlaybackData = Module["_flutter_recorder_feedPlaybackData"] = makeInvalidEarlyAccess("_flutter_recorder_feedPlaybackData");

var _ma_device__on_notification_unlocked = Module["_ma_device__on_notification_unlocked"] = makeInvalidEarlyAccess("_ma_device__on_notification_unlocked");

var _ma_malloc_emscripten = Module["_ma_malloc_emscripten"] = makeInvalidEarlyAccess("_ma_malloc_emscripten");

var _ma_free_emscripten = Module["_ma_free_emscripten"] = makeInvalidEarlyAccess("_ma_free_emscripten");

var _ma_device_process_pcm_frames_capture__webaudio = Module["_ma_device_process_pcm_frames_capture__webaudio"] = makeInvalidEarlyAccess("_ma_device_process_pcm_frames_capture__webaudio");

var _ma_device_process_pcm_frames_playback__webaudio = Module["_ma_device_process_pcm_frames_playback__webaudio"] = makeInvalidEarlyAccess("_ma_device_process_pcm_frames_playback__webaudio");

var __emscripten_tls_init = Module["__emscripten_tls_init"] = makeInvalidEarlyAccess("__emscripten_tls_init");

var _pthread_self = Module["_pthread_self"] = makeInvalidEarlyAccess("_pthread_self");

var _memcpy = Module["_memcpy"] = makeInvalidEarlyAccess("_memcpy");

var _memset = Module["_memset"] = makeInvalidEarlyAccess("_memset");

var __emscripten_thread_init = Module["__emscripten_thread_init"] = makeInvalidEarlyAccess("__emscripten_thread_init");

var ___set_thread_state = Module["___set_thread_state"] = makeInvalidEarlyAccess("___set_thread_state");

var __emscripten_thread_crashed = Module["__emscripten_thread_crashed"] = makeInvalidEarlyAccess("__emscripten_thread_crashed");

var _fflush = Module["_fflush"] = makeInvalidEarlyAccess("_fflush");

var _emscripten_stack_get_end = Module["_emscripten_stack_get_end"] = makeInvalidEarlyAccess("_emscripten_stack_get_end");

var _emscripten_stack_get_base = Module["_emscripten_stack_get_base"] = makeInvalidEarlyAccess("_emscripten_stack_get_base");

var _strerror = Module["_strerror"] = makeInvalidEarlyAccess("_strerror");

var __emscripten_run_js_on_main_thread = Module["__emscripten_run_js_on_main_thread"] = makeInvalidEarlyAccess("__emscripten_run_js_on_main_thread");

var __emscripten_thread_free_data = Module["__emscripten_thread_free_data"] = makeInvalidEarlyAccess("__emscripten_thread_free_data");

var __emscripten_thread_exit = Module["__emscripten_thread_exit"] = makeInvalidEarlyAccess("__emscripten_thread_exit");

var __emscripten_check_mailbox = Module["__emscripten_check_mailbox"] = makeInvalidEarlyAccess("__emscripten_check_mailbox");

var _emscripten_stack_init = Module["_emscripten_stack_init"] = makeInvalidEarlyAccess("_emscripten_stack_init");

var _emscripten_stack_set_limits = Module["_emscripten_stack_set_limits"] = makeInvalidEarlyAccess("_emscripten_stack_set_limits");

var _emscripten_stack_get_free = Module["_emscripten_stack_get_free"] = makeInvalidEarlyAccess("_emscripten_stack_get_free");

var __emscripten_stack_restore = Module["__emscripten_stack_restore"] = makeInvalidEarlyAccess("__emscripten_stack_restore");

var __emscripten_stack_alloc = Module["__emscripten_stack_alloc"] = makeInvalidEarlyAccess("__emscripten_stack_alloc");

var _emscripten_stack_get_current = Module["_emscripten_stack_get_current"] = makeInvalidEarlyAccess("_emscripten_stack_get_current");

var __emscripten_wasm_worker_initialize = Module["__emscripten_wasm_worker_initialize"] = makeInvalidEarlyAccess("__emscripten_wasm_worker_initialize");

var dynCall_vi = Module["dynCall_vi"] = makeInvalidEarlyAccess("dynCall_vi");

var dynCall_viiiii = Module["dynCall_viiiii"] = makeInvalidEarlyAccess("dynCall_viiiii");

var dynCall_ii = Module["dynCall_ii"] = makeInvalidEarlyAccess("dynCall_ii");

var dynCall_fii = Module["dynCall_fii"] = makeInvalidEarlyAccess("dynCall_fii");

var dynCall_viii = Module["dynCall_viii"] = makeInvalidEarlyAccess("dynCall_viii");

var dynCall_viif = Module["dynCall_viif"] = makeInvalidEarlyAccess("dynCall_viif");

var dynCall_viiiiii = Module["dynCall_viiiiii"] = makeInvalidEarlyAccess("dynCall_viiiiii");

var dynCall_viiii = Module["dynCall_viiii"] = makeInvalidEarlyAccess("dynCall_viiii");

var dynCall_vii = Module["dynCall_vii"] = makeInvalidEarlyAccess("dynCall_vii");

var dynCall_iii = Module["dynCall_iii"] = makeInvalidEarlyAccess("dynCall_iii");

var dynCall_iiii = Module["dynCall_iiii"] = makeInvalidEarlyAccess("dynCall_iiii");

var dynCall_iiiii = Module["dynCall_iiiii"] = makeInvalidEarlyAccess("dynCall_iiiii");

var dynCall_iiiiiiii = Module["dynCall_iiiiiiii"] = makeInvalidEarlyAccess("dynCall_iiiiiiii");

var dynCall_iiiji = Module["dynCall_iiiji"] = makeInvalidEarlyAccess("dynCall_iiiji");

var dynCall_iiiiiii = Module["dynCall_iiiiiii"] = makeInvalidEarlyAccess("dynCall_iiiiiii");

var dynCall_jii = Module["dynCall_jii"] = makeInvalidEarlyAccess("dynCall_jii");

var dynCall_viiiiiii = Module["dynCall_viiiiiii"] = makeInvalidEarlyAccess("dynCall_viiiiiii");

var dynCall_v = Module["dynCall_v"] = makeInvalidEarlyAccess("dynCall_v");

var dynCall_jiji = Module["dynCall_jiji"] = makeInvalidEarlyAccess("dynCall_jiji");

var dynCall_iidiiii = Module["dynCall_iidiiii"] = makeInvalidEarlyAccess("dynCall_iidiiii");

var _asyncify_start_unwind = Module["_asyncify_start_unwind"] = makeInvalidEarlyAccess("_asyncify_start_unwind");

var _asyncify_stop_unwind = Module["_asyncify_stop_unwind"] = makeInvalidEarlyAccess("_asyncify_stop_unwind");

var _asyncify_start_rewind = Module["_asyncify_start_rewind"] = makeInvalidEarlyAccess("_asyncify_start_rewind");

var _asyncify_stop_rewind = Module["_asyncify_stop_rewind"] = makeInvalidEarlyAccess("_asyncify_stop_rewind");

var __indirect_function_table = Module["__indirect_function_table"] = makeInvalidEarlyAccess("__indirect_function_table");

var wasmTable = Module["wasmTable"] = makeInvalidEarlyAccess("wasmTable");

function assignWasmExports(wasmExports) {
  assert(typeof wasmExports["flutter_recorder_createWorkerInWasm"] != "undefined", "missing Wasm export: flutter_recorder_createWorkerInWasm");
  assert(typeof wasmExports["_Z41flutter_recorder_sendSilenceEventToWorkerPKcbf"] != "undefined", "missing Wasm export: _Z41flutter_recorder_sendSilenceEventToWorkerPKcbf");
  assert(typeof wasmExports["_Z35flutter_recorder_sendStreamToWorkerPKcPKhi"] != "undefined", "missing Wasm export: _Z35flutter_recorder_sendStreamToWorkerPKcPKhi");
  assert(typeof wasmExports["flutter_recorder_setDartEventCallbackForEngine"] != "undefined", "missing Wasm export: flutter_recorder_setDartEventCallbackForEngine");
  assert(typeof wasmExports["flutter_recorder_setDartEventCallback"] != "undefined", "missing Wasm export: flutter_recorder_setDartEventCallback");
  assert(typeof wasmExports["flutter_recorder_setDartVisualizationCallbackForEngine"] != "undefined", "missing Wasm export: flutter_recorder_setDartVisualizationCallbackForEngine");
  assert(typeof wasmExports["flutter_recorder_setDartVisualizationCallback"] != "undefined", "missing Wasm export: flutter_recorder_setDartVisualizationCallback");
  assert(typeof wasmExports["flutter_recorder_prepareEngineInit"] != "undefined", "missing Wasm export: flutter_recorder_prepareEngineInit");
  assert(typeof wasmExports["flutter_recorder_currentEngineShutdownEpoch"] != "undefined", "missing Wasm export: flutter_recorder_currentEngineShutdownEpoch");
  assert(typeof wasmExports["flutter_recorder_prepareEngineInitForRequest"] != "undefined", "missing Wasm export: flutter_recorder_prepareEngineInitForRequest");
  assert(typeof wasmExports["flutter_recorder_clearDartCallbackRegistrationsForEngine"] != "undefined", "missing Wasm export: flutter_recorder_clearDartCallbackRegistrationsForEngine");
  assert(typeof wasmExports["flutter_recorder_clearDartCallbackRegistrations"] != "undefined", "missing Wasm export: flutter_recorder_clearDartCallbackRegistrations");
  assert(typeof wasmExports["flutter_recorder_requestEngineTeardownForEngine"] != "undefined", "missing Wasm export: flutter_recorder_requestEngineTeardownForEngine");
  assert(typeof wasmExports["flutter_recorder_retireDartCallbacksFinalizer"] != "undefined", "missing Wasm export: flutter_recorder_retireDartCallbacksFinalizer");
  assert(typeof wasmExports["flutter_recorder_nativeFree"] != "undefined", "missing Wasm export: flutter_recorder_nativeFree");
  assert(typeof wasmExports["free"] != "undefined", "missing Wasm export: free");
  assert(typeof wasmExports["flutter_recorder_listCaptureDevices"] != "undefined", "missing Wasm export: flutter_recorder_listCaptureDevices");
  assert(typeof wasmExports["malloc"] != "undefined", "missing Wasm export: malloc");
  assert(typeof wasmExports["flutter_recorder_freeListCaptureDevices"] != "undefined", "missing Wasm export: flutter_recorder_freeListCaptureDevices");
  assert(typeof wasmExports["flutter_recorder_init"] != "undefined", "missing Wasm export: flutter_recorder_init");
  assert(typeof wasmExports["flutter_recorder_deinit"] != "undefined", "missing Wasm export: flutter_recorder_deinit");
  assert(typeof wasmExports["flutter_recorder_isInited"] != "undefined", "missing Wasm export: flutter_recorder_isInited");
  assert(typeof wasmExports["flutter_recorder_isDeviceStarted"] != "undefined", "missing Wasm export: flutter_recorder_isDeviceStarted");
  assert(typeof wasmExports["flutter_recorder_start"] != "undefined", "missing Wasm export: flutter_recorder_start");
  assert(typeof wasmExports["flutter_recorder_stop"] != "undefined", "missing Wasm export: flutter_recorder_stop");
  assert(typeof wasmExports["flutter_recorder_startStreamingData"] != "undefined", "missing Wasm export: flutter_recorder_startStreamingData");
  assert(typeof wasmExports["flutter_recorder_stopStreamingData"] != "undefined", "missing Wasm export: flutter_recorder_stopStreamingData");
  assert(typeof wasmExports["flutter_recorder_setSilenceDetection"] != "undefined", "missing Wasm export: flutter_recorder_setSilenceDetection");
  assert(typeof wasmExports["flutter_recorder_setSilenceThresholdDb"] != "undefined", "missing Wasm export: flutter_recorder_setSilenceThresholdDb");
  assert(typeof wasmExports["flutter_recorder_setSilenceDuration"] != "undefined", "missing Wasm export: flutter_recorder_setSilenceDuration");
  assert(typeof wasmExports["flutter_recorder_setSecondsOfAudioToWriteBefore"] != "undefined", "missing Wasm export: flutter_recorder_setSecondsOfAudioToWriteBefore");
  assert(typeof wasmExports["flutter_recorder_startRecording"] != "undefined", "missing Wasm export: flutter_recorder_startRecording");
  assert(typeof wasmExports["flutter_recorder_setPauseRecording"] != "undefined", "missing Wasm export: flutter_recorder_setPauseRecording");
  assert(typeof wasmExports["flutter_recorder_stopRecording"] != "undefined", "missing Wasm export: flutter_recorder_stopRecording");
  assert(typeof wasmExports["flutter_recorder_getVolumeDb"] != "undefined", "missing Wasm export: flutter_recorder_getVolumeDb");
  assert(typeof wasmExports["flutter_recorder_setVisualizationEnabled"] != "undefined", "missing Wasm export: flutter_recorder_setVisualizationEnabled");
  assert(typeof wasmExports["flutter_recorder_isVisualizationEnabled"] != "undefined", "missing Wasm export: flutter_recorder_isVisualizationEnabled");
  assert(typeof wasmExports["flutter_recorder_setFftSmoothing"] != "undefined", "missing Wasm export: flutter_recorder_setFftSmoothing");
  assert(typeof wasmExports["flutter_recorder_setLoopback"] != "undefined", "missing Wasm export: flutter_recorder_setLoopback");
  assert(typeof wasmExports["flutter_recorder_isLoopbackEnabled"] != "undefined", "missing Wasm export: flutter_recorder_isLoopbackEnabled");
  assert(typeof wasmExports["flutter_recorder_isFilterActive"] != "undefined", "missing Wasm export: flutter_recorder_isFilterActive");
  assert(typeof wasmExports["flutter_recorder_addFilter"] != "undefined", "missing Wasm export: flutter_recorder_addFilter");
  assert(typeof wasmExports["flutter_recorder_removeFilter"] != "undefined", "missing Wasm export: flutter_recorder_removeFilter");
  assert(typeof wasmExports["flutter_recorder_getFilterParamNames"] != "undefined", "missing Wasm export: flutter_recorder_getFilterParamNames");
  assert(typeof wasmExports["flutter_recorder_setFilterParams"] != "undefined", "missing Wasm export: flutter_recorder_setFilterParams");
  assert(typeof wasmExports["flutter_recorder_getFilterParams"] != "undefined", "missing Wasm export: flutter_recorder_getFilterParams");
  assert(typeof wasmExports["flutter_recorder_feedPlaybackData"] != "undefined", "missing Wasm export: flutter_recorder_feedPlaybackData");
  assert(typeof wasmExports["ma_device__on_notification_unlocked"] != "undefined", "missing Wasm export: ma_device__on_notification_unlocked");
  assert(typeof wasmExports["ma_malloc_emscripten"] != "undefined", "missing Wasm export: ma_malloc_emscripten");
  assert(typeof wasmExports["ma_free_emscripten"] != "undefined", "missing Wasm export: ma_free_emscripten");
  assert(typeof wasmExports["ma_device_process_pcm_frames_capture__webaudio"] != "undefined", "missing Wasm export: ma_device_process_pcm_frames_capture__webaudio");
  assert(typeof wasmExports["ma_device_process_pcm_frames_playback__webaudio"] != "undefined", "missing Wasm export: ma_device_process_pcm_frames_playback__webaudio");
  assert(typeof wasmExports["_emscripten_tls_init"] != "undefined", "missing Wasm export: _emscripten_tls_init");
  assert(typeof wasmExports["pthread_self"] != "undefined", "missing Wasm export: pthread_self");
  assert(typeof wasmExports["memcpy"] != "undefined", "missing Wasm export: memcpy");
  assert(typeof wasmExports["memset"] != "undefined", "missing Wasm export: memset");
  assert(typeof wasmExports["_emscripten_thread_init"] != "undefined", "missing Wasm export: _emscripten_thread_init");
  assert(typeof wasmExports["__set_thread_state"] != "undefined", "missing Wasm export: __set_thread_state");
  assert(typeof wasmExports["_emscripten_thread_crashed"] != "undefined", "missing Wasm export: _emscripten_thread_crashed");
  assert(typeof wasmExports["fflush"] != "undefined", "missing Wasm export: fflush");
  assert(typeof wasmExports["emscripten_stack_get_end"] != "undefined", "missing Wasm export: emscripten_stack_get_end");
  assert(typeof wasmExports["emscripten_stack_get_base"] != "undefined", "missing Wasm export: emscripten_stack_get_base");
  assert(typeof wasmExports["strerror"] != "undefined", "missing Wasm export: strerror");
  assert(typeof wasmExports["_emscripten_run_js_on_main_thread"] != "undefined", "missing Wasm export: _emscripten_run_js_on_main_thread");
  assert(typeof wasmExports["_emscripten_thread_free_data"] != "undefined", "missing Wasm export: _emscripten_thread_free_data");
  assert(typeof wasmExports["_emscripten_thread_exit"] != "undefined", "missing Wasm export: _emscripten_thread_exit");
  assert(typeof wasmExports["_emscripten_check_mailbox"] != "undefined", "missing Wasm export: _emscripten_check_mailbox");
  assert(typeof wasmExports["emscripten_stack_init"] != "undefined", "missing Wasm export: emscripten_stack_init");
  assert(typeof wasmExports["emscripten_stack_set_limits"] != "undefined", "missing Wasm export: emscripten_stack_set_limits");
  assert(typeof wasmExports["emscripten_stack_get_free"] != "undefined", "missing Wasm export: emscripten_stack_get_free");
  assert(typeof wasmExports["_emscripten_stack_restore"] != "undefined", "missing Wasm export: _emscripten_stack_restore");
  assert(typeof wasmExports["_emscripten_stack_alloc"] != "undefined", "missing Wasm export: _emscripten_stack_alloc");
  assert(typeof wasmExports["emscripten_stack_get_current"] != "undefined", "missing Wasm export: emscripten_stack_get_current");
  assert(typeof wasmExports["_emscripten_wasm_worker_initialize"] != "undefined", "missing Wasm export: _emscripten_wasm_worker_initialize");
  assert(typeof wasmExports["dynCall_vi"] != "undefined", "missing Wasm export: dynCall_vi");
  assert(typeof wasmExports["dynCall_viiiii"] != "undefined", "missing Wasm export: dynCall_viiiii");
  assert(typeof wasmExports["dynCall_ii"] != "undefined", "missing Wasm export: dynCall_ii");
  assert(typeof wasmExports["dynCall_fii"] != "undefined", "missing Wasm export: dynCall_fii");
  assert(typeof wasmExports["dynCall_viii"] != "undefined", "missing Wasm export: dynCall_viii");
  assert(typeof wasmExports["dynCall_viif"] != "undefined", "missing Wasm export: dynCall_viif");
  assert(typeof wasmExports["dynCall_viiiiii"] != "undefined", "missing Wasm export: dynCall_viiiiii");
  assert(typeof wasmExports["dynCall_viiii"] != "undefined", "missing Wasm export: dynCall_viiii");
  assert(typeof wasmExports["dynCall_vii"] != "undefined", "missing Wasm export: dynCall_vii");
  assert(typeof wasmExports["dynCall_iii"] != "undefined", "missing Wasm export: dynCall_iii");
  assert(typeof wasmExports["dynCall_iiii"] != "undefined", "missing Wasm export: dynCall_iiii");
  assert(typeof wasmExports["dynCall_iiiii"] != "undefined", "missing Wasm export: dynCall_iiiii");
  assert(typeof wasmExports["dynCall_iiiiiiii"] != "undefined", "missing Wasm export: dynCall_iiiiiiii");
  assert(typeof wasmExports["dynCall_iiiji"] != "undefined", "missing Wasm export: dynCall_iiiji");
  assert(typeof wasmExports["dynCall_iiiiiii"] != "undefined", "missing Wasm export: dynCall_iiiiiii");
  assert(typeof wasmExports["dynCall_jii"] != "undefined", "missing Wasm export: dynCall_jii");
  assert(typeof wasmExports["dynCall_viiiiiii"] != "undefined", "missing Wasm export: dynCall_viiiiiii");
  assert(typeof wasmExports["dynCall_v"] != "undefined", "missing Wasm export: dynCall_v");
  assert(typeof wasmExports["dynCall_jiji"] != "undefined", "missing Wasm export: dynCall_jiji");
  assert(typeof wasmExports["dynCall_iidiiii"] != "undefined", "missing Wasm export: dynCall_iidiiii");
  assert(typeof wasmExports["asyncify_start_unwind"] != "undefined", "missing Wasm export: asyncify_start_unwind");
  assert(typeof wasmExports["asyncify_stop_unwind"] != "undefined", "missing Wasm export: asyncify_stop_unwind");
  assert(typeof wasmExports["asyncify_start_rewind"] != "undefined", "missing Wasm export: asyncify_start_rewind");
  assert(typeof wasmExports["asyncify_stop_rewind"] != "undefined", "missing Wasm export: asyncify_stop_rewind");
  assert(typeof wasmExports["__indirect_function_table"] != "undefined", "missing Wasm export: __indirect_function_table");
  _flutter_recorder_createWorkerInWasm = Module["_flutter_recorder_createWorkerInWasm"] = createExportWrapper("flutter_recorder_createWorkerInWasm", 0);
  __Z41flutter_recorder_sendSilenceEventToWorkerPKcbf = Module["__Z41flutter_recorder_sendSilenceEventToWorkerPKcbf"] = createExportWrapper("_Z41flutter_recorder_sendSilenceEventToWorkerPKcbf", 3);
  __Z35flutter_recorder_sendStreamToWorkerPKcPKhi = Module["__Z35flutter_recorder_sendStreamToWorkerPKcPKhi"] = createExportWrapper("_Z35flutter_recorder_sendStreamToWorkerPKcPKhi", 3);
  _flutter_recorder_setDartEventCallbackForEngine = Module["_flutter_recorder_setDartEventCallbackForEngine"] = createExportWrapper("flutter_recorder_setDartEventCallbackForEngine", 3);
  _flutter_recorder_setDartEventCallback = Module["_flutter_recorder_setDartEventCallback"] = createExportWrapper("flutter_recorder_setDartEventCallback", 2);
  _flutter_recorder_setDartVisualizationCallbackForEngine = Module["_flutter_recorder_setDartVisualizationCallbackForEngine"] = createExportWrapper("flutter_recorder_setDartVisualizationCallbackForEngine", 2);
  _flutter_recorder_setDartVisualizationCallback = Module["_flutter_recorder_setDartVisualizationCallback"] = createExportWrapper("flutter_recorder_setDartVisualizationCallback", 1);
  _flutter_recorder_prepareEngineInit = Module["_flutter_recorder_prepareEngineInit"] = createExportWrapper("flutter_recorder_prepareEngineInit", 1);
  _flutter_recorder_currentEngineShutdownEpoch = Module["_flutter_recorder_currentEngineShutdownEpoch"] = createExportWrapper("flutter_recorder_currentEngineShutdownEpoch", 0);
  _flutter_recorder_prepareEngineInitForRequest = Module["_flutter_recorder_prepareEngineInitForRequest"] = createExportWrapper("flutter_recorder_prepareEngineInitForRequest", 2);
  _flutter_recorder_clearDartCallbackRegistrationsForEngine = Module["_flutter_recorder_clearDartCallbackRegistrationsForEngine"] = createExportWrapper("flutter_recorder_clearDartCallbackRegistrationsForEngine", 1);
  _flutter_recorder_clearDartCallbackRegistrations = Module["_flutter_recorder_clearDartCallbackRegistrations"] = createExportWrapper("flutter_recorder_clearDartCallbackRegistrations", 0);
  _flutter_recorder_requestEngineTeardownForEngine = Module["_flutter_recorder_requestEngineTeardownForEngine"] = createExportWrapper("flutter_recorder_requestEngineTeardownForEngine", 1);
  _flutter_recorder_retireDartCallbacksFinalizer = Module["_flutter_recorder_retireDartCallbacksFinalizer"] = createExportWrapper("flutter_recorder_retireDartCallbacksFinalizer", 1);
  _flutter_recorder_nativeFree = Module["_flutter_recorder_nativeFree"] = createExportWrapper("flutter_recorder_nativeFree", 1);
  _free = Module["_free"] = createExportWrapper("free", 1);
  _flutter_recorder_listCaptureDevices = Module["_flutter_recorder_listCaptureDevices"] = createExportWrapper("flutter_recorder_listCaptureDevices", 4);
  _malloc = Module["_malloc"] = createExportWrapper("malloc", 1);
  _flutter_recorder_freeListCaptureDevices = Module["_flutter_recorder_freeListCaptureDevices"] = createExportWrapper("flutter_recorder_freeListCaptureDevices", 4);
  _flutter_recorder_init = Module["_flutter_recorder_init"] = createExportWrapper("flutter_recorder_init", 6);
  _flutter_recorder_deinit = Module["_flutter_recorder_deinit"] = createExportWrapper("flutter_recorder_deinit", 0);
  _flutter_recorder_isInited = Module["_flutter_recorder_isInited"] = createExportWrapper("flutter_recorder_isInited", 0);
  _flutter_recorder_isDeviceStarted = Module["_flutter_recorder_isDeviceStarted"] = createExportWrapper("flutter_recorder_isDeviceStarted", 0);
  _flutter_recorder_start = Module["_flutter_recorder_start"] = createExportWrapper("flutter_recorder_start", 0);
  _flutter_recorder_stop = Module["_flutter_recorder_stop"] = createExportWrapper("flutter_recorder_stop", 0);
  _flutter_recorder_startStreamingData = Module["_flutter_recorder_startStreamingData"] = createExportWrapper("flutter_recorder_startStreamingData", 1);
  _flutter_recorder_stopStreamingData = Module["_flutter_recorder_stopStreamingData"] = createExportWrapper("flutter_recorder_stopStreamingData", 0);
  _flutter_recorder_setSilenceDetection = Module["_flutter_recorder_setSilenceDetection"] = createExportWrapper("flutter_recorder_setSilenceDetection", 1);
  _flutter_recorder_setSilenceThresholdDb = Module["_flutter_recorder_setSilenceThresholdDb"] = createExportWrapper("flutter_recorder_setSilenceThresholdDb", 1);
  _flutter_recorder_setSilenceDuration = Module["_flutter_recorder_setSilenceDuration"] = createExportWrapper("flutter_recorder_setSilenceDuration", 1);
  _flutter_recorder_setSecondsOfAudioToWriteBefore = Module["_flutter_recorder_setSecondsOfAudioToWriteBefore"] = createExportWrapper("flutter_recorder_setSecondsOfAudioToWriteBefore", 1);
  _flutter_recorder_startRecording = Module["_flutter_recorder_startRecording"] = createExportWrapper("flutter_recorder_startRecording", 2);
  _flutter_recorder_setPauseRecording = Module["_flutter_recorder_setPauseRecording"] = createExportWrapper("flutter_recorder_setPauseRecording", 1);
  _flutter_recorder_stopRecording = Module["_flutter_recorder_stopRecording"] = createExportWrapper("flutter_recorder_stopRecording", 0);
  _flutter_recorder_getVolumeDb = Module["_flutter_recorder_getVolumeDb"] = createExportWrapper("flutter_recorder_getVolumeDb", 1);
  _flutter_recorder_setVisualizationEnabled = Module["_flutter_recorder_setVisualizationEnabled"] = createExportWrapper("flutter_recorder_setVisualizationEnabled", 4);
  _flutter_recorder_isVisualizationEnabled = Module["_flutter_recorder_isVisualizationEnabled"] = createExportWrapper("flutter_recorder_isVisualizationEnabled", 0);
  _flutter_recorder_setFftSmoothing = Module["_flutter_recorder_setFftSmoothing"] = createExportWrapper("flutter_recorder_setFftSmoothing", 1);
  _flutter_recorder_setLoopback = Module["_flutter_recorder_setLoopback"] = createExportWrapper("flutter_recorder_setLoopback", 1);
  _flutter_recorder_isLoopbackEnabled = Module["_flutter_recorder_isLoopbackEnabled"] = createExportWrapper("flutter_recorder_isLoopbackEnabled", 0);
  _flutter_recorder_isFilterActive = Module["_flutter_recorder_isFilterActive"] = createExportWrapper("flutter_recorder_isFilterActive", 1);
  _flutter_recorder_addFilter = Module["_flutter_recorder_addFilter"] = createExportWrapper("flutter_recorder_addFilter", 1);
  _flutter_recorder_removeFilter = Module["_flutter_recorder_removeFilter"] = createExportWrapper("flutter_recorder_removeFilter", 1);
  _flutter_recorder_getFilterParamNames = Module["_flutter_recorder_getFilterParamNames"] = createExportWrapper("flutter_recorder_getFilterParamNames", 3);
  _flutter_recorder_setFilterParams = Module["_flutter_recorder_setFilterParams"] = createExportWrapper("flutter_recorder_setFilterParams", 3);
  _flutter_recorder_getFilterParams = Module["_flutter_recorder_getFilterParams"] = createExportWrapper("flutter_recorder_getFilterParams", 2);
  _flutter_recorder_feedPlaybackData = Module["_flutter_recorder_feedPlaybackData"] = createExportWrapper("flutter_recorder_feedPlaybackData", 4);
  _ma_device__on_notification_unlocked = Module["_ma_device__on_notification_unlocked"] = createExportWrapper("ma_device__on_notification_unlocked", 1);
  _ma_malloc_emscripten = Module["_ma_malloc_emscripten"] = createExportWrapper("ma_malloc_emscripten", 2);
  _ma_free_emscripten = Module["_ma_free_emscripten"] = createExportWrapper("ma_free_emscripten", 2);
  _ma_device_process_pcm_frames_capture__webaudio = Module["_ma_device_process_pcm_frames_capture__webaudio"] = createExportWrapper("ma_device_process_pcm_frames_capture__webaudio", 3);
  _ma_device_process_pcm_frames_playback__webaudio = Module["_ma_device_process_pcm_frames_playback__webaudio"] = createExportWrapper("ma_device_process_pcm_frames_playback__webaudio", 3);
  __emscripten_tls_init = Module["__emscripten_tls_init"] = createExportWrapper("_emscripten_tls_init", 0);
  _pthread_self = Module["_pthread_self"] = createExportWrapper("pthread_self", 0);
  _memcpy = Module["_memcpy"] = createExportWrapper("memcpy", 3);
  _memset = Module["_memset"] = createExportWrapper("memset", 3);
  __emscripten_thread_init = Module["__emscripten_thread_init"] = createExportWrapper("_emscripten_thread_init", 6);
  ___set_thread_state = Module["___set_thread_state"] = createExportWrapper("__set_thread_state", 4);
  __emscripten_thread_crashed = Module["__emscripten_thread_crashed"] = createExportWrapper("_emscripten_thread_crashed", 0);
  _fflush = Module["_fflush"] = createExportWrapper("fflush", 1);
  _emscripten_stack_get_end = Module["_emscripten_stack_get_end"] = wasmExports["emscripten_stack_get_end"];
  _emscripten_stack_get_base = Module["_emscripten_stack_get_base"] = wasmExports["emscripten_stack_get_base"];
  _strerror = Module["_strerror"] = createExportWrapper("strerror", 1);
  __emscripten_run_js_on_main_thread = Module["__emscripten_run_js_on_main_thread"] = createExportWrapper("_emscripten_run_js_on_main_thread", 5);
  __emscripten_thread_free_data = Module["__emscripten_thread_free_data"] = createExportWrapper("_emscripten_thread_free_data", 1);
  __emscripten_thread_exit = Module["__emscripten_thread_exit"] = createExportWrapper("_emscripten_thread_exit", 1);
  __emscripten_check_mailbox = Module["__emscripten_check_mailbox"] = createExportWrapper("_emscripten_check_mailbox", 0);
  _emscripten_stack_init = Module["_emscripten_stack_init"] = wasmExports["emscripten_stack_init"];
  _emscripten_stack_set_limits = Module["_emscripten_stack_set_limits"] = wasmExports["emscripten_stack_set_limits"];
  _emscripten_stack_get_free = Module["_emscripten_stack_get_free"] = wasmExports["emscripten_stack_get_free"];
  __emscripten_stack_restore = Module["__emscripten_stack_restore"] = wasmExports["_emscripten_stack_restore"];
  __emscripten_stack_alloc = Module["__emscripten_stack_alloc"] = wasmExports["_emscripten_stack_alloc"];
  _emscripten_stack_get_current = Module["_emscripten_stack_get_current"] = wasmExports["emscripten_stack_get_current"];
  __emscripten_wasm_worker_initialize = Module["__emscripten_wasm_worker_initialize"] = createExportWrapper("_emscripten_wasm_worker_initialize", 2);
  dynCall_vi = dynCalls["vi"] = Module["dynCall_vi"] = createExportWrapper("dynCall_vi", 2);
  dynCall_viiiii = dynCalls["viiiii"] = Module["dynCall_viiiii"] = createExportWrapper("dynCall_viiiii", 6);
  dynCall_ii = dynCalls["ii"] = Module["dynCall_ii"] = createExportWrapper("dynCall_ii", 2);
  dynCall_fii = dynCalls["fii"] = Module["dynCall_fii"] = createExportWrapper("dynCall_fii", 3);
  dynCall_viii = dynCalls["viii"] = Module["dynCall_viii"] = createExportWrapper("dynCall_viii", 4);
  dynCall_viif = dynCalls["viif"] = Module["dynCall_viif"] = createExportWrapper("dynCall_viif", 4);
  dynCall_viiiiii = dynCalls["viiiiii"] = Module["dynCall_viiiiii"] = createExportWrapper("dynCall_viiiiii", 7);
  dynCall_viiii = dynCalls["viiii"] = Module["dynCall_viiii"] = createExportWrapper("dynCall_viiii", 5);
  dynCall_vii = dynCalls["vii"] = Module["dynCall_vii"] = createExportWrapper("dynCall_vii", 3);
  dynCall_iii = dynCalls["iii"] = Module["dynCall_iii"] = createExportWrapper("dynCall_iii", 3);
  dynCall_iiii = dynCalls["iiii"] = Module["dynCall_iiii"] = createExportWrapper("dynCall_iiii", 4);
  dynCall_iiiii = dynCalls["iiiii"] = Module["dynCall_iiiii"] = createExportWrapper("dynCall_iiiii", 5);
  dynCall_iiiiiiii = dynCalls["iiiiiiii"] = Module["dynCall_iiiiiiii"] = createExportWrapper("dynCall_iiiiiiii", 8);
  dynCall_iiiji = dynCalls["iiiji"] = Module["dynCall_iiiji"] = createExportWrapper("dynCall_iiiji", 5);
  dynCall_iiiiiii = dynCalls["iiiiiii"] = Module["dynCall_iiiiiii"] = createExportWrapper("dynCall_iiiiiii", 7);
  dynCall_jii = dynCalls["jii"] = Module["dynCall_jii"] = createExportWrapper("dynCall_jii", 3);
  dynCall_viiiiiii = dynCalls["viiiiiii"] = Module["dynCall_viiiiiii"] = createExportWrapper("dynCall_viiiiiii", 8);
  dynCall_v = dynCalls["v"] = Module["dynCall_v"] = createExportWrapper("dynCall_v", 1);
  dynCall_jiji = dynCalls["jiji"] = Module["dynCall_jiji"] = createExportWrapper("dynCall_jiji", 4);
  dynCall_iidiiii = dynCalls["iidiiii"] = Module["dynCall_iidiiii"] = createExportWrapper("dynCall_iidiiii", 7);
  _asyncify_start_unwind = Module["_asyncify_start_unwind"] = createExportWrapper("asyncify_start_unwind", 1);
  _asyncify_stop_unwind = Module["_asyncify_stop_unwind"] = createExportWrapper("asyncify_stop_unwind", 0);
  _asyncify_start_rewind = Module["_asyncify_start_rewind"] = createExportWrapper("asyncify_start_rewind", 1);
  _asyncify_stop_rewind = Module["_asyncify_stop_rewind"] = createExportWrapper("asyncify_stop_rewind", 0);
  __indirect_function_table = Module["__indirect_function_table"] = wasmTable = wasmExports["__indirect_function_table"];
}

var wasmImports;

function assignWasmImports() {
  wasmImports = {
    /** @export */ __assert_fail: ___assert_fail,
    /** @export */ __cxa_throw: ___cxa_throw,
    /** @export */ __pthread_create_js: ___pthread_create_js,
    /** @export */ _abort_js: __abort_js,
    /** @export */ _emscripten_init_main_thread_js: __emscripten_init_main_thread_js,
    /** @export */ _emscripten_notify_mailbox_postmessage: __emscripten_notify_mailbox_postmessage,
    /** @export */ _emscripten_receive_on_main_thread_js: __emscripten_receive_on_main_thread_js,
    /** @export */ _emscripten_thread_cleanup: __emscripten_thread_cleanup,
    /** @export */ _emscripten_thread_mailbox_await: __emscripten_thread_mailbox_await,
    /** @export */ _emscripten_thread_set_strongref: __emscripten_thread_set_strongref,
    /** @export */ clock_time_get: _clock_time_get,
    /** @export */ emscripten_asm_const_int: _emscripten_asm_const_int,
    /** @export */ emscripten_audio_context_quantum_size: _emscripten_audio_context_quantum_size,
    /** @export */ emscripten_audio_worklet_post_function_sig: _emscripten_audio_worklet_post_function_sig,
    /** @export */ emscripten_audio_worklet_post_function_viii: _emscripten_audio_worklet_post_function_viii,
    /** @export */ emscripten_check_blocking_allowed: _emscripten_check_blocking_allowed,
    /** @export */ emscripten_create_audio_context: _emscripten_create_audio_context,
    /** @export */ emscripten_create_wasm_audio_worklet_node: _emscripten_create_wasm_audio_worklet_node,
    /** @export */ emscripten_create_wasm_audio_worklet_processor_async: _emscripten_create_wasm_audio_worklet_processor_async,
    /** @export */ emscripten_date_now: _emscripten_date_now,
    /** @export */ emscripten_destroy_audio_context: _emscripten_destroy_audio_context,
    /** @export */ emscripten_destroy_web_audio_node: _emscripten_destroy_web_audio_node,
    /** @export */ emscripten_exit_with_live_runtime: _emscripten_exit_with_live_runtime,
    /** @export */ emscripten_get_now: _emscripten_get_now,
    /** @export */ emscripten_resize_heap: _emscripten_resize_heap,
    /** @export */ emscripten_sleep: _emscripten_sleep,
    /** @export */ emscripten_start_wasm_audio_worklet_thread_async: _emscripten_start_wasm_audio_worklet_thread_async,
    /** @export */ exit: _exit,
    /** @export */ fd_close: _fd_close,
    /** @export */ fd_seek: _fd_seek,
    /** @export */ fd_write: _fd_write,
    /** @export */ memory: wasmMemory
  };
}

// include: postamble.js
// === Auto-generated postamble setup entry stuff ===
var calledRun;

function stackCheckInit() {
  // This is normally called automatically during __wasm_call_ctors but need to
  // get these values before even running any of the ctors so we call it redundantly
  // here.
  // See $establishStackSpace for the equivalent code that runs on a thread
  assert(!ENVIRONMENT_IS_PTHREAD);
  _emscripten_stack_init();
  // TODO(sbc): Move writeStackCookie to native to to avoid this.
  writeStackCookie();
}

function run() {
  if (runDependencies > 0) {
    dependenciesFulfilled = run;
    return;
  }
  if ((ENVIRONMENT_IS_PTHREAD || ENVIRONMENT_IS_WASM_WORKER)) {
    readyPromiseResolve?.(Module);
    initRuntime();
    return;
  }
  stackCheckInit();
  preRun();
  // a preRun added a dependency, run will be called later
  if (runDependencies > 0) {
    dependenciesFulfilled = run;
    return;
  }
  function doRun() {
    // run may have just been called through dependencies being fulfilled just in this very frame,
    // or while the async setStatus time below was happening
    assert(!calledRun);
    calledRun = true;
    Module["calledRun"] = true;
    if (ABORT) return;
    initRuntime();
    readyPromiseResolve?.(Module);
    Module["onRuntimeInitialized"]?.();
    consumedModuleProp("onRuntimeInitialized");
    assert(!Module["_main"], 'compiled without a main, but one is present. if you added it from JS, use Module["onRuntimeInitialized"]');
    postRun();
  }
  if (Module["setStatus"]) {
    Module["setStatus"]("Running...");
    setTimeout(() => {
      setTimeout(() => Module["setStatus"](""), 1);
      doRun();
    }, 1);
  } else {
    doRun();
  }
  checkStackCookie();
}

function checkUnflushedContent() {
  // Compiler settings do not allow exiting the runtime, so flushing
  // the streams is not possible. but in ASSERTIONS mode we check
  // if there was something to flush, and if so tell the user they
  // should request that the runtime be exitable.
  // Normally we would not even include flush() at all, but in ASSERTIONS
  // builds we do so just for this check, and here we see if there is any
  // content to flush, that is, we check if there would have been
  // something a non-ASSERTIONS build would have not seen.
  // How we flush the streams depends on whether we are in SYSCALLS_REQUIRE_FILESYSTEM=0
  // mode (which has its own special function for this; otherwise, all
  // the code is inside libc)
  var oldOut = out;
  var oldErr = err;
  var has = false;
  out = err = x => {
    has = true;
  };
  try {
    // it doesn't matter if it fails
    flush_NO_FILESYSTEM();
  } catch (e) {}
  out = oldOut;
  err = oldErr;
  if (has) {
    warnOnce("stdio streams had content in them that was not flushed. you should set EXIT_RUNTIME to 1 (see the Emscripten FAQ), or make sure to emit a newline when you printf etc.");
    warnOnce("(this may also be due to not including full filesystem support - try building with -sFORCE_FILESYSTEM)");
  }
}

var wasmExports;

if ((!(ENVIRONMENT_IS_PTHREAD || ENVIRONMENT_IS_WASM_WORKER))) {
  // Call createWasm on startup if we are the main thread.
  // Worker threads call this once they receive the module via postMessage
  // In modularize mode the generated code is within a factory function so we
  // can use await here (since it's not top-level-await).
  wasmExports = await (createWasm());
  run();
}

// end include: postamble.js
// include: postamble_modularize.js
// In MODULARIZE mode we wrap the generated code in a factory function
// and return either the Module itself, or a promise of the module.
// We assign to the `moduleRtn` global here and configure closure to see
// this as and extern so it won't get minified.
if (runtimeInitialized) {
  moduleRtn = Module;
} else {
  // Set up the promise that indicates the Module is initialized
  moduleRtn = new Promise((resolve, reject) => {
    readyPromiseResolve = resolve;
    readyPromiseReject = reject;
  });
}

// Assertion for attempting to access module properties on the incoming
// moduleArg.  In the past we used this object as the prototype of the module
// and assigned properties to it, but now we return a distinct object.  This
// keeps the instance private until it is ready (i.e the promise has been
// resolved).
for (const prop of Object.keys(Module)) {
  if (!(prop in moduleArg)) {
    Object.defineProperty(moduleArg, prop, {
      configurable: true,
      get() {
        abort(`Access to module property ('${prop}') is no longer possible via the module constructor argument; Instead, use the result of the module constructor.`);
      }
    });
  }
}


    return moduleRtn;
  };
})();

// Export using a UMD style export, or ES6 exports if selected
if (typeof exports === 'object' && typeof module === 'object') {
  module.exports = RecorderModule;
  // This default export looks redundant, but it allows TS to import this
  // commonjs style module.
  module.exports.default = RecorderModule;
} else if (typeof define === 'function' && define['amd'])
  define([], () => RecorderModule);

// Create code for detecting if we are running in a pthread.
// Normally this detection is done when the module is itself run but
// when running in MODULARIZE mode we need use this to know if we should
// run the module constructor on startup (true only for pthreads).
var isPthread = globalThis.self?.name?.startsWith('em-pthread');
// In order to support both web and node we also need to detect node here.
var isNode = globalThis.process?.versions?.node && globalThis.process?.type != 'renderer';
if (isNode) isPthread = require('worker_threads').workerData === 'em-pthread'

isPthread && RecorderModule();

// Same as above for for WASM_WORKERS
// Normally this detection is done when the module is itself run but
// when running in MODULARIZE mode we need use this to know if we should
// run the module constructor on startup (true only for pthreads).
var isWW = globalThis.self?.name == 'em-ww';
// In order to support both web and node we also need to detect node here.
if (isNode) isWW = require('worker_threads').workerData === 'em-ww';

isWW ||= !!globalThis.AudioWorkletGlobalScope;
// When running as a wasm worker, construct a new instance on startup

isWW && RecorderModule();

