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
  if (currentNodeVersion < 16e4) {
    throw new Error(`This emscripten-generated code requires node v${packedVersionToHumanReadable(16e4)} (detected v${packedVersionToHumanReadable(currentNodeVersion)})`);
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

// Determine the runtime environment we are in. You can customize this by
// setting the ENVIRONMENT setting at compile time (see settings.js).
// Attempt to auto-detect the environment
var ENVIRONMENT_IS_WEB = !!globalThis.window;

var ENVIRONMENT_IS_WORKER = !!globalThis.WorkerGlobalScope;

// N.b. Electron.js environment is simultaneously a NODE-environment, but
// also a web environment.
var ENVIRONMENT_IS_NODE = globalThis.process?.versions?.node && globalThis.process?.type != "renderer";

var ENVIRONMENT_IS_SHELL = !ENVIRONMENT_IS_WEB && !ENVIRONMENT_IS_NODE && !ENVIRONMENT_IS_WORKER;

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
  {
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
} else {
  throw new Error("environment detection error");
}

var out = console.log.bind(console);

var err = console.error.bind(console);

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
  HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((max) >> 2), "storing")] = 34821223;
  HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((max) + (4)) >> 2), "storing")] = 2310721022;
}

function checkStackCookie() {
  if (ABORT) return;
  var max = _emscripten_stack_get_end();
  // See writeStackCookie().
  if (max == 0) {
    max += 4;
  }
  var cookie1 = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((max) >> 2), "loading")];
  var cookie2 = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((max) + (4)) >> 2), "loading")];
  if (cookie1 != 34821223 || cookie2 != 2310721022) {
    abort(`Stack overflow! Stack cookie has been overwritten at ${ptrToString(max)}, expected hex dwords 0x89BACDFE and 0x2135467, but received ${ptrToString(cookie2)} ${ptrToString(cookie1)}`);
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
  // TODO(sbc): Make this configurable somehow.  Its not always convenient for
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

// end include: runtime_debug.js
// include: runtime_safe_heap.js
function SAFE_HEAP_INDEX(arr, idx, action) {
  const bytes = arr.BYTES_PER_ELEMENT;
  const dest = idx * bytes;
  if (idx <= 0) abort(`segmentation fault ${action} ${bytes} bytes at address ${dest}`);
  if (runtimeInitialized) {
    var brk = _sbrk(0);
    if (dest + bytes > brk) abort(`segmentation fault, exceeded the top of the available dynamic heap when ${action} ${bytes} bytes at address ${dest}. DYNAMICTOP=${brk}`);
    if (brk < _emscripten_stack_get_base()) abort(`brk >= _emscripten_stack_get_base() (brk=${brk}, _emscripten_stack_get_base()=${_emscripten_stack_get_base()})`);
    // sbrk-managed memory must be above the stack
    if (brk > wasmMemory.buffer.byteLength) abort(`brk <= wasmMemory.buffer.byteLength (brk=${brk}, wasmMemory.buffer.byteLength=${wasmMemory.buffer.byteLength})`);
  }
  return idx;
}

function segfault() {
  abort("segmentation fault");
}

function alignfault() {
  abort("alignment fault");
}

// end include: runtime_safe_heap.js
var readyPromiseResolve, readyPromiseReject;

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

// include: memoryprofiler.js
// end include: memoryprofiler.js
// end include: runtime_common.js
assert(globalThis.Int32Array && globalThis.Float64Array && Int32Array.prototype.subarray && Int32Array.prototype.set, "JS engine does not provide full typed array support");

function preRun() {
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
  checkStackCookie();
  // No ATINITS hooks
  wasmExports["__wasm_call_ctors"]();
}

function postRun() {
  checkStackCookie();
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
  return locateFile("libflutter_recorder_plugin.wasm");
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
    assignWasmExports(wasmExports);
    updateMemoryViews();
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
    // TODO: Due to Closure regression https://github.com/google/closure-compiler/issues/3193, the above line no longer optimizes out down to the following line.
    // When the regression is fixed, can restore the above PTHREADS-enabled path.
    return receiveInstance(result["instance"]);
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

var callRuntimeCallbacks = callbacks => {
  while (callbacks.length > 0) {
    // Pass the module as the first argument.
    callbacks.shift()(Module);
  }
};

var onPostRuns = [];

var addOnPostRun = cb => onPostRuns.push(cb);

var onPreRuns = [];

var addOnPreRun = cb => onPreRuns.push(cb);

/**
     * @param {number} ptr
     * @param {string} type
     */ function getValue(ptr, type = "i8") {
  if (type.endsWith("*")) type = "*";
  switch (type) {
   case "i1":
    return HEAP8[SAFE_HEAP_INDEX(HEAP8, ptr, "loading")];

   case "i8":
    return HEAP8[SAFE_HEAP_INDEX(HEAP8, ptr, "loading")];

   case "i16":
    return HEAP16[SAFE_HEAP_INDEX(HEAP16, ((ptr) >> 1), "loading")];

   case "i32":
    return HEAP32[SAFE_HEAP_INDEX(HEAP32, ((ptr) >> 2), "loading")];

   case "i64":
    return HEAP64[SAFE_HEAP_INDEX(HEAP64, ((ptr) >> 3), "loading")];

   case "float":
    return HEAPF32[SAFE_HEAP_INDEX(HEAPF32, ((ptr) >> 2), "loading")];

   case "double":
    return HEAPF64[SAFE_HEAP_INDEX(HEAPF64, ((ptr) >> 3), "loading")];

   case "*":
    return HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((ptr) >> 2), "loading")];

   default:
    abort(`invalid type for getValue: ${type}`);
  }
}

