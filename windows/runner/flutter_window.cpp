#include "flutter_window.h"

#include <windows.h>

#include <optional>
#include <string>

#include "app_messages.h"
#include "flutter/generated_plugin_registrant.h"

namespace {

// 首次启动提示只需出现一次：在 userdata 下留一个标记文件。
// 沿用便携版语义 —— 删掉程序目录即恢复"首次启动"。
bool ShouldShowFirstRunHint() {
  wchar_t exe_path[MAX_PATH] = {};
  const DWORD length =
      ::GetModuleFileNameW(nullptr, exe_path, static_cast<DWORD>(MAX_PATH));
  if (length == 0 || length >= static_cast<DWORD>(MAX_PATH)) {
    return false;
  }

  std::wstring directory(exe_path, length);
  const size_t separator = directory.find_last_of(L"\\/");
  if (separator == std::wstring::npos) {
    return false;
  }
  directory.erase(separator);
  directory += L"\\userdata";
  ::CreateDirectoryW(directory.c_str(), nullptr);  // 已存在时会失败，忽略

  const std::wstring marker = directory + L"\\.tray-hint-shown";
  // CREATE_NEW：只有第一次能创建成功，之后必然失败。
  HANDLE file = ::CreateFileW(marker.c_str(), GENERIC_WRITE, 0, nullptr,
                              CREATE_NEW, FILE_ATTRIBUTE_NORMAL, nullptr);
  if (file == INVALID_HANDLE_VALUE) {
    // 已存在 → 不是首次；其他错误（只读目录等）→ 宁可不提示，避免每次启动都弹。
    return false;
  }
  ::CloseHandle(file);
  return true;
}

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  // 托盘常驻：启动即隐藏。模板此处原本是
  //   SetNextFrameCallback([&]() { this->Show(); });
  // 它会让窗口在首帧后自动出现，是"启动会弹窗"的唯一原因，因此不再注册。
  // 主窗口此后只由托盘菜单「显示主窗口」或第二实例唤起。
  // ForceRedraw 保留：先让引擎渲染一帧，后续显示时无需再等首帧。
  flutter_controller_->ForceRedraw();

  tray_.SetHandlers([this]() { ShowMainWindow(); }, [this]() { QuitApp(); });
  if (!tray_.Create(GetHandle(), kTrayCallbackMessage, kWindowTitle)) {
    // 托盘挂载失败就完全没有入口（窗口是隐藏的），此时直接回退为显示窗口，
    // 宁可违反"启动即隐藏"，也不能让用户面对一个看不见、点不到的进程。
    ShowMainWindow();
    return true;
  }

  // 启动即隐藏后没有任何视觉反馈，首次运行时提示一次"我在托盘"。
  if (ShouldShowFirstRunHint()) {
    tray_.ShowBalloon(L"Foxel", L"已在系统托盘运行，右键托盘图标可显示主窗口。");
  }

  return true;
}

void FlutterWindow::OnDestroy() {
  // 兜底：无论从哪条路径销毁窗口，都先把托盘图标摘掉。
  tray_.Dispose();

  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

void FlutterWindow::ShowMainWindow() {
  HWND hwnd = GetHandle();
  if (hwnd == nullptr) {
    return;
  }

  // 托盘恢复时窗口可能处于隐藏或最小化状态，两种都要处理。
  ::ShowWindow(hwnd, ::IsIconic(hwnd) ? SW_RESTORE : SW_SHOW);
  ::SetForegroundWindow(hwnd);
  if (flutter_controller_) {
    flutter_controller_->ForceRedraw();
  }
  // 不擦背景（FALSE），避免出现一帧白底。
  ::InvalidateRect(hwnd, nullptr, FALSE);
}

void FlutterWindow::HideMainWindow() {
  HWND hwnd = GetHandle();
  if (hwnd != nullptr) {
    ::ShowWindow(hwnd, SW_HIDE);
  }
}

void FlutterWindow::QuitApp() {
  if (quitting_) {
    return;
  }
  quitting_ = true;

  // 顺序关键：先摘托盘图标，再销毁窗口，否则任务栏残留幽灵图标。
  tray_.Dispose();

  HWND hwnd = GetHandle();
  if (hwnd != nullptr) {
    // WM_DESTROY → PostQuitMessage(0)，消息循环结束后进程退出。
    ::DestroyWindow(hwnd);
  }
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // 托盘回调与第二实例唤起属于 runner 自己的消息，先于引擎处理。
  if (message == kTrayCallbackMessage) {
    tray_.HandleCallback(wparam, lparam);
    return 0;
  }
  if (message == kShowWindowMessage) {
    ShowMainWindow();
    return 0;
  }
  // 资源管理器重启后重新挂载图标，否则图标会永久消失。
  if (tray_.IsTaskbarCreatedMessage(message)) {
    tray_.ReAdd();
    return 0;
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
    case WM_CLOSE:
      // 关闭主界面只收进托盘：隐藏而非销毁，进程与 Flutter 引擎继续运行。
      // 唯一的真退出路径是托盘菜单「退出」（见 QuitApp）。
      if (!quitting_) {
        HideMainWindow();
        return 0;
      }
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
