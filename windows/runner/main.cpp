#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <shellapi.h>
#include <windows.h>

#include <string>
#include <vector>

#include "flutter_window.h"
#include "utils.h"

namespace {

constexpr wchar_t kSingleInstanceMutexName[] =
  L"Anoxia.NotePadClient.SingleInstance";
constexpr ULONG_PTR kAnoxiaUriCopyDataId = 0x414E4F58;  // 'ANOX'

void RegisterAnoxiaProtocol() {
  wchar_t exe_path[MAX_PATH];
  const DWORD path_len = GetModuleFileNameW(nullptr, exe_path, MAX_PATH);
  if (path_len == 0 || path_len >= MAX_PATH) {
    return;
  }

  HKEY hkey = nullptr;
  const wchar_t* protocol_key = L"Software\\Classes\\anoxia";
  if (RegCreateKeyExW(HKEY_CURRENT_USER, protocol_key, 0, nullptr, 0,
                      KEY_SET_VALUE | KEY_CREATE_SUB_KEY, nullptr, &hkey,
                      nullptr) != ERROR_SUCCESS) {
    return;
  }

  const std::wstring protocol_name = L"URL:Anoxia Protocol";
  RegSetValueExW(hkey, nullptr, 0, REG_SZ,
                 reinterpret_cast<const BYTE*>(protocol_name.c_str()),
                 static_cast<DWORD>((protocol_name.size() + 1) * sizeof(wchar_t)));

  const wchar_t empty_value[] = L"";
  RegSetValueExW(hkey, L"URL Protocol", 0, REG_SZ,
                 reinterpret_cast<const BYTE*>(empty_value),
                 static_cast<DWORD>(sizeof(empty_value)));

  HKEY command_key = nullptr;
  if (RegCreateKeyExW(hkey, L"shell\\open\\command", 0, nullptr, 0,
                      KEY_SET_VALUE, nullptr, &command_key,
                      nullptr) == ERROR_SUCCESS) {
    const std::wstring command =
        L"\"" + std::wstring(exe_path) + L"\" \"%1\"";
    RegSetValueExW(command_key, nullptr, 0, REG_SZ,
                   reinterpret_cast<const BYTE*>(command.c_str()),
                   static_cast<DWORD>((command.size() + 1) * sizeof(wchar_t)));
    RegCloseKey(command_key);
  }

  RegCloseKey(hkey);
}

HWND FindExistingMainWindow() {
  return FindWindowW(nullptr, L"notepadclient");
}

void ActivateExistingMainWindow() {
  HWND hwnd = FindExistingMainWindow();
  if (!hwnd) {
    return;
  }

  if (IsIconic(hwnd)) {
    ShowWindow(hwnd, SW_RESTORE);
  }

  ShowWindow(hwnd, SW_SHOW);
  SetForegroundWindow(hwnd);
}

std::wstring GetLaunchUriArgument() {
  int argc = 0;
  LPWSTR* argv = CommandLineToArgvW(GetCommandLineW(), &argc);
  if (!argv) {
    return L"";
  }

  std::wstring uri;
  for (int i = 1; i < argc; ++i) {
    const std::wstring arg = argv[i] ? argv[i] : L"";
    if (arg.rfind(L"anoxia://", 0) == 0) {
      uri = arg;
      break;
    }
  }

  LocalFree(argv);
  return uri;
}

void ForwardUriToExistingInstance(HWND hwnd, const std::wstring& uri) {
  if (!hwnd || uri.empty()) {
    return;
  }

  COPYDATASTRUCT cds{};
  cds.dwData = kAnoxiaUriCopyDataId;
  cds.cbData = static_cast<DWORD>((uri.size() + 1) * sizeof(wchar_t));
  cds.lpData = const_cast<wchar_t*>(uri.c_str());
  SendMessageW(hwnd, WM_COPYDATA, 0, reinterpret_cast<LPARAM>(&cds));
}

}  // namespace

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

  HANDLE single_instance_mutex =
      CreateMutexW(nullptr, TRUE, kSingleInstanceMutexName);
  if (single_instance_mutex != nullptr && GetLastError() == ERROR_ALREADY_EXISTS) {
    HWND hwnd = FindExistingMainWindow();
    ActivateExistingMainWindow();
    ForwardUriToExistingInstance(hwnd, GetLaunchUriArgument());
    CloseHandle(single_instance_mutex);
    ::CoUninitialize();
    return EXIT_SUCCESS;
  }

  // Register anoxia:// protocol for browser-to-app return flow.
  RegisterAnoxiaProtocol();

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"notepadclient", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  if (single_instance_mutex != nullptr) {
    ReleaseMutex(single_instance_mutex);
    CloseHandle(single_instance_mutex);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
