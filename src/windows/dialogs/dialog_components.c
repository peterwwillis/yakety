#include "dialog_components.h"
#include "logging.h"
#include <stdlib.h>
#include <string.h>

// Forward declarations for component painters
static void header_component_paint(DialogComponent* component, HDC hdc);
static void header_component_cleanup(DialogComponent* component);
static void button_component_paint(DialogComponent* component, HDC hdc);
static void button_component_click(DialogComponent* component, POINT pt);
static void button_component_cleanup(DialogComponent* component);

// Generic Component Functions

DialogComponent* dialog_component_create(ComponentType type, BaseDialog* dialog, const RECT* bounds) {
    if (!dialog || !bounds) return NULL;

    DialogComponent* component = (DialogComponent*)calloc(1, sizeof(DialogComponent));
    if (!component) {
        log_error("Failed to allocate component memory");
        return NULL;
    }

    component->type = type;
    component->dialog = dialog;
    component->bounds = *bounds;
    component->visible = true;
    component->enabled = true;

    return component;
}

void dialog_component_destroy(DialogComponent* component) {
    if (!component) return;

    if (component->cleanup_func) {
        component->cleanup_func(component);
    }

    free(component);
}

void dialog_component_set_visible(DialogComponent* component, bool visible) {
    if (!component) return;
    
    component->visible = visible;
    if (component->hwnd) {
        ShowWindow(component->hwnd, visible ? SW_SHOW : SW_HIDE);
    }
}

void dialog_component_set_enabled(DialogComponent* component, bool enabled) {
    if (!component) return;
    
    component->enabled = enabled;
    if (component->hwnd) {
        EnableWindow(component->hwnd, enabled ? TRUE : FALSE);
    }
}

void dialog_component_set_bounds(DialogComponent* component, const RECT* bounds) {
    if (!component || !bounds) return;
    
    component->bounds = *bounds;
    if (component->hwnd) {
        SetWindowPos(component->hwnd, NULL, 
                    bounds->left, bounds->top, 
                    bounds->right - bounds->left, 
                    bounds->bottom - bounds->top,
                    SWP_NOZORDER);
    }
}

void dialog_component_paint(DialogComponent* component, HDC hdc) {
    if (!component || !component->visible || !component->paint_func) return;
    
    component->paint_func(component, hdc);
}

void dialog_component_click(DialogComponent* component, POINT pt) {
    if (!component || !component->visible || !component->enabled || !component->click_func) return;
    
    component->click_func(component, pt);
}

// Header Component Implementation

DialogComponent* header_component_create(BaseDialog* dialog, const char* title, const RECT* bounds) {
    DialogComponent* component = dialog_component_create(COMPONENT_TYPE_HEADER, dialog, bounds);
    if (!component) return NULL;

    HeaderComponentData* data = (HeaderComponentData*)calloc(1, sizeof(HeaderComponentData));
    if (!data) {
        dialog_component_destroy(component);
        return NULL;
    }

    // Set title
    if (title) {
        size_t title_len = strlen(title) + 1;
        data->title = (char*)malloc(title_len);
        if (data->title) {
            strcpy_s(data->title, title_len, title);
        }
    }

    // Create title font
    float dpi = dialog->dpi_scale;
    data->title_font = CreateFontW(
        dialog_scale_dpi(DIALOG_TITLE_FONT_SIZE, dpi), 0, 0, 0, FW_MEDIUM,
        FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
        CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
        DEFAULT_PITCH | FF_SWISS, L"Segoe UI");

    // Get app icon
    int icon_size = dialog_scale_dpi(APP_ICON_SIZE, dpi);
    data->icon = (HICON)LoadImage(GetModuleHandle(NULL), MAKEINTRESOURCE(1), 
                                 IMAGE_ICON, icon_size, icon_size, 0);
    if (!data->icon) {
        data->icon = LoadIcon(NULL, IDI_APPLICATION);
    }
    data->show_icon = true;

    component->data = data;
    component->paint_func = header_component_paint;
    component->cleanup_func = header_component_cleanup;

    log_info("Created header component: %s", title ? title : "untitled");
    return component;
}

void header_component_set_title(DialogComponent* component, const char* title) {
    if (!component || component->type != COMPONENT_TYPE_HEADER) return;

    HeaderComponentData* data = (HeaderComponentData*)component->data;
    if (!data) return;

    // Free old title
    free(data->title);
    data->title = NULL;

    // Set new title
    if (title) {
        size_t title_len = strlen(title) + 1;
        data->title = (char*)malloc(title_len);
        if (data->title) {
            strcpy_s(data->title, title_len, title);
        }
    }
}

