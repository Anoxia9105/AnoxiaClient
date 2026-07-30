#include "flutter_window.h"

#include <algorithm>
#include <cstdint>
#include <optional>
#include <string>
#include <vector>

#include "flutter/generated_plugin_registrant.h"
#include "desktop_multi_window/desktop_multi_window_plugin.h"

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

    taskbar_button_created_message_ =
            RegisterWindowMessageW(L"TaskbarButtonCreated");
    if (SUCCEEDED(CoCreateInstance(CLSID_TaskbarList, nullptr,
                                   CLSCTX_INPROC_SERVER,
                                   IID_PPV_ARGS(&taskbar_list_))) &&
        FAILED(taskbar_list_->HrInit())) {
        taskbar_list_->Release();
        taskbar_list_ = nullptr;
    }

    taskbar_badge_channel_ =
            std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
                    flutter_controller_->engine()->messenger(),
                    "anoxia/taskbar_badge",
                    &flutter::StandardMethodCodec::GetInstance());
    taskbar_badge_channel_->SetMethodCallHandler(
            [this](const flutter::MethodCall<flutter::EncodableValue> &call,
                   std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                           result) {
                if (call.method_name() != "updateBadge") {
                    result->NotImplemented();
                    return;
                }

                int count = 0;
                const auto *arguments = call.arguments();
                if (arguments != nullptr) {
                    const auto *map = std::get_if<flutter::EncodableMap>(arguments);
                    if (map != nullptr) {
                        const auto count_it =
                                map->find(flutter::EncodableValue("count"));
                        if (count_it != map->end()) {
                            if (const auto *int32_value =
                                        std::get_if<int32_t>(&count_it->second)) {
                                count = *int32_value;
                            } else if (const auto *int64_value =
                                               std::get_if<int64_t>(&count_it->second)) {
                                count = static_cast<int>(*int64_value);
                            }
                        }
                    }
                }

                UpdateTaskbarBadge(count);
                result->Success();
            });

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
    if (taskbar_list_ != nullptr) {
        taskbar_list_->SetOverlayIcon(GetHandle(), nullptr, L"");
    }
    if (taskbar_badge_icon_ != nullptr) {
        DestroyIcon(taskbar_badge_icon_);
        taskbar_badge_icon_ = nullptr;
    }
    if (taskbar_list_ != nullptr) {
        taskbar_list_->Release();
        taskbar_list_ = nullptr;
    }
    taskbar_badge_channel_.reset();
    if (flutter_controller_) {
        flutter_controller_ = nullptr;
    }

    Win32Window::OnDestroy();
}

void FlutterWindow::UpdateTaskbarBadge(int count) {
    unread_badge_count_ = std::max(0, count);
    ApplyTaskbarBadge();
}

void FlutterWindow::ApplyTaskbarBadge() {
    if (taskbar_list_ == nullptr || GetHandle() == nullptr) {
        return;
    }

    if (unread_badge_count_ <= 0) {
        taskbar_list_->SetOverlayIcon(GetHandle(), nullptr, L"");
        if (taskbar_badge_icon_ != nullptr) {
            DestroyIcon(taskbar_badge_icon_);
            taskbar_badge_icon_ = nullptr;
        }
        return;
    }

    HICON next_icon = CreateTaskbarBadgeIcon(unread_badge_count_);
    if (next_icon == nullptr) {
        return;
    }

    const std::wstring description =
            std::to_wstring(unread_badge_count_) + L" unread messages";
    if (SUCCEEDED(taskbar_list_->SetOverlayIcon(
                GetHandle(), next_icon, description.c_str()))) {
        if (taskbar_badge_icon_ != nullptr) {
            DestroyIcon(taskbar_badge_icon_);
        }
        taskbar_badge_icon_ = next_icon;
    } else {
        DestroyIcon(next_icon);
    }
}

