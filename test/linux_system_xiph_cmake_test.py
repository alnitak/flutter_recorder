"""Build the CMake plugin without any vendored Linux libraries or headers.

Requires CMake, a C++ compiler and Ogg/Opus/SpeexDSP development packages.
Run with: python3 test/linux_system_xiph_cmake_test.py
"""

from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


class SystemXiphTest(unittest.TestCase):
    def test_system_build_does_not_require_or_bundle_prebuilts(self):
        package = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory(prefix='recorder system Xiph ') as directory:
            root = Path(directory)
            source = root / 'source'
            source.mkdir()
            shutil.copytree(package / 'src', source / 'src')
            (source / 'linux').mkdir()
            shutil.copy2(package / 'linux/CMakeLists.txt', source / 'linux')
            (source / 'CMakeLists.txt').write_text('''
cmake_minimum_required(VERSION 3.10)
project(recorder_system_test LANGUAGES C CXX)
add_subdirectory(linux)
file(GENERATE OUTPUT "${CMAKE_BINARY_DIR}/bundled-libraries.txt"
  CONTENT "$<JOIN:${flutter_recorder_bundled_libraries},\\n>")
''')
            build = root / 'build'
            subprocess.run(['cmake', '-S', source, '-B', build,
                            '-DFLUTTER_RECORDER_USE_SYSTEM_XIPH=ON'], check=True)
            subprocess.run(['cmake', '--build', build, '--parallel', '2'], check=True)
            libraries = (build / 'bundled-libraries.txt').read_text().splitlines()
            self.assertEqual(len(libraries), 1)
            library = root / 'libflutter_recorder.so'
            shutil.copy2(libraries[0], library)
            shutil.rmtree(build)
            shutil.rmtree(source)
            subprocess.run([sys.executable, '-c', '''
import ctypes, sys
library = ctypes.CDLL(sys.argv[1])
assert library.flutter_recorder_isInited() == 0
''', str(library)], check=True)


if __name__ == '__main__':
    unittest.main()