static void header_component_paint(DialogComponent* component, HDC hdc) {
    HeaderComponentData* data = (HeaderComponentData*)component->data;
    if (!data) return;

    RECT rect = component->bounds;
    BaseDialog* dialog = component->dialog;
    int padding = dialog_scale_dpi(DIALOG_PADDING, dialog->dpi_scale);
    int icon_size = dialog_scale_dpi(APP_ICON_SIZE, dialog->dpi_scale);

    // Draw icon
    if (data->show_icon && data->icon) {
        DrawIconEx(hdc, rect.left + padding, rect.top + padding, 
                  data->icon, icon_size, icon_size, 0, NULL, DI_NORMAL);
    }

    // Draw title
    if (data->title) {
        SetBkMode(hdc, TRANSPARENT);
        SetTextColor(hdc, dialog->theme.text_color);
        HFONT old_font = (HFONT)SelectObject(hdc, data->title_font);

        wchar_t* wide_title = dialog_utf8_to_wide(data->title);
        if (wide_title) {
            RECT title_rect = {
                rect.left + padding + (data->show_icon ? icon_size + padding/2 : 0),
                rect.top + padding,
                rect.right - padding,
                rect.top + padding + icon_size
            };
            DrawTextW(hdc, wide_title, -1, &title_rect, 
                     DT_LEFT | DT_VCENTER | DT_SINGLELINE);
            free(wide_title);
        }

        SelectObject(hdc, old_font);
    }
}

static void header_component_cleanup(DialogComponent* component) {
    HeaderComponentData* data = (HeaderComponentData*)component->data;
    if (!data) return;

    free(data->title);
    if (data->title_font) DeleteObject(data->title_font);
    // Don't delete icon as it may be shared
    free(data);
}

// Button Component Implementation

DialogComponent* button_component_create(BaseDialog* dialog, const char* text, int button_id,
                                        const RECT* bounds, bool is_default,
                                        void (*click_callback)(DialogComponent*, int)) {
    DialogComponent* component = dialog_component_create(COMPONENT_TYPE_BUTTON, dialog, bounds);
    if (!component) return NULL;

    ButtonComponentData* data = (ButtonComponentData*)calloc(1, sizeof(ButtonComponentData));
    if (!data) {
        dialog_component_destroy(component);
        return NULL;
    }

    // Set text
    if (text) {
        size_t text_len = strlen(text) + 1;
        data->text = (char*)malloc(text_len);
        if (data->text) {
            strcpy_s(data->text, text_len, text);
        }
    }

    data->button_id = button_id;
    data->is_default = is_default;
    data->click_callback = click_callback;

    // Create button font
    float dpi = dialog->dpi_scale;
    data->font = CreateFontW(
        dialog_scale_dpi(DIALOG_BUTTON_FONT_SIZE, dpi), 0, 0, 0, FW_NORMAL,
        FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
        CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
        DEFAULT_PITCH | FF_SWISS, L"Segoe UI");

    component->data = data;
    component->paint_func = button_component_paint;
    component->click_func = button_component_click;
    component->cleanup_func = button_component_cleanup;

    log_info("Created button component: %s (ID: %d)", text ? text : "untitled", button_id);
    return component;
}

void button_component_set_hover(DialogComponent* component, bool hovered) {
    if (!component || component->type != COMPONENT_TYPE_BUTTON) return;

    ButtonComponentData* data = (ButtonComponentData*)component->data;
    if (!data) return;

    if (data->is_hovered != hovered) {
        data->is_hovered = hovered;
        // Trigger repaint
        if (component->dialog && component->dialog->hwnd) {
            RECT rect = component->bounds;
            InvalidateRect(component->dialog->hwnd, &rect, FALSE);
        }
    }
}

void button_component_set_pressed(DialogComponent* component, bool pressed) {
    if (!component || component->type != COMPONENT_TYPE_BUTTON) return;

    ButtonComponentData* data = (ButtonComponentData*)component->data;
    if (!data) return;

    if (data->is_pressed != pressed) {
        data->is_pressed = pressed;
        // Trigger repaint
        if (component->dialog && component->dialog->hwnd) {
            RECT rect = component->bounds;
            InvalidateRect(component->dialog->hwnd, &rect, FALSE);
        }
    }
}