var noExitRuntime = true;

var ptrToString = ptr => {
  assert(typeof ptr === "number", `ptrToString expects a number, got ${typeof ptr}`);
  // Convert to 32-bit unsigned value
  ptr >>>= 0;
  return "0x" + ptr.toString(16).padStart(8, "0");
};

/**
     * @param {number} ptr
     * @param {number} value
     * @param {string} type
     */ function setValue(ptr, value, type = "i8") {
  if (type.endsWith("*")) type = "*";
  switch (type) {
   case "i1":
    HEAP8[SAFE_HEAP_INDEX(HEAP8, ptr, "storing")] = value;
    break;

   case "i8":
    HEAP8[SAFE_HEAP_INDEX(HEAP8, ptr, "storing")] = value;
    break;

   case "i16":
    HEAP16[SAFE_HEAP_INDEX(HEAP16, ((ptr) >> 1), "storing")] = value;
    break;

   case "i32":
    HEAP32[SAFE_HEAP_INDEX(HEAP32, ((ptr) >> 2), "storing")] = value;
    break;

   case "i64":
    HEAP64[SAFE_HEAP_INDEX(HEAP64, ((ptr) >> 3), "storing")] = BigInt(value);
    break;

   case "float":
    HEAPF32[SAFE_HEAP_INDEX(HEAPF32, ((ptr) >> 2), "storing")] = value;
    break;

   case "double":
    HEAPF64[SAFE_HEAP_INDEX(HEAPF64, ((ptr) >> 3), "storing")] = value;
    break;

   case "*":
    HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((ptr) >> 2), "storing")] = value;
    break;

   default:
    abort(`invalid type for setValue: ${type}`);
  }
}

var stackRestore = val => __emscripten_stack_restore(val);

var stackSave = () => _emscripten_stack_get_current();

var warnOnce = text => {
  warnOnce.shown ||= {};
  if (!warnOnce.shown[text]) {
    warnOnce.shown[text] = 1;
    if (ENVIRONMENT_IS_NODE) text = "warning: " + text;
    err(text);
  }
};

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
    return UTF8Decoder.decode(heapOrArray.subarray(idx, endPtr));
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
  return ptr ? UTF8ArrayToString(HEAPU8, ptr, maxBytesToRead, ignoreNul) : "";
};

var ___assert_fail = (condition, filename, line, func) => abort(`Assertion failed: ${UTF8ToString(condition)}, at: ` + [ filename ? UTF8ToString(filename) : "unknown filename", line, func ? UTF8ToString(func) : "unknown function" ]);

class ExceptionInfo {
  // excPtr - Thrown object pointer to wrap. Metadata pointer is calculated from it.
  constructor(excPtr) {
    this.excPtr = excPtr;
    this.ptr = excPtr - 24;
  }
  set_type(type) {
    HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((this.ptr) + (4)) >> 2), "storing")] = type;
  }
  get_type() {
    return HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((this.ptr) + (4)) >> 2), "loading")];
  }
  set_destructor(destructor) {
    HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((this.ptr) + (8)) >> 2), "storing")] = destructor;
  }
  get_destructor() {
    return HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((this.ptr) + (8)) >> 2), "loading")];
  }
  set_caught(caught) {
    caught = caught ? 1 : 0;
    HEAP8[SAFE_HEAP_INDEX(HEAP8, (this.ptr) + (12), "storing")] = caught;
  }
  get_caught() {
    return HEAP8[SAFE_HEAP_INDEX(HEAP8, (this.ptr) + (12), "loading")] != 0;
  }
  set_rethrown(rethrown) {
    rethrown = rethrown ? 1 : 0;
    HEAP8[SAFE_HEAP_INDEX(HEAP8, (this.ptr) + (13), "storing")] = rethrown;
  }
  get_rethrown() {
    return HEAP8[SAFE_HEAP_INDEX(HEAP8, (this.ptr) + (13), "loading")] != 0;
  }
  // Initialize native structure fields. Should be called once after allocated.
  init(type, destructor) {
    this.set_adjusted_ptr(0);
    this.set_type(type);
    this.set_destructor(destructor);
  }
  set_adjusted_ptr(adjustedPtr) {
    HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((this.ptr) + (16)) >> 2), "storing")] = adjustedPtr;
  }
  get_adjusted_ptr() {
    return HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((this.ptr) + (16)) >> 2), "loading")];
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

