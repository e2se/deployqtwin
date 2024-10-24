## deployqtwin

Finalize distributable as alternative to *windeployqt*.

The main difference with *windeployqt* is the absence of dependency resolver. Dependencies are listed within the script.

> [!TIP]
> The script has a **simulation mode**, to try all the actions without write any files

> [!IMPORTANT]
> This script does not has key features of *windeployqt* distribuited with Qt, for example dependency resolver and deploy of qml, translations, etc. You should provide your own routine to deploy qml, translations, etc.

By default it looks for Qt installed via *MSYS2* inside default paths.

`-environment` system environment values are: MSYS

`-system` system architecture values are: MINGW64, MINGW32, UCRT64, CLANG64, CLANG32, CLANGARM64, MSVC

**It requires `bash` and a POSIX compliant sub-system**


## Usage

`bash deployqtwin.sh binary.exe [OPTIONS]`

| Options |  |
| ------- | - |
| --verbose | Verbose |
| -s --simulate | Simulate actions without write files |
| -f --force | Force overwrite of files |
| -o --dest-path | Set a destination path instead of binary directory |
| -np --no-deploy-plugins | Disallow plugins deploy |
| -environment | Set system environment \[MSYS\] |
| -system | Set system architecture \[MINGW64\] |
| -qt-version | Set Qt version \[6.x.x\] |
| -modules | Modules to deploy (Core,Gui,Widgets) |
| -plugins | Plugins to deploy (platforms,styles) |
| -libraries | Append libraries to deploy () |
| -lib-path | Set system environment lib path |
| -qt-path | Set Qt path |
| -framework-path | Set Qt framework path |
| -plugins-path | Set Qt plugins path |
| -h --help | Display this help and exit |


## Example

An example of the script ran with `--verbose` and `--simulate` using your Qt path passed to `-qtpath`
```
chmod +x deployqtwin.sh

./deployqtwin.sh built/binary.exe --verbose --simulate -qtpath /path/to/qt &> log
```

Produces this output:
```
executable: /path/to/user/repo/built/binary.exe
system: MINGW64
module: Core  as: Qt6Core
copy: Qt6Core.dll  to: built/Qt6Core.dll
  copy file from "/path/to/qt/bin/Qt6Core.dll" to "/path/to/user/repo/built/Qt6Core.dll"
dependency: libgcc_s_seh-1.dll
  copy file from "/path/to/mingw64/bin/libgcc_s_seh-1.dll" to "/path/to/user/repo/built/libgcc_s_seh-1.dll"
dependency: libstdc++-6.dll
  copy file from "/path/to/mingw64/bin/libstdc++-6.dll" to "/path/to/user/repo/built/libstdc++-6.dll"
dependency: libwinpthread-1.dll
  copy file from "/path/to/mingw64/bin/libwinpthread-1.dll" to "/path/to/user/repo/built/libwinpthread-1.dll"
dependency: libpcre2-16-0.dll
  copy file from "/path/to/mingw64/bin/libpcre2-16-0.dll" to "/path/to/user/repo/built/libpcre2-16-0.dll"
dependency: libssp-0.dll
  copy file from "/path/to/mingw64/bin/libssp-0.dll" to "/path/to/user/repo/built/libssp-0.dll"
dependency: libzstd.dll
  copy file from "/path/to/mingw64/bin/libzstd.dll" to "/path/to/user/repo/built/libzstd.dll"
dependency: zlib1.dll
  copy file from "/path/to/mingw64/bin/zlib1.dll" to "/path/to/user/repo/built/zlib1.dll"
module: Gui  as: Qt6Gui
no overwrite: Qt6Gui.dll  already at: built/Qt6Gui.dll
dependency: libbrotlicommon.dll
no overwrite: libbrotlicommon.dll  already at: built/libbrotlicommon.dll
dependency: libbrotlidec.dll
no overwrite: libbrotlidec.dll  already at: built/libbrotlidec.dll
dependency: libbz2-1.dll
no overwrite: libbz2-1.dll  already at: built/libbz2-1.dll
[...]
plugin: platforms
copy: platforms  to: built/platforms
  copy directory from "/path/to/qt/plugins/platforms" to "/path/to/user/repo/built/platforms"
[...]
```

&nbsp;

### License

Source code licensed under the terms of the [MIT License](https://github.com/e2se/deployqtwin/blob/main/LICENSE-MIT).

It is also licensed under the terms of the [GNU GPLv3](https://github.com/e2se/deployqtwin/blob/main/LICENSE-GPL-3.0-or-later).