static void button_component_paint(DialogComponent* component, HDC hdc) {
    ButtonComponentData* data = (ButtonComponentData*)component->data;
    if (!data) return;

    RECT rect = component->bounds;
    BaseDialog* dialog = component->dialog;

    // Determine button colors based on state
    COLORREF bg_color = dialog->theme.button_bg_color;
    COLORREF text_color = dialog->theme.button_text_color;
    COLORREF border_color = dialog->theme.border_color;

    if (!component->enabled) {
        bg_color = dialog_darken_color(bg_color, 0.3f);
        text_color = dialog_darken_color(text_color, 0.5f);
    } else if (data->is_pressed) {
        bg_color = dialog->theme.button_pressed_color;
    } else if (data->is_hovered) {
        bg_color = dialog->theme.button_hover_color;
    }

    if (data->is_default) {
        border_color = dialog->theme.accent_color;
        if (!data->is_pressed && !data->is_hovered) {
            bg_color = dialog->theme.accent_color;
            text_color = RGB(255, 255, 255);
        }
    }

    // Draw button background with rounded corners
    HBRUSH bg_brush = CreateSolidBrush(bg_color);
    HPEN border_pen = CreatePen(PS_SOLID, 1, border_color);
    
    dialog_draw_rounded_rect(hdc, &rect, 4, border_pen, bg_brush);
    
    DeleteObject(bg_brush);
    DeleteObject(border_pen);

    // Draw button text
    if (data->text) {
        SetBkMode(hdc, TRANSPARENT);
        SetTextColor(hdc, text_color);
        HFONT old_font = (HFONT)SelectObject(hdc, data->font);

        wchar_t* wide_text = dialog_utf8_to_wide(data->text);
        if (wide_text) {
            // Add pressed offset
            RECT text_rect = rect;
            if (data->is_pressed) {
                OffsetRect(&text_rect, 1, 1);
            }
            
            DrawTextW(hdc, wide_text, -1, &text_rect, 
                     DT_CENTER | DT_VCENTER | DT_SINGLELINE);
            free(wide_text);
        }

        SelectObject(hdc, old_font);
    }
}

static void button_component_click(DialogComponent* component, POINT pt) {
    ButtonComponentData* data = (ButtonComponentData*)component->data;
    if (!data || !data->click_callback) return;

    data->click_callback(component, data->button_id);
}

static void button_component_cleanup(DialogComponent* component) {
    ButtonComponentData* data = (ButtonComponentData*)component->data;
    if (!data) return;

    free(data->text);
    if (data->font) DeleteObject(data->font);
    free(data);
}

// List Component Implementation

static void list_component_paint(DialogComponent* component, HDC hdc);
static void list_component_click(DialogComponent* component, POINT pt);
static void list_component_cleanup(DialogComponent* component);

DialogComponent* list_component_create(BaseDialog* dialog, const RECT* bounds, int item_height,
                                      void (*selection_callback)(DialogComponent*, ListItem*)) {
    DialogComponent* component = dialog_component_create(COMPONENT_TYPE_LIST, dialog, bounds);
    if (!component) return NULL;

    ListComponentData* data = (ListComponentData*)calloc(1, sizeof(ListComponentData));
    if (!data) {
        dialog_component_destroy(component);
        return NULL;
    }

    data->item_height = item_height;
    data->selection_callback = selection_callback;
    data->visible_items = (bounds->bottom - bounds->top) / item_height;

    // Create fonts
    float dpi = dialog->dpi_scale;
    data->title_font = CreateFontW(
        dialog_scale_dpi(16, dpi), 0, 0, 0, FW_MEDIUM,
        FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
        CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
        DEFAULT_PITCH | FF_SWISS, L"Segoe UI");

    data->body_font = CreateFontW(
        dialog_scale_dpi(13, dpi), 0, 0, 0, FW_NORMAL,
        FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
        CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
        DEFAULT_PITCH | FF_SWISS, L"Segoe UI");

    component->data = data;
    component->paint_func = list_component_paint;
    component->click_func = list_component_click;
    component->cleanup_func = list_component_cleanup;

    log_info("Created list component with item height: %d", item_height);
    return component;
}