var __abort_js = () => abort("native code called abort()");

var _emscripten_get_now = () => performance.now();

var _emscripten_date_now = () => Date.now();

var nowIsMonotonic = 1;

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
  HEAP64[SAFE_HEAP_INDEX(HEAP64, ((ptime) >> 3), "storing")] = BigInt(nsec);
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
  while (ch = HEAPU8[SAFE_HEAP_INDEX(HEAPU8, sigPtr++, "loading")]) {
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
    ch == 112 ? HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((buf) >> 2), "loading")] : ch == 106 ? HEAP64[SAFE_HEAP_INDEX(HEAP64, ((buf) >> 3), "loading")] : ch == 105 ? HEAP32[SAFE_HEAP_INDEX(HEAP32, ((buf) >> 2), "loading")] : HEAPF64[SAFE_HEAP_INDEX(HEAPF64, ((buf) >> 3), "loading")]);
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
  var oldSize = HEAPU8.length;
  // With CAN_ADDRESS_2GB or MEMORY64, pointers are already unsigned.
  requestedSize >>>= 0;
  // With multithreaded builds, races can happen (another thread might increase the size
  // in between), so return a failure, and let the caller retry.
  assert(requestedSize > oldSize);
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

var runtimeKeepaliveCounter = 0;

var keepRuntimeAlive = () => noExitRuntime || runtimeKeepaliveCounter > 0;

var _proc_exit = code => {
  EXITSTATUS = code;
  if (!keepRuntimeAlive()) {
    Module["onExit"]?.(code);
    ABORT = true;
  }
  quit_(code, new ExitStatus(code));
};

/** @param {boolean|number=} implicit */ var exitJS = (status, implicit) => {
  EXITSTATUS = status;
  checkUnflushedContent();
  // if exit() was called explicitly, warn the user if the runtime isn't actually being shut down
  if (keepRuntimeAlive() && !implicit) {
    var msg = `program exited (with status: ${status}), but keepRuntimeAlive() is set (counter=${runtimeKeepaliveCounter}) due to an async operation, so halting execution but not exiting the runtime or preventing further async execution (you can use emscripten_force_exit, if you want to force a true shutdown)`;
    readyPromiseReject?.(msg);
    err(msg);
  }
  _proc_exit(status);
};

var _exit = exitJS;

var SYSCALLS = {
  varargs: undefined,
  getStr(ptr) {
    var ret = UTF8ToString(ptr);
    return ret;
  }
};

var _fd_close = fd => {
  abort("fd_close called without SYSCALLS_REQUIRE_FILESYSTEM");
};

function _fd_seek(fd, offset, whence, newOffset) {
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

var _fd_write = (fd, iov, iovcnt, pnum) => {
  // hack to support printf in SYSCALLS_REQUIRE_FILESYSTEM=0
  var num = 0;
  for (var i = 0; i < iovcnt; i++) {
    var ptr = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((iov) >> 2), "loading")];
    var len = HEAPU32[SAFE_HEAP_INDEX(HEAPU32, (((iov) + (4)) >> 2), "loading")];
    iov += 8;
    for (var j = 0; j < len; j++) {
      printChar(fd, HEAPU8[SAFE_HEAP_INDEX(HEAPU8, ptr + j, "loading")]);
    }
    num += len;
  }
  HEAPU32[SAFE_HEAP_INDEX(HEAPU32, ((pnum) >> 2), "storing")] = num;
  return 0;
};

var getCFunc = ident => {
  var func = Module["_" + ident];
  // closure exported function
  assert(func, "Cannot call unknown function " + ident + ", make sure it is exported");
  return func;
};

var writeArrayToMemory = (array, buffer) => {
  assert(array.length >= 0, "writeArrayToMemory array must have a length (should be an array or typed array)");
  HEAP8.set(array, buffer);
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
  return stringToUTF8Array(str, HEAPU8, outPtr, maxBytesToWrite);
};

var stackAlloc = sz => __emscripten_stack_alloc(sz);

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
  var ret = func(...cArgs);
  function onDone(ret) {
    if (stack !== 0) stackRestore(stack);
    return convertReturnValue(ret);
  }
  ret = onDone(ret);
  return ret;
};

