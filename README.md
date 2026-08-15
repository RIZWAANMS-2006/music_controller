# Rusic - Music Player

## Desktop build notes

The Linux desktop build expects a working C++ toolchain and linker. If CMake reports that it cannot find `ld` or `ld.lld`, install the system linker package for your distribution and then run `flutter clean` before rebuilding.

### Linux Requirements (SQLite)
The application requires SQLite for its local database to function. If you encounter a black screen on startup on Linux, you need to install the `libsqlite3-dev` package. 

Run the following command on Debian/Ubuntu-based distributions:
```bash
sudo apt-get update && sudo apt-get install -y libsqlite3-dev
```

Inside VS Code, the workspace terminal prepends `toolchain/linux/bin` to `PATH` so the local shims can satisfy the native asset build on Linux.

