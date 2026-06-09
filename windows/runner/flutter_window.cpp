#include "flutter_window.h"

#include <optional>
#include <string>

#include "flutter/generated_plugin_registrant.h"
#include "desktop_multi_window/desktop_multi_window_plugin.h"

namespace {
constexpr ULONG_PTR kAnoxiaUriCopyDataId = 0x414E4F58;  // 'ANOX'

std::string WideToUtf8(const std::wstring &input) {
    if (input.empty()) {
        return "";
    }

    const int required = WideCharToMultiByte(
            CP_UTF8, 0, input.c_str(), -1, nullptr, 0, nullptr, nullptr);
    if (required <= 1) {
        return "";
    }

    std::string output(required - 1, '\0');
    WideCharToMultiByte(
            CP_UTF8, 0, input.c_str(), -1, output.data(), required, nullptr,
            nullptr);
    return output;
}
} // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject &project)
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
    DesktopMultiWindowSetWindowCreatedCallback([](void *controller) {
        auto *flutter_view_controller =
                +reinterpret_cast<flutter::FlutterViewController *>(controller);
        auto *registry = flutter_view_controller->engine();
        RegisterPlugins(registry);
    });
    SetChildContent(flutter_controller_->view()->GetNativeWindow());

        register_return_channel_ =
            std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
                flutter_controller_->engine()->messenger(),
                "anoxia/register_return",
                &flutter::StandardMethodCodec::GetInstance());

    flutter_controller_->engine()->SetNextFrameCallback([&]() {
        this->Show();
    });

    // Flutter can complete the first frame before the "show window" callback is
    // registered. The following call ensures a frame is pending to ensure the
    // window is shown. It is a no-op if the first frame hasn't completed yet.
    flutter_controller_->ForceRedraw();

    return true;
}

void FlutterWindow::OnDestroy() {
    register_return_channel_.reset();
    if (flutter_controller_) {
        flutter_controller_ = nullptr;
    }

    Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam)

noexcept {
// Give Flutter, including plugins, an opportunity to handle window messages.
if (flutter_controller_) {
std::optional <LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
if (result) {
return *
result;
}
}

switch (message) {
case WM_FONTCHANGE:
flutter_controller_->engine()->ReloadSystemFonts();
break;
case WM_COPYDATA: {
    const auto *cds = reinterpret_cast<const COPYDATASTRUCT *>(lparam);
    if (cds != nullptr && cds->dwData == kAnoxiaUriCopyDataId &&
        cds->lpData != nullptr && cds->cbData >= sizeof(wchar_t) &&
        register_return_channel_ != nullptr) {
        const auto *raw = reinterpret_cast<const wchar_t *>(cds->lpData);
        std::wstring uri(raw, cds->cbData / sizeof(wchar_t));
        if (!uri.empty() && uri.back() == L'\0') {
            uri.pop_back();
        }

        const std::string utf8_uri = WideToUtf8(uri);
        if (!utf8_uri.empty()) {
            register_return_channel_->InvokeMethod(
                    "onLink",
                    std::make_unique<flutter::EncodableValue>(utf8_uri));
        }
    }
    return 0;
}
}

return
Win32Window::MessageHandler(hwnd, message, wparam, lparam
);
}