/**
     * @param {string=} returnType
     * @param {Array=} argTypes
     * @param {Object=} opts
     */ var cwrap = (ident, returnType, argTypes, opts) => (...args) => ccall(ident, returnType, argTypes, args, opts);

// End JS library code
// include: postlibrary.js
// This file is included after the automatically-generated JS library code
// but before the wasm module is created.
{
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
  // If memory is defined in wasm, the user can't provide it, or set INITIAL_MEMORY
  assert(typeof Module["wasmMemory"] == "undefined", "Use of `wasmMemory` detected.  Use -sIMPORTED_MEMORY to define wasmMemory externally");
  assert(typeof Module["INITIAL_MEMORY"] == "undefined", "Detected runtime INITIAL_MEMORY setting.  Use -sIMPORTED_MEMORY to define wasmMemory dynamically");
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

Module["addOnPostRun"] = addOnPostRun;

Module["onPostRuns"] = onPostRuns;

Module["callRuntimeCallbacks"] = callRuntimeCallbacks;

Module["addOnPreRun"] = addOnPreRun;

Module["onPreRuns"] = onPreRuns;

Module["getValue"] = getValue;

Module["noExitRuntime"] = noExitRuntime;

Module["ptrToString"] = ptrToString;

Module["setValue"] = setValue;

Module["stackRestore"] = stackRestore;

Module["stackSave"] = stackSave;

Module["warnOnce"] = warnOnce;

Module["___assert_fail"] = ___assert_fail;

Module["UTF8ToString"] = UTF8ToString;

Module["UTF8ArrayToString"] = UTF8ArrayToString;

Module["UTF8Decoder"] = UTF8Decoder;

Module["findStringEnd"] = findStringEnd;

Module["___cxa_throw"] = ___cxa_throw;

Module["ExceptionInfo"] = ExceptionInfo;

Module["exceptionLast"] = exceptionLast;

Module["uncaughtExceptionCount"] = uncaughtExceptionCount;

Module["__abort_js"] = __abort_js;

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

Module["_emscripten_resize_heap"] = _emscripten_resize_heap;

Module["getHeapMax"] = getHeapMax;

Module["alignMemory"] = alignMemory;

Module["growMemory"] = growMemory;

Module["_exit"] = _exit;

Module["exitJS"] = exitJS;

Module["_proc_exit"] = _proc_exit;

Module["keepRuntimeAlive"] = keepRuntimeAlive;

Module["runtimeKeepaliveCounter"] = runtimeKeepaliveCounter;

Module["_fd_close"] = _fd_close;

Module["SYSCALLS"] = SYSCALLS;

Module["_fd_seek"] = _fd_seek;

Module["_fd_write"] = _fd_write;

Module["flush_NO_FILESYSTEM"] = flush_NO_FILESYSTEM;

Module["printChar"] = printChar;

Module["printCharBuffers"] = printCharBuffers;

Module["ccall"] = ccall;

Module["getCFunc"] = getCFunc;

Module["writeArrayToMemory"] = writeArrayToMemory;

Module["stringToUTF8OnStack"] = stringToUTF8OnStack;

Module["lengthBytesUTF8"] = lengthBytesUTF8;

Module["stringToUTF8"] = stringToUTF8;

Module["stringToUTF8Array"] = stringToUTF8Array;

Module["stackAlloc"] = stackAlloc;

Module["cwrap"] = cwrap;

// End JS library exports
// end include: postlibrary.js
function checkIncomingModuleAPI() {
  ignoredModuleProp("fetchSettings");
}

var ASM_CONSTS = {
  85724: ($0, $1, $2, $3, $4) => {
    if (typeof _wasmRecorderVisualizationCallback === "function") {
      _wasmRecorderVisualizationCallback($0, $1, $2, $3, $4);
    }
  },
  85850: ($0, $1, $2) => {
    const data = new Uint8Array(HEAPU8.subarray($0, $0 + $1));
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
  86520: () => {
    if (!RecorderModule.wasmWorker) {
      var workerUri = "assets/packages/flutter_recorder/web/worker.dart.js";
      RecorderModule.wasmWorker = new Worker(workerUri);
      console.log("EM_ASM creating web worker! " + workerUri + "  " + RecorderModule.wasmWorker);
    } else {
      console.log("EM_ASM web worker already created!");
    }
  },
  86834: ($0, $1, $2) => {
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
  87020: ($0, $1, $2) => {
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
  87283: ($0, $1, $2, $3, $4) => {
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
  89461: () => {
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
  89765: () => (navigator.mediaDevices !== undefined && navigator.mediaDevices.getUserMedia !== undefined),
  89869: () => {
    try {
      var temp = new (window.AudioContext || window.webkitAudioContext);
      var sampleRate = temp.sampleRate;
      temp.close();
      return sampleRate;
    } catch (e) {
      return 0;
    }
  },
  90040: ($0, $1, $2, $3, $4, $5) => {
    var deviceType = $0;
    var channels = $1;
    var sampleRate = $2;
    var bufferSize = $3;
    var pIntermediaryBuffer = $4;
    var pDevice = $5;
    if (typeof (window.miniaudio) === "undefined") {
      return -1;
    }
    var device = {};
    var audioContextOptions = {};
    if (deviceType == window.miniaudio.device_type.playback && sampleRate != 0) {
      audioContextOptions.sampleRate = sampleRate;
    }
    device.webaudio = new (window.AudioContext || window.webkitAudioContext)(audioContextOptions);
    device.webaudio.suspend();
    device.state = window.miniaudio.device_state.stopped;
    var channelCountIn = 0;
    var channelCountOut = channels;
    if (deviceType != window.miniaudio.device_type.playback) {
      channelCountIn = channels;
    }
    device.scriptNode = device.webaudio.createScriptProcessor(bufferSize, channelCountIn, channelCountOut);
    device.scriptNode.onaudioprocess = function(e) {
      if (device.intermediaryBufferView == null || device.intermediaryBufferView.length == 0) {
        device.intermediaryBufferView = new Float32Array(HEAPF32.buffer, pIntermediaryBuffer, bufferSize * channels);
      }
      if (deviceType == window.miniaudio.device_type.capture || deviceType == window.miniaudio.device_type.duplex) {
        for (var iChannel = 0; iChannel < channels; iChannel += 1) {
          var inputBuffer = e.inputBuffer.getChannelData(iChannel);
          var intermediaryBuffer = device.intermediaryBufferView;
          for (var iFrame = 0; iFrame < bufferSize; iFrame += 1) {
            intermediaryBuffer[iFrame * channels + iChannel] = inputBuffer[iFrame];
          }
        }
        _ma_device_process_pcm_frames_capture__webaudio(pDevice, bufferSize, pIntermediaryBuffer);
      }
      if (deviceType == window.miniaudio.device_type.playback || deviceType == window.miniaudio.device_type.duplex) {
        _ma_device_process_pcm_frames_playback__webaudio(pDevice, bufferSize, pIntermediaryBuffer);
        for (var iChannel = 0; iChannel < e.outputBuffer.numberOfChannels; ++iChannel) {
          var outputBuffer = e.outputBuffer.getChannelData(iChannel);
          var intermediaryBuffer = device.intermediaryBufferView;
          for (var iFrame = 0; iFrame < bufferSize; iFrame += 1) {
            outputBuffer[iFrame] = intermediaryBuffer[iFrame * channels + iChannel];
          }
        }
      } else {
        for (var iChannel = 0; iChannel < e.outputBuffer.numberOfChannels; ++iChannel) {
          e.outputBuffer.getChannelData(iChannel).fill(0);
        }
      }
    };
    if (deviceType == window.miniaudio.device_type.capture || deviceType == window.miniaudio.device_type.duplex) {
      navigator.mediaDevices.getUserMedia({
        audio: true,
        video: false
      }).then(function(stream) {
        device.streamNode = device.webaudio.createMediaStreamSource(stream);
        device.streamNode.connect(device.scriptNode);
        device.scriptNode.connect(device.webaudio.destination);
      }).catch(function(error) {
        console.log("Failed to get user media: " + error);
      });
    }
    if (deviceType == window.miniaudio.device_type.playback) {
      device.scriptNode.connect(device.webaudio.destination);
    }
    device.pDevice = pDevice;
    return window.miniaudio.track_device(device);
  },
  92917: $0 => window.miniaudio.get_device_by_index($0).webaudio.sampleRate,
  92990: $0 => {
    var device = window.miniaudio.get_device_by_index($0);
    if (device.scriptNode !== undefined) {
      device.scriptNode.onaudioprocess = function(e) {};
      device.scriptNode.disconnect();
      device.scriptNode = undefined;
    }
    if (device.streamNode !== undefined) {
      device.streamNode.disconnect();
      device.streamNode = undefined;
    }
    device.webaudio.close();
    device.webaudio = undefined;
    device.pDevice = undefined;
  },
  93390: $0 => {
    window.miniaudio.untrack_device_by_index($0);
  },
  93440: $0 => {
    var device = window.miniaudio.get_device_by_index($0);
    device.webaudio.resume();
    device.state = window.miniaudio.device_state.started;
  },
  93579: $0 => {
    var device = window.miniaudio.get_device_by_index($0);
    device.webaudio.suspend();
    device.state = window.miniaudio.device_state.stopped;
  },
  93719: ($0, $1, $2) => {
    const data = new Uint8Array(HEAPU8.subarray($0, $0 + $1));
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

var _flutter_recorder_setDartEventCallback = Module["_flutter_recorder_setDartEventCallback"] = makeInvalidEarlyAccess("_flutter_recorder_setDartEventCallback");

var _flutter_recorder_setDartVisualizationCallback = Module["_flutter_recorder_setDartVisualizationCallback"] = makeInvalidEarlyAccess("_flutter_recorder_setDartVisualizationCallback");

var _flutter_recorder_nativeFree = Module["_flutter_recorder_nativeFree"] = makeInvalidEarlyAccess("_flutter_recorder_nativeFree");

var _free = Module["_free"] = makeInvalidEarlyAccess("_free");

var _flutter_recorder_listCaptureDevices = Module["_flutter_recorder_listCaptureDevices"] = makeInvalidEarlyAccess("_flutter_recorder_listCaptureDevices");

var _malloc = Module["_malloc"] = makeInvalidEarlyAccess("_malloc");

var _flutter_recorder_freeListCaptureDevices = Module["_flutter_recorder_freeListCaptureDevices"] = makeInvalidEarlyAccess("_flutter_recorder_freeListCaptureDevices");

var _flutter_recorder_init = Module["_flutter_recorder_init"] = makeInvalidEarlyAccess("_flutter_recorder_init");

var _flutter_recorder_deinit = Module["_flutter_recorder_deinit"] = makeInvalidEarlyAccess("_flutter_recorder_deinit");

var _flutter_recorder_isInited = Module["_flutter_recorder_isInited"] = makeInvalidEarlyAccess("_flutter_recorder_isInited");

var _flutter_recorder_isDeviceStarted = Module["_flutter_recorder_isDeviceStarted"] = makeInvalidEarlyAccess("_flutter_recorder_isDeviceStarted");

var __Z33flutter_recorder_isCaptureStartedv = Module["__Z33flutter_recorder_isCaptureStartedv"] = makeInvalidEarlyAccess("__Z33flutter_recorder_isCaptureStartedv");

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

var _memcpy = Module["_memcpy"] = makeInvalidEarlyAccess("_memcpy");

var _memset = Module["_memset"] = makeInvalidEarlyAccess("_memset");

var _fflush = Module["_fflush"] = makeInvalidEarlyAccess("_fflush");

var _strerror = Module["_strerror"] = makeInvalidEarlyAccess("_strerror");

var _emscripten_stack_get_end = Module["_emscripten_stack_get_end"] = makeInvalidEarlyAccess("_emscripten_stack_get_end");

var _emscripten_stack_get_base = Module["_emscripten_stack_get_base"] = makeInvalidEarlyAccess("_emscripten_stack_get_base");

var _sbrk = Module["_sbrk"] = makeInvalidEarlyAccess("_sbrk");

var _emscripten_get_sbrk_ptr = Module["_emscripten_get_sbrk_ptr"] = makeInvalidEarlyAccess("_emscripten_get_sbrk_ptr");

var _emscripten_stack_init = Module["_emscripten_stack_init"] = makeInvalidEarlyAccess("_emscripten_stack_init");

var _emscripten_stack_get_free = Module["_emscripten_stack_get_free"] = makeInvalidEarlyAccess("_emscripten_stack_get_free");

var __emscripten_stack_restore = Module["__emscripten_stack_restore"] = makeInvalidEarlyAccess("__emscripten_stack_restore");

var __emscripten_stack_alloc = Module["__emscripten_stack_alloc"] = makeInvalidEarlyAccess("__emscripten_stack_alloc");

var _emscripten_stack_get_current = Module["_emscripten_stack_get_current"] = makeInvalidEarlyAccess("_emscripten_stack_get_current");

var memory = Module["memory"] = makeInvalidEarlyAccess("memory");

var __indirect_function_table = Module["__indirect_function_table"] = makeInvalidEarlyAccess("__indirect_function_table");

var wasmMemory = Module["wasmMemory"] = makeInvalidEarlyAccess("wasmMemory");

function assignWasmExports(wasmExports) {
  assert(typeof wasmExports["flutter_recorder_createWorkerInWasm"] != "undefined", "missing Wasm export: flutter_recorder_createWorkerInWasm");
  assert(typeof wasmExports["_Z41flutter_recorder_sendSilenceEventToWorkerPKcbf"] != "undefined", "missing Wasm export: _Z41flutter_recorder_sendSilenceEventToWorkerPKcbf");
  assert(typeof wasmExports["_Z35flutter_recorder_sendStreamToWorkerPKcPKhi"] != "undefined", "missing Wasm export: _Z35flutter_recorder_sendStreamToWorkerPKcPKhi");
  assert(typeof wasmExports["flutter_recorder_setDartEventCallback"] != "undefined", "missing Wasm export: flutter_recorder_setDartEventCallback");
  assert(typeof wasmExports["flutter_recorder_setDartVisualizationCallback"] != "undefined", "missing Wasm export: flutter_recorder_setDartVisualizationCallback");
  assert(typeof wasmExports["flutter_recorder_nativeFree"] != "undefined", "missing Wasm export: flutter_recorder_nativeFree");
  assert(typeof wasmExports["free"] != "undefined", "missing Wasm export: free");
  assert(typeof wasmExports["flutter_recorder_listCaptureDevices"] != "undefined", "missing Wasm export: flutter_recorder_listCaptureDevices");
  assert(typeof wasmExports["malloc"] != "undefined", "missing Wasm export: malloc");
  assert(typeof wasmExports["flutter_recorder_freeListCaptureDevices"] != "undefined", "missing Wasm export: flutter_recorder_freeListCaptureDevices");
  assert(typeof wasmExports["flutter_recorder_init"] != "undefined", "missing Wasm export: flutter_recorder_init");
  assert(typeof wasmExports["flutter_recorder_deinit"] != "undefined", "missing Wasm export: flutter_recorder_deinit");
  assert(typeof wasmExports["flutter_recorder_isInited"] != "undefined", "missing Wasm export: flutter_recorder_isInited");
  assert(typeof wasmExports["flutter_recorder_isDeviceStarted"] != "undefined", "missing Wasm export: flutter_recorder_isDeviceStarted");
  assert(typeof wasmExports["_Z33flutter_recorder_isCaptureStartedv"] != "undefined", "missing Wasm export: _Z33flutter_recorder_isCaptureStartedv");
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
  assert(typeof wasmExports["memcpy"] != "undefined", "missing Wasm export: memcpy");
  assert(typeof wasmExports["memset"] != "undefined", "missing Wasm export: memset");
  assert(typeof wasmExports["fflush"] != "undefined", "missing Wasm export: fflush");
  assert(typeof wasmExports["strerror"] != "undefined", "missing Wasm export: strerror");
  assert(typeof wasmExports["emscripten_stack_get_end"] != "undefined", "missing Wasm export: emscripten_stack_get_end");
  assert(typeof wasmExports["emscripten_stack_get_base"] != "undefined", "missing Wasm export: emscripten_stack_get_base");
  assert(typeof wasmExports["sbrk"] != "undefined", "missing Wasm export: sbrk");
  assert(typeof wasmExports["emscripten_get_sbrk_ptr"] != "undefined", "missing Wasm export: emscripten_get_sbrk_ptr");
  assert(typeof wasmExports["emscripten_stack_init"] != "undefined", "missing Wasm export: emscripten_stack_init");
  assert(typeof wasmExports["emscripten_stack_get_free"] != "undefined", "missing Wasm export: emscripten_stack_get_free");
  assert(typeof wasmExports["_emscripten_stack_restore"] != "undefined", "missing Wasm export: _emscripten_stack_restore");
  assert(typeof wasmExports["_emscripten_stack_alloc"] != "undefined", "missing Wasm export: _emscripten_stack_alloc");
  assert(typeof wasmExports["emscripten_stack_get_current"] != "undefined", "missing Wasm export: emscripten_stack_get_current");
  assert(typeof wasmExports["memory"] != "undefined", "missing Wasm export: memory");
  assert(typeof wasmExports["__indirect_function_table"] != "undefined", "missing Wasm export: __indirect_function_table");
  _flutter_recorder_createWorkerInWasm = Module["_flutter_recorder_createWorkerInWasm"] = createExportWrapper("flutter_recorder_createWorkerInWasm", 0);
  __Z41flutter_recorder_sendSilenceEventToWorkerPKcbf = Module["__Z41flutter_recorder_sendSilenceEventToWorkerPKcbf"] = createExportWrapper("_Z41flutter_recorder_sendSilenceEventToWorkerPKcbf", 3);
  __Z35flutter_recorder_sendStreamToWorkerPKcPKhi = Module["__Z35flutter_recorder_sendStreamToWorkerPKcPKhi"] = createExportWrapper("_Z35flutter_recorder_sendStreamToWorkerPKcPKhi", 3);
  _flutter_recorder_setDartEventCallback = Module["_flutter_recorder_setDartEventCallback"] = createExportWrapper("flutter_recorder_setDartEventCallback", 2);
  _flutter_recorder_setDartVisualizationCallback = Module["_flutter_recorder_setDartVisualizationCallback"] = createExportWrapper("flutter_recorder_setDartVisualizationCallback", 1);
  _flutter_recorder_nativeFree = Module["_flutter_recorder_nativeFree"] = createExportWrapper("flutter_recorder_nativeFree", 1);
  _free = Module["_free"] = createExportWrapper("free", 1);
  _flutter_recorder_listCaptureDevices = Module["_flutter_recorder_listCaptureDevices"] = createExportWrapper("flutter_recorder_listCaptureDevices", 4);
  _malloc = Module["_malloc"] = createExportWrapper("malloc", 1);
  _flutter_recorder_freeListCaptureDevices = Module["_flutter_recorder_freeListCaptureDevices"] = createExportWrapper("flutter_recorder_freeListCaptureDevices", 4);
  _flutter_recorder_init = Module["_flutter_recorder_init"] = createExportWrapper("flutter_recorder_init", 6);
  _flutter_recorder_deinit = Module["_flutter_recorder_deinit"] = createExportWrapper("flutter_recorder_deinit", 0);
  _flutter_recorder_isInited = Module["_flutter_recorder_isInited"] = createExportWrapper("flutter_recorder_isInited", 0);
  _flutter_recorder_isDeviceStarted = Module["_flutter_recorder_isDeviceStarted"] = createExportWrapper("flutter_recorder_isDeviceStarted", 0);
  __Z33flutter_recorder_isCaptureStartedv = Module["__Z33flutter_recorder_isCaptureStartedv"] = createExportWrapper("_Z33flutter_recorder_isCaptureStartedv", 0);
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
  _memcpy = Module["_memcpy"] = createExportWrapper("memcpy", 3);
  _memset = Module["_memset"] = createExportWrapper("memset", 3);
  _fflush = Module["_fflush"] = createExportWrapper("fflush", 1);
  _strerror = Module["_strerror"] = createExportWrapper("strerror", 1);
  _emscripten_stack_get_end = Module["_emscripten_stack_get_end"] = wasmExports["emscripten_stack_get_end"];
  _emscripten_stack_get_base = Module["_emscripten_stack_get_base"] = wasmExports["emscripten_stack_get_base"];
  _sbrk = Module["_sbrk"] = createExportWrapper("sbrk", 1);
  _emscripten_get_sbrk_ptr = Module["_emscripten_get_sbrk_ptr"] = wasmExports["emscripten_get_sbrk_ptr"];
  _emscripten_stack_init = Module["_emscripten_stack_init"] = wasmExports["emscripten_stack_init"];
  _emscripten_stack_get_free = Module["_emscripten_stack_get_free"] = wasmExports["emscripten_stack_get_free"];
  __emscripten_stack_restore = Module["__emscripten_stack_restore"] = wasmExports["_emscripten_stack_restore"];
  __emscripten_stack_alloc = Module["__emscripten_stack_alloc"] = wasmExports["_emscripten_stack_alloc"];
  _emscripten_stack_get_current = Module["_emscripten_stack_get_current"] = wasmExports["emscripten_stack_get_current"];
  memory = Module["memory"] = wasmMemory = wasmExports["memory"];
  __indirect_function_table = Module["__indirect_function_table"] = wasmExports["__indirect_function_table"];
}

var wasmImports = {
  /** @export */ __assert_fail: ___assert_fail,
  /** @export */ __cxa_throw: ___cxa_throw,
  /** @export */ _abort_js: __abort_js,
  /** @export */ alignfault,
  /** @export */ clock_time_get: _clock_time_get,
  /** @export */ emscripten_asm_const_int: _emscripten_asm_const_int,
  /** @export */ emscripten_date_now: _emscripten_date_now,
  /** @export */ emscripten_get_now: _emscripten_get_now,
  /** @export */ emscripten_resize_heap: _emscripten_resize_heap,
  /** @export */ exit: _exit,
  /** @export */ fd_close: _fd_close,
  /** @export */ fd_seek: _fd_seek,
  /** @export */ fd_write: _fd_write,
  /** @export */ segfault
};

// include: postamble.js
// === Auto-generated postamble setup entry stuff ===
var calledRun;

function stackCheckInit() {
  // This is normally called automatically during __wasm_call_ctors but need to
  // get these values before even running any of the ctors so we call it redundantly
  // here.
  _emscripten_stack_init();
  // TODO(sbc): Move writeStackCookie to native to to avoid this.
  writeStackCookie();
}

function run() {
  stackCheckInit();
  preRun();
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

// In modularize mode the generated code is within a factory function so we
// can use await here (since it's not top-level-await).
wasmExports = await (createWasm());

run();

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

