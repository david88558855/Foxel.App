#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "app_messages.h"
#include "flutter_window.h"
#include "utils.h"

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  // 单实例：主窗口启动即隐藏后，重复双击不会给出任何视觉反馈，
  // 容易开出多个实例并同时写 userdata/prefs.json（后写覆盖前写）。
  // 第二个实例只负责把已有实例的主窗口唤到前台，然后立即退出。
  // 命名放在 Local\ 下：多用户 / 远程桌面各自独立。
  HANDLE instance_mutex =
      ::CreateMutexW(nullptr, TRUE, L"Local\\Foxel.App.SingleInstance");
  if (instance_mutex != nullptr && ::GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND existing = ::FindWindowW(nullptr, kWindowTitle);
    if (existing != nullptr) {
      DWORD owner_pid = 0;
      ::GetWindowThreadProcessId(existing, &owner_pid);
      // 允许目标进程抢前台，否则它的 SetForegroundWindow 会被系统驳回。
      ::AllowSetForegroundWindow(owner_pid);
      ::PostMessageW(existing, kShowWindowMessage, 0, 0);
    }
    ::CloseHandle(instance_mutex);
    ::CoUninitialize();
    return EXIT_SUCCESS;
  }

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(kWindowTitle, origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  if (instance_mutex != nullptr) {
    ::CloseHandle(instance_mutex);
  }
  return EXIT_SUCCESS;
}