ListItem* list_component_add_item(DialogComponent* component, const char* title,
                                 const char* description, const char* detail,
                                 const char* status_text, COLORREF status_color,
                                 void* user_data) {
    if (!component || component->type != COMPONENT_TYPE_LIST) return NULL;

    ListComponentData* data = (ListComponentData*)component->data;
    if (!data) return NULL;

    ListItem* item = (ListItem*)calloc(1, sizeof(ListItem));
    if (!item) return NULL;

    // Copy strings
    if (title) {
        size_t len = strlen(title) + 1;
        item->title = (char*)malloc(len);
        if (item->title) strcpy_s(item->title, len, title);
    }
    if (description) {
        size_t len = strlen(description) + 1;
        item->description = (char*)malloc(len);
        if (item->description) strcpy_s(item->description, len, description);
    }
    if (detail) {
        size_t len = strlen(detail) + 1;
        item->detail = (char*)malloc(len);
        if (item->detail) strcpy_s(item->detail, len, detail);
    }
    if (status_text) {
        size_t len = strlen(status_text) + 1;
        item->status_text = (char*)malloc(len);
        if (item->status_text) strcpy_s(item->status_text, len, status_text);
    }

    item->status_color = status_color;
    item->user_data = user_data;

    // Add to linked list
    if (!data->items) {
        data->items = item;
    } else {
        ListItem* current = data->items;
        while (current->next) {
            current = current->next;
        }
        current->next = item;
    }

    data->item_count++;
    return item;
}

void list_component_clear(DialogComponent* component) {
    if (!component || component->type != COMPONENT_TYPE_LIST) return;

    ListComponentData* data = (ListComponentData*)component->data;
    if (!data) return;

    ListItem* current = data->items;
    while (current) {
        ListItem* next = current->next;
        free(current->title);
        free(current->description);
        free(current->detail);
        free(current->status_text);
        free(current);
        current = next;
    }

    data->items = NULL;
    data->selected_item = NULL;
    data->item_count = 0;
    data->scroll_offset = 0;
}

ListItem* list_component_get_selected(DialogComponent* component) {
    if (!component || component->type != COMPONENT_TYPE_LIST) return NULL;

    ListComponentData* data = (ListComponentData*)component->data;
    return data ? data->selected_item : NULL;
}

void list_component_set_delete_callback(DialogComponent* component,
                                       void (*delete_callback)(DialogComponent*, ListItem*)) {
    if (!component || component->type != COMPONENT_TYPE_LIST) return;

    ListComponentData* data = (ListComponentData*)component->data;
    if (data) {
        data->delete_callback = delete_callback;
    }
}