HICON FlutterWindow::CreateTaskbarBadgeIcon(int count) {
    constexpr int kIconSize = 32;
    BITMAPV5HEADER bitmap_info{};
    bitmap_info.bV5Size = sizeof(BITMAPV5HEADER);
    bitmap_info.bV5Width = kIconSize;
    bitmap_info.bV5Height = -kIconSize;
    bitmap_info.bV5Planes = 1;
    bitmap_info.bV5BitCount = 32;
    bitmap_info.bV5Compression = BI_BITFIELDS;
    bitmap_info.bV5RedMask = 0x00FF0000;
    bitmap_info.bV5GreenMask = 0x0000FF00;
    bitmap_info.bV5BlueMask = 0x000000FF;
    bitmap_info.bV5AlphaMask = 0xFF000000;

    HDC screen_dc = GetDC(nullptr);
    if (screen_dc == nullptr) {
        return nullptr;
    }

    void *raw_pixels = nullptr;
    HBITMAP color_bitmap = CreateDIBSection(
            screen_dc, reinterpret_cast<BITMAPINFO *>(&bitmap_info),
            DIB_RGB_COLORS, &raw_pixels, nullptr, 0);
    HDC memory_dc = CreateCompatibleDC(screen_dc);
    ReleaseDC(nullptr, screen_dc);
    if (color_bitmap == nullptr || memory_dc == nullptr || raw_pixels == nullptr) {
        if (color_bitmap != nullptr) DeleteObject(color_bitmap);
        if (memory_dc != nullptr) DeleteDC(memory_dc);
        return nullptr;
    }

    HGDIOBJ old_bitmap = SelectObject(memory_dc, color_bitmap);
    HBRUSH badge_brush = CreateSolidBrush(RGB(229, 57, 53));
    HPEN badge_pen = CreatePen(PS_NULL, 0, RGB(229, 57, 53));
    HGDIOBJ old_brush = SelectObject(memory_dc, badge_brush);
    HGDIOBJ old_pen = SelectObject(memory_dc, badge_pen);
    Ellipse(memory_dc, 0, 0, kIconSize, kIconSize);

    const std::wstring label = count > 99 ? L"99+" : std::to_wstring(count);
    const int font_height = label.length() >= 3 ? -15 :
                            label.length() == 2 ? -19 : -23;
    HFONT font = CreateFontW(font_height, 0, 0, 0, FW_BOLD, FALSE, FALSE,
                             FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
                             CLIP_DEFAULT_PRECIS, ANTIALIASED_QUALITY,
                             DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
    HGDIOBJ old_font = SelectObject(memory_dc, font);
    SetBkMode(memory_dc, TRANSPARENT);
    SetTextColor(memory_dc, RGB(255, 255, 255));
    RECT text_rect{0, label.length() >= 3 ? 1 : 0, kIconSize, kIconSize};
    DrawTextW(memory_dc, label.c_str(), static_cast<int>(label.length()),
              &text_rect, DT_CENTER | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX);

    // GDI leaves the alpha byte unset. Mark every painted pixel as opaque;
    // untouched pixels stay transparent around the circular badge.
    auto *pixels = static_cast<uint32_t *>(raw_pixels);
    for (int index = 0; index < kIconSize * kIconSize; ++index) {
        if ((pixels[index] & 0x00FFFFFF) != 0) {
            pixels[index] |= 0xFF000000;
        }
    }

    SelectObject(memory_dc, old_font);
    SelectObject(memory_dc, old_pen);
    SelectObject(memory_dc, old_brush);
    SelectObject(memory_dc, old_bitmap);
    DeleteObject(font);
    DeleteObject(badge_pen);
    DeleteObject(badge_brush);
    DeleteDC(memory_dc);

    constexpr int kMaskStride = ((kIconSize + 15) / 16) * 2;
    std::vector<uint8_t> mask_bits(kMaskStride * kIconSize, 0);
    HBITMAP mask_bitmap = CreateBitmap(kIconSize, kIconSize, 1, 1,
                                       mask_bits.data());
    if (mask_bitmap == nullptr) {
        DeleteObject(color_bitmap);
        return nullptr;
    }

    ICONINFO icon_info{};
    icon_info.fIcon = TRUE;
    icon_info.hbmColor = color_bitmap;
    icon_info.hbmMask = mask_bitmap;
    HICON icon = CreateIconIndirect(&icon_info);
    DeleteObject(mask_bitmap);
    DeleteObject(color_bitmap);
    return icon;
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam)

noexcept {
if (message == taskbar_button_created_message_) {
    ApplyTaskbarBadge();
    return 0;
}
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
}

return
Win32Window::MessageHandler(hwnd, message, wparam, lparam
);
}
