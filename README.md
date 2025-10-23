It extracts ARIB STD-B69 subtitle from 4K/8K TV Program and converts it to Advanced SubStation Alpha (ASS) file.

从 4K/8K 电视节目中提取 ARIB STD-B69 字幕并将其转换为 Advanced SubStation Alpha (ASS) 文件。

## Building

### Turn-key build (bundled FFmpeg + Expat sources)

The default CMake configuration downloads the FFmpeg and Expat source trees and
builds the exact libraries required by **bs4kass**. As long as you can compile
C99 code and provide the basic toolchain required by FFmpeg, no pre-installed
dependencies are needed.

1. Install the tools required by FFmpeg
   * **Linux/macOS** – `gcc`/`clang`, `make`, `pkg-config`, and `nasm`.
   * **Windows (MSVC)** – Visual Studio (build tools), Git for Windows (for
     `bash`), NASM, and Perl. See [Windows preparation](#windows-preparation)
     for the recommended setup steps.
2. Configure and build:

   ```
   cmake -S . -B build
   cmake --build build
   ```

CMake will clone FFmpeg (tag `n6.1.1` by default), compile it with a
minimal feature set and link it together with a statically built Expat. The
artifacts are stored under `build/ffmpeg/install/` so repeated builds reuse the
previous results.

Useful cache variables when working with the bundled flow:

| Cache entry | Description |
| --- | --- |
| `BS4KASS_FFMPEG_TAG` | FFmpeg git tag/commit to checkout when downloading automatically. |
| `BS4KASS_FFMPEG_SOURCE` | Points at an existing FFmpeg checkout if you already have the sources locally. |

### Windows preparation

On a clean Windows installation you only need to follow these steps once. They
ensure the automatic FFmpeg/Expat builds have every tool they expect.

1. **Install Visual Studio Build Tools (or Visual Studio)** with the "Desktop
   development with C++" workload and the latest Windows 10/11 SDK.
2. **Install Git for Windows** and keep the default option that adds `bash.exe`
   to the `PATH` environment variable.
3. **Install NASM** (download the Windows installer from
   <https://www.nasm.us/>) and enable "Add to PATH" during setup.
4. **Install Perl** (for example via Strawberry Perl at
   <https://strawberryperl.com/>) so FFmpeg's configure scripts can run.
5. Open the "x64 Native Tools Command Prompt for VS" (or any *Developer
   Command Prompt*) so that `cl.exe` and `nmake.exe` are configured.
6. In the same prompt verify that the required tools are visible:

   ```bat
   cl
   nmake /?
   bash --version
   perl -v
   nasm -v
   ```

   The commands do not need to build anything yet—they just confirm the tools
   are on `PATH`. If any of them fails, fix the installation before proceeding.
7. Configure and build the project from that prompt:

   ```bat
   cmake -S . -B build
   cmake --build build
   ```

   CMake automatically drives the bundled FFmpeg/Expat build with `nmake`. If
   you prefer another generator (for example Ninja) pass `-G "Ninja"` and make
   sure the corresponding tool is installed.

### Windows 构建准备

在全新安装的 Windows 环境里，只需按以下步骤执行一次，就能确保自动构建
FFmpeg/Expat 时所需的所有工具都已准备就绪：

1. **安装 Visual Studio Build Tools（或完整的 Visual Studio）**，并勾选“使用
   C++ 的桌面开发”工作负载，同时安装最新的 Windows 10/11 SDK。
2. **安装 Git for Windows**，保留默认选项，让安装程序把 `bash.exe` 添加到
   `PATH` 环境变量中。
3. **安装 NASM**（可从 <https://www.nasm.us/> 下载 Windows 安装包），在安装
   过程中勾选“Add to PATH”。
4. **安装 Perl**（例如安装 Strawberry Perl：<https://strawberryperl.com/>），
   以便 FFmpeg 的配置脚本能够运行。
5. 打开“x64 Native Tools Command Prompt for VS”（或任意 *Developer Command
   Prompt*），确保 `cl.exe` 和 `nmake.exe` 已经就绪。
6. 在同一个命令提示符里确认这些工具都能被找到：

   ```bat
   cl
   nmake /?
   bash --version
   perl -v
   nasm -v
   ```

   这些命令不需要真正编译任何东西，只要能够正确输出版本信息，就说明工具
   已经加入 `PATH`。如果有命令失败，请先修复对应的安装。
7. 在该命令提示符中配置并构建本项目：

   ```bat
   cmake -S . -B build
   cmake --build build
   ```

   CMake 会自动使用 `nmake` 构建随附的 FFmpeg 和 Expat。如果你更喜欢其他
   生成器（例如 Ninja），可以额外传入 `-G "Ninja"`，同时确保相关工具已
   正确安装。

### Using system packages instead

If you prefer the traditional approach where FFmpeg and Expat are provided by
your system, set `BS4KASS_USE_SYSTEM_LIBS=ON` when configuring CMake. Example:

```
cmake -S . -B build -DBS4KASS_USE_SYSTEM_LIBS=ON
cmake --build build
```

When this option is enabled CMake falls back to locating the libraries in the
environment. On Windows you can still hint at a local FFmpeg build through the
`FFMPEG_ROOT` environment variable (or the `_ffmpeg_root_hint` cache variable).
