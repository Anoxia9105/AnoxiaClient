#include "flutter_window.h"

#include <algorithm>
#include <cmath>
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
    // 高分辨率画布（64px，约为角标显示尺寸的 3~4 倍）：
    // Windows 会把角标缩放到任务栏显示尺寸，高分辨率源图缩放后依然清晰。
    // 文字按内存 DC 的实际 DPI 换算逻辑单位，避免高分屏下 GDI 字体被放大
    // 溢出画布（旧实现固定 32px + 未补偿 DPI，150% 缩放下数字被裁剪发虚）。
    constexpr int kIconSize = 64;
    constexpr uint32_t kBadgeRed = 0x00E53935;  // RGB(229, 57, 53)

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
    const int font_px = label.length() >= 3 ? 30 :
                        label.length() == 2 ? 38 : 46;
    // GDI 字体高度是逻辑单位，按 DC DPI 换算成目标像素高度
    int dc_dpi = GetDeviceCaps(memory_dc, LOGPIXELSY);
    if (dc_dpi <= 0) dc_dpi = 96;
    const int font_logical = -MulDiv(font_px, 96, dc_dpi);
    HFONT font = CreateFontW(font_logical, 0, 0, 0, FW_BOLD, FALSE, FALSE,
                             FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
                             CLIP_DEFAULT_PRECIS, ANTIALIASED_QUALITY,
                             DEFAULT_PITCH | FF_DONTCARE, L"Segoe UI");
    HGDIOBJ old_font = SelectObject(memory_dc, font);
    SetBkMode(memory_dc, TRANSPARENT);
    SetTextColor(memory_dc, RGB(255, 255, 255));
    RECT text_rect{0, label.length() >= 3 ? 2 : 0, kIconSize, kIconSize};
    DrawTextW(memory_dc, label.c_str(), static_cast<int>(label.length()),
              &text_rect, DT_CENTER | DT_VCENTER | DT_SINGLELINE | DT_NOPREFIX);

    // 圆形边缘抗锯齿（按像素到圆心的距离做 1.5px 羽化）+ 补全透明通道。
    // GDI 的圆是硬边，直接缩放会发虚；羽化后边缘平滑，且高分辨率下更清晰。
    auto *pixels = static_cast<uint32_t *>(raw_pixels);
    constexpr double kFeather = 1.5;
    const double radius = kIconSize / 2.0;
    const double center = kIconSize / 2.0;
    for (int y = 0; y < kIconSize; ++y) {
        for (int x = 0; x < kIconSize; ++x) {
            uint32_t &pixel = pixels[y * kIconSize + x];
            const double dx = x + 0.5 - center;
            const double dy = y + 0.5 - center;
            const double dist = std::sqrt(dx * dx + dy * dy);
            const double coverage = radius - dist;
            if (coverage >= kFeather) {
                // 完全在圆内：GDI 已绘制红色/文字，确保完全不透明
                if ((pixel & 0x00FFFFFF) != 0) {
                    pixel |= 0xFF000000;
                }
            } else if (coverage > 0.0) {
                // 边缘过渡：圆外缘 GDI 未绘制的像素补红色，alpha 渐变
                const uint32_t alpha = static_cast<uint32_t>(
                        255.0 * (coverage / kFeather));
                if ((pixel & 0x00FFFFFF) == 0) {
                    pixel = kBadgeRed;
                }
                pixel = (pixel & 0x00FFFFFF) | (alpha << 24);
            } else {
                // 圆外：完全透明
                pixel = 0;
            }
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
