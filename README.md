## deployqtwin

Finalize distributable as alternative to *windeployqt*.

:construction: *alpha* :construction:

The main difference with *windeployqt* is the absence of dependency resolver. Dependencies are listed within the script.

> [!TIP]
> The script has a **simulation mode**, to try all the actions without write any files

> [!IMPORTANT]
> This script does not has key features of *windeployqt* distribuited with Qt, for example dependency resolver and deploy of qml, translations, etc. You should provide your own routine to deploy qml, translations, etc.

By default it looks for Qt installed via *MSYS2* inside default paths or in cross-compiler way inside `/usr/x86_64-w64-mingw32` or `/usr/i686-w64-mingw32`

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
| -system | Set build system architecture \[MINGW64\] |
| -qt-version | Set Qt version \[6\] |
| -modules | Modules to deploy (Core Gui Widgets) |
| -plugins | Plugins to deploy (platforms styles) |
| -libraries | Append libraries to deploy () |
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
module: Core  as: Qt6Core
copy: Qt6Core.dll  to: built/Qt6Core.dll
  copy file from "/path/to/qt/lib/Qt6Core.dll" to "/path/to/user/repo/built/Qt6Core.dll"
  copy file from "/path/to/mingw64/bin/libharfbuzz-0.dll" to "/path/to/user/repo/built/libharfbuzz-0.dll"
  copy file from "/path/to/mingw64/bin/libiconv-2.dll" to "/path/to/user/repo/built/libintl-8.dll"
  copy file from "/path/to/mingw64/bin/libintl-8.dll" to "/path/to/user/repo/built/libintl-8.dll"
  copy file from "/path/to/mingw64/bin/libwinpthread-1.dll" to "/path/to/user/repo/built/libwinpthread-1.dll"
[...]
plugin: platforms
copy: platforms  to: built/platforms
  copy file from "/path/to/qt/plugins/platforms" to "/path/to/user/repo/built/platforms"
[...]
```

&nbsp;

### License

Source code licensed under the terms of the [MIT License](https://github.com/e2se/deployqtwin/blob/main/LICENSE-MIT).

It is also licensed under the terms of the [GNU GPLv3](https://github.com/e2se/deployqtwin/blob/main/LICENSE-GPL-3.0-or-later).