static void list_component_paint(DialogComponent* component, HDC hdc) {
    ListComponentData* data = (ListComponentData*)component->data;
    if (!data) return;

    RECT rect = component->bounds;
    BaseDialog* dialog = component->dialog;
    int padding = dialog_scale_dpi(16, dialog->dpi_scale);

    // Draw list background
    HBRUSH bg_brush = CreateSolidBrush(dialog->theme.control_bg_color);
    FillRect(hdc, &rect, bg_brush);
    DeleteObject(bg_brush);

    // Draw items
    ListItem* current = data->items;
    int item_index = 0;
    int y_offset = rect.top;

    // Skip items before scroll offset
    while (current && item_index < data->scroll_offset) {
        current = current->next;
        item_index++;
    }

    // Draw visible items
    int visible_count = 0;
    while (current && visible_count < data->visible_items && y_offset < rect.bottom) {
        RECT item_rect = {
            rect.left,
            y_offset,
            rect.right,
            y_offset + data->item_height
        };

        // Draw item background
        COLORREF item_bg = dialog->theme.control_bg_color;
        if (current->selected) {
            item_bg = dialog->theme.accent_color;
            // Draw selection with rounded corners
            HBRUSH select_brush = CreateSolidBrush(item_bg);
            HPEN select_pen = CreatePen(PS_SOLID, 2, dialog->theme.accent_color);
            dialog_draw_rounded_rect(hdc, &item_rect, 8, select_pen, select_brush);
            DeleteObject(select_brush);
            DeleteObject(select_pen);
        } else {
            HBRUSH item_brush = CreateSolidBrush(item_bg);
            FillRect(hdc, &item_rect, item_brush);
            DeleteObject(item_brush);
        }

        SetBkMode(hdc, TRANSPARENT);

        // Draw title
        if (current->title) {
            COLORREF text_color = current->selected ? RGB(255, 255, 255) : dialog->theme.text_color;
            SetTextColor(hdc, text_color);
            HFONT old_font = (HFONT)SelectObject(hdc, data->title_font);

            wchar_t* wide_title = dialog_utf8_to_wide(current->title);
            if (wide_title) {
                RECT title_rect = {
                    item_rect.left + padding,
                    item_rect.top + padding,
                    item_rect.right - padding - 100, // Leave space for status
                    item_rect.top + padding + 20
                };
                DrawTextW(hdc, wide_title, -1, &title_rect, DT_LEFT | DT_TOP | DT_SINGLELINE);
                free(wide_title);
            }
            SelectObject(hdc, old_font);
        }

        // Draw description
        if (current->description) {
            COLORREF desc_color = current->selected ? 
                dialog_lighten_color(RGB(255, 255, 255), 0.3f) : dialog->theme.secondary_text_color;
            SetTextColor(hdc, desc_color);
            HFONT old_font = (HFONT)SelectObject(hdc, data->body_font);

            wchar_t* wide_desc = dialog_utf8_to_wide(current->description);
            if (wide_desc) {
                RECT desc_rect = {
                    item_rect.left + padding,
                    item_rect.top + padding + 25,
                    item_rect.right - padding - 100,
                    item_rect.top + padding + 45
                };
                DrawTextW(hdc, wide_desc, -1, &desc_rect, DT_LEFT | DT_TOP | DT_SINGLELINE);
                free(wide_desc);
            }
            SelectObject(hdc, old_font);
        }

        // Draw detail (size info)
        if (current->detail) {
            COLORREF detail_color = current->selected ? 
                dialog_lighten_color(RGB(255, 255, 255), 0.3f) : dialog->theme.secondary_text_color;
            SetTextColor(hdc, detail_color);
            HFONT old_font = (HFONT)SelectObject(hdc, data->body_font);

            wchar_t* wide_detail = dialog_utf8_to_wide(current->detail);
            if (wide_detail) {
                RECT detail_rect = {
                    item_rect.left + padding,
                    item_rect.top + padding + 50,
                    item_rect.right - padding - 100,
                    item_rect.bottom - padding
                };
                DrawTextW(hdc, wide_detail, -1, &detail_rect, DT_LEFT | DT_TOP | DT_SINGLELINE);
                free(wide_detail);
            }
            SelectObject(hdc, old_font);
        }

        // Draw status badge
        if (current->status_text) {
            RECT status_rect = {
                item_rect.right - padding - 80,
                item_rect.top + padding,
                item_rect.right - padding,
                item_rect.top + padding + 20
            };

            // Draw badge background
            HBRUSH status_brush = CreateSolidBrush(dialog_lighten_color(current->status_color, 0.8f));
            HPEN status_pen = CreatePen(PS_SOLID, 1, current->status_color);
            dialog_draw_rounded_rect(hdc, &status_rect, 4, status_pen, status_brush);
            DeleteObject(status_brush);
            DeleteObject(status_pen);

            // Draw badge text
            SetTextColor(hdc, current->status_color);
            HFONT old_font = (HFONT)SelectObject(hdc, data->body_font);

            wchar_t* wide_status = dialog_utf8_to_wide(current->status_text);
            if (wide_status) {
                DrawTextW(hdc, wide_status, -1, &status_rect, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
                free(wide_status);
            }
            SelectObject(hdc, old_font);
        }

        // Draw delete button if available and installed
        if (current->has_delete_button && data->delete_callback) {
            RECT delete_rect = {
                item_rect.right - padding - 20,
                item_rect.top + padding + 25,
                item_rect.right - padding,
                item_rect.top + padding + 45
            };

            // Draw trash icon background
            HBRUSH trash_brush = CreateSolidBrush(dialog_lighten_color(RGB(255, 0, 0), 0.8f));
            HPEN trash_pen = CreatePen(PS_SOLID, 1, RGB(255, 0, 0));
            dialog_draw_rounded_rect(hdc, &delete_rect, 2, trash_pen, trash_brush);
            DeleteObject(trash_brush);
            DeleteObject(trash_pen);

            // Draw trash icon (simplified)
            SetTextColor(hdc, RGB(255, 0, 0));
            DrawTextW(hdc, L"🗑", -1, &delete_rect, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
        }

        current = current->next;
        y_offset += data->item_height;
        visible_count++;
    }

    // Draw scrollbar if needed
    if (data->item_count > data->visible_items) {
        RECT scrollbar_rect = {
            rect.right - 8,
            rect.top,
            rect.right,
            rect.bottom
        };

        HBRUSH scrollbar_brush = CreateSolidBrush(dialog->theme.border_color);
        FillRect(hdc, &scrollbar_rect, scrollbar_brush);
        DeleteObject(scrollbar_brush);

        // Draw thumb
        int thumb_height = max(20, (data->visible_items * scrollbar_rect.bottom) / data->item_count);
        int thumb_pos = (data->scroll_offset * (scrollbar_rect.bottom - thumb_height)) / 
                       max(1, data->item_count - data->visible_items);

        RECT thumb_rect = {
            scrollbar_rect.left + 2,
            scrollbar_rect.top + thumb_pos,
            scrollbar_rect.right - 2,
            scrollbar_rect.top + thumb_pos + thumb_height
        };

        HBRUSH thumb_brush = CreateSolidBrush(dialog->theme.accent_color);
        FillRect(hdc, &thumb_rect, thumb_brush);
        DeleteObject(thumb_brush);
    }
}

static void list_component_click(DialogComponent* component, POINT pt) {
    ListComponentData* data = (ListComponentData*)component->data;
    if (!data) return;

    RECT rect = component->bounds;
    
    // Convert to component-relative coordinates
    pt.x -= rect.left;
    pt.y -= rect.top;

    // Check if click is on scrollbar
    if (pt.x > rect.right - rect.left - 8) {
        // Handle scrollbar click
        int scroll_area_height = rect.bottom - rect.top;
        float scroll_percent = (float)pt.y / scroll_area_height;
        int new_offset = (int)(scroll_percent * max(0, data->item_count - data->visible_items));
        data->scroll_offset = max(0, min(new_offset, data->item_count - data->visible_items));
        return;
    }

    // Find clicked item
    int item_index = data->scroll_offset + (pt.y / data->item_height);
    
    ListItem* current = data->items;
    for (int i = 0; i < item_index && current; i++) {
        current = current->next;
    }

    if (current) {
        // Check if delete button was clicked
        if (current->has_delete_button && data->delete_callback) {
            int delete_x = rect.right - rect.left - 20 - 16; // padding
            if (pt.x >= delete_x && pt.x <= delete_x + 20) {
                int delete_y_start = (pt.y % data->item_height) - 16;
                if (delete_y_start >= 25 && delete_y_start <= 45) {
                    data->delete_callback(component, current);
                    return;
                }
            }
        }

        // Select item
        if (data->selected_item) {
            data->selected_item->selected = false;
        }
        current->selected = true;
        data->selected_item = current;

        if (data->selection_callback) {
            data->selection_callback(component, current);
        }

        // Trigger repaint
        if (component->dialog && component->dialog->hwnd) {
            InvalidateRect(component->dialog->hwnd, &rect, FALSE);
        }
    }
}

static void list_component_cleanup(DialogComponent* component) {
    ListComponentData* data = (ListComponentData*)component->data;
    if (!data) return;

    list_component_clear(component);
    
    if (data->title_font) DeleteObject(data->title_font);
    if (data->body_font) DeleteObject(data->body_font);
    
    free(data);
}

// Progress Component Implementation

static void progress_component_paint(DialogComponent* component, HDC hdc);
static void progress_component_cleanup(DialogComponent* component);

DialogComponent* progress_component_create(BaseDialog* dialog, const RECT* bounds) {
    DialogComponent* component = dialog_component_create(COMPONENT_TYPE_PROGRESS, dialog, bounds);
    if (!component) return NULL;

    ProgressComponentData* data = (ProgressComponentData*)calloc(1, sizeof(ProgressComponentData));
    if (!data) {
        dialog_component_destroy(component);
        return NULL;
    }

    data->progress = 0.0f;
    data->progress_color = dialog->theme.accent_color;
    data->bg_color = dialog->theme.border_color;

    // Create font for status text
    float dpi = dialog->dpi_scale;
    data->font = CreateFontW(
        dialog_scale_dpi(14, dpi), 0, 0, 0, FW_NORMAL,
        FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
        CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
        DEFAULT_PITCH | FF_SWISS, L"Segoe UI");

    component->data = data;
    component->paint_func = progress_component_paint;
    component->cleanup_func = progress_component_cleanup;

    log_info("Created progress component");
    return component;
}

void progress_component_set_progress(DialogComponent* component, float progress) {
    if (!component || component->type != COMPONENT_TYPE_PROGRESS) return;

    ProgressComponentData* data = (ProgressComponentData*)component->data;
    if (!data) return;

    data->progress = max(0.0f, min(1.0f, progress));

    // Trigger repaint
    if (component->dialog && component->dialog->hwnd) {
        RECT rect = component->bounds;
        InvalidateRect(component->dialog->hwnd, &rect, FALSE);
    }
}

void progress_component_set_status(DialogComponent* component, const char* status_text) {
    if (!component || component->type != COMPONENT_TYPE_PROGRESS) return;

    ProgressComponentData* data = (ProgressComponentData*)component->data;
    if (!data) return;

    // Free old status text
    free(data->status_text);
    data->status_text = NULL;

    // Set new status text
    if (status_text) {
        size_t len = strlen(status_text) + 1;
        data->status_text = (char*)malloc(len);
        if (data->status_text) {
            strcpy_s(data->status_text, len, status_text);
        }
    }

    // Trigger repaint
    if (component->dialog && component->dialog->hwnd) {
        RECT rect = component->bounds;
        InvalidateRect(component->dialog->hwnd, &rect, FALSE);
    }
}

void progress_component_set_animate(DialogComponent* component, bool animate) {
    if (!component || component->type != COMPONENT_TYPE_PROGRESS) return;

    ProgressComponentData* data = (ProgressComponentData*)component->data;
    if (data) {
        data->animate = animate;
    }
}

static void progress_component_paint(DialogComponent* component, HDC hdc) {
    ProgressComponentData* data = (ProgressComponentData*)component->data;
    if (!data) return;

    RECT rect = component->bounds;
    BaseDialog* dialog = component->dialog;
    
    // Calculate progress bar area (upper half of component)
    int progress_height = dialog_scale_dpi(8, dialog->dpi_scale); // Thicker progress bar
    RECT progress_rect = {
        rect.left,
        rect.top,
        rect.right,
        rect.top + progress_height
    };

    // Draw progress background with rounded corners
    HBRUSH bg_brush = CreateSolidBrush(data->bg_color);
    dialog_draw_rounded_rect(hdc, &progress_rect, progress_height / 2, NULL, bg_brush);
    DeleteObject(bg_brush);

    // Draw progress fill with rounded corners
    if (data->progress > 0.0f) {
        int fill_width = (int)((progress_rect.right - progress_rect.left) * data->progress);
        RECT fill_rect = {
            progress_rect.left,
            progress_rect.top,
            progress_rect.left + fill_width,
            progress_rect.bottom
        };

        HBRUSH fill_brush = CreateSolidBrush(data->progress_color);
        dialog_draw_rounded_rect(hdc, &fill_rect, progress_height / 2, NULL, fill_brush);
        DeleteObject(fill_brush);
    }

    // Draw status text below progress bar
    if (data->status_text) {
        SetBkMode(hdc, TRANSPARENT);
        SetTextColor(hdc, dialog->theme.text_color);
        HFONT old_font = (HFONT)SelectObject(hdc, data->font);

        wchar_t* wide_status = dialog_utf8_to_wide(data->status_text);
        if (wide_status) {
            RECT text_rect = {
                rect.left,
                rect.top + progress_height + dialog_scale_dpi(10, dialog->dpi_scale),
                rect.right,
                rect.bottom
            };
            DrawTextW(hdc, wide_status, -1, &text_rect, DT_CENTER | DT_TOP | DT_SINGLELINE);
            free(wide_status);
        }

        SelectObject(hdc, old_font);
    }
}

static void progress_component_cleanup(DialogComponent* component) {
    ProgressComponentData* data = (ProgressComponentData*)component->data;
    if (!data) return;

    free(data->status_text);
    if (data->font) DeleteObject(data->font);
    free(data);
}

// Capture Area Component Implementation

static void capture_area_component_paint(DialogComponent* component, HDC hdc);
static void capture_area_component_click(DialogComponent* component, POINT pt);
static void capture_area_component_cleanup(DialogComponent* component);

DialogComponent* capture_area_component_create(BaseDialog* dialog, const RECT* bounds,
                                              void (*capture_callback)(DialogComponent*, void*)) {
    DialogComponent* component = dialog_component_create(COMPONENT_TYPE_CAPTURE_AREA, dialog, bounds);
    if (!component) return NULL;

    CaptureAreaComponentData* data = (CaptureAreaComponentData*)calloc(1, sizeof(CaptureAreaComponentData));
    if (!data) {
        dialog_component_destroy(component);
        return NULL;
    }

    data->capture_callback = capture_callback;
    
    // Set default text
    const char* default_text = "Click here to start capturing";
    size_t len = strlen(default_text) + 1;
    data->captured_text = (char*)malloc(len);
    if (data->captured_text) {
        strcpy_s(data->captured_text, len, default_text);
    }

    // Create font
    float dpi = dialog->dpi_scale;
    data->font = CreateFontW(
        dialog_scale_dpi(18, dpi), 0, 0, 0, FW_NORMAL,
        FALSE, FALSE, FALSE, DEFAULT_CHARSET, OUT_DEFAULT_PRECIS,
        CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
        DEFAULT_PITCH | FF_SWISS, L"Segoe UI");

    component->data = data;
    component->paint_func = capture_area_component_paint;
    component->click_func = capture_area_component_click;
    component->cleanup_func = capture_area_component_cleanup;

    log_info("Created capture area component");
    return component;
}

void capture_area_component_start_capture(DialogComponent* component) {
    if (!component || component->type != COMPONENT_TYPE_CAPTURE_AREA) return;

    CaptureAreaComponentData* data = (CaptureAreaComponentData*)component->data;
    if (!data) return;

    data->is_capturing = true;
    data->has_focus = true;
    
    // Update text
    capture_area_component_set_text(component, "Press a key combination...");
}

void capture_area_component_stop_capture(DialogComponent* component) {
    if (!component || component->type != COMPONENT_TYPE_CAPTURE_AREA) return;

    CaptureAreaComponentData* data = (CaptureAreaComponentData*)component->data;
    if (!data) return;

    data->is_capturing = false;
    data->has_focus = false;
}

void capture_area_component_set_text(DialogComponent* component, const char* text) {
    if (!component || component->type != COMPONENT_TYPE_CAPTURE_AREA) return;

    CaptureAreaComponentData* data = (CaptureAreaComponentData*)component->data;
    if (!data) return;

    // Free old text
    free(data->captured_text);
    data->captured_text = NULL;

    // Set new text
    if (text) {
        size_t len = strlen(text) + 1;
        data->captured_text = (char*)malloc(len);
        if (data->captured_text) {
            strcpy_s(data->captured_text, len, text);
        }
    }

    // Trigger repaint
    if (component->dialog && component->dialog->hwnd) {
        RECT rect = component->bounds;
        InvalidateRect(component->dialog->hwnd, &rect, FALSE);
    }
}

static void capture_area_component_paint(DialogComponent* component, HDC hdc) {
    CaptureAreaComponentData* data = (CaptureAreaComponentData*)component->data;
    if (!data) return;

    RECT rect = component->bounds;
    BaseDialog* dialog = component->dialog;

    // Determine colors based on state
    COLORREF bg_color = dialog->theme.control_bg_color;
    COLORREF border_color = dialog->theme.border_color;
    COLORREF text_color = dialog->theme.text_color;

    if (data->is_capturing) {
        border_color = dialog->theme.accent_color;
        bg_color = dialog_lighten_color(dialog->theme.accent_color, 0.9f);
    } else if (data->has_focus) {
        border_color = dialog->theme.accent_color;
    }

    // Draw capture area with rounded corners
    HBRUSH bg_brush = CreateSolidBrush(bg_color);
    HPEN border_pen = CreatePen(PS_SOLID, data->is_capturing ? 2 : 1, border_color);
    
    dialog_draw_rounded_rect(hdc, &rect, 8, border_pen, bg_brush);
    
    DeleteObject(bg_brush);
    DeleteObject(border_pen);

    // Draw captured text
    if (data->captured_text) {
        SetBkMode(hdc, TRANSPARENT);
        SetTextColor(hdc, text_color);
        HFONT old_font = (HFONT)SelectObject(hdc, data->font);

        wchar_t* wide_text = dialog_utf8_to_wide(data->captured_text);
        if (wide_text) {
            DrawTextW(hdc, wide_text, -1, &rect, DT_CENTER | DT_VCENTER | DT_SINGLELINE);
            free(wide_text);
        }

        SelectObject(hdc, old_font);
    }
}

static void capture_area_component_click(DialogComponent* component, POINT pt) {
    CaptureAreaComponentData* data = (CaptureAreaComponentData*)component->data;
    if (!data) return;

    if (!data->is_capturing) {
        capture_area_component_start_capture(component);
        
        if (data->capture_callback) {
            data->capture_callback(component, data->capture_data);
        }
    }
}

static void capture_area_component_cleanup(DialogComponent* component) {
    CaptureAreaComponentData* data = (CaptureAreaComponentData*)component->data;
    if (!data) return;

    free(data->captured_text);
    if (data->font) DeleteObject(data->font);
    free(data);
}