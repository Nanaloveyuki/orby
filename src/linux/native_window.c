#ifdef __linux__
#include <gtk/gtk.h>
#include <moonbit.h>
#include <stdint.h>

typedef void (*orby_event_callback)(void *, int32_t, int32_t, int32_t, int32_t, double, double);
static orby_event_callback event_callback = NULL;
static void *event_context = NULL;
static int exit_requested = 0;
static int32_t exit_code = 0;
static int32_t window_count = 0;
static int poll_mode = 0;

typedef struct {
  int32_t min_width;
  int32_t min_height;
  int32_t max_width;
  int32_t max_height;
} OrbySizeConstraints;

static int32_t window_id(GtkWidget *fixed) {
  return GPOINTER_TO_INT(g_object_get_data(G_OBJECT(fixed), "orby-window-id"));
}

static void emit_event(GtkWidget *fixed, int32_t kind, int32_t arg0, int32_t arg1, double argd0, double argd1) {
  if (event_callback != NULL) event_callback(event_context, kind, window_id(fixed), arg0, arg1, argd0, argd1);
}

static void emit_application_event(int32_t kind) {
  if (event_callback != NULL) event_callback(event_context, kind, 0, 0, 0, 0.0, 0.0);
}

static void request_exit(int32_t code) {
  exit_requested = 1;
  exit_code = code;
  if (gtk_main_level() > 0) gtk_main_quit();
}

static GtkWidget *window_from_host(uint64_t host) {
  GtkWidget *fixed = (GtkWidget *)(uintptr_t)host;
  return fixed == NULL ? NULL : GTK_WIDGET(g_object_get_data(G_OBJECT(fixed), "orby-window"));
}

static OrbySizeConstraints *constraints_from_host(GtkWidget *fixed, int create) {
  if (fixed == NULL) return NULL;
  OrbySizeConstraints *constraints = g_object_get_data(G_OBJECT(fixed), "orby-size-constraints");
  if (constraints == NULL && create) {
    constraints = g_new0(OrbySizeConstraints, 1);
    g_object_set_data_full(G_OBJECT(fixed), "orby-size-constraints", constraints, g_free);
  }
  return constraints;
}

static int32_t constrained_dimension(int32_t value, int32_t minimum, int32_t maximum) {
  if (value < 1) value = 1;
  if (minimum > 0 && value < minimum) value = minimum;
  if (maximum > 0 && value > maximum) value = maximum;
  return value;
}

static void apply_size_constraints(GtkWidget *window, OrbySizeConstraints *constraints) {
  GdkGeometry geometry = { 0 };
  GdkWindowHints hints = 0;
  if (constraints->min_width > 0 || constraints->min_height > 0) {
    geometry.min_width = constraints->min_width > 0 ? constraints->min_width : 1;
    geometry.min_height = constraints->min_height > 0 ? constraints->min_height : 1;
    hints |= GDK_HINT_MIN_SIZE;
  }
  if (constraints->max_width > 0 || constraints->max_height > 0) {
    geometry.max_width = constraints->max_width > 0 ? constraints->max_width : G_MAXINT;
    geometry.max_height = constraints->max_height > 0 ? constraints->max_height : G_MAXINT;
    hints |= GDK_HINT_MAX_SIZE;
  }
  gtk_window_set_geometry_hints(GTK_WINDOW(window), NULL, &geometry, hints);
}

static int32_t modifier_bits(GdkModifierType state) {
  int32_t modifiers = 0;
  if ((state & GDK_SHIFT_MASK) != 0) modifiers |= 1;
  if ((state & GDK_CONTROL_MASK) != 0) modifiers |= 2;
  if ((state & GDK_MOD1_MASK) != 0) modifiers |= 4;
  if ((state & (GDK_SUPER_MASK | GDK_META_MASK)) != 0) modifiers |= 8;
  return modifiers;
}

static gboolean on_delete(GtkWidget *window, GdkEvent *, gpointer data) {
  (void)window;
  emit_event(GTK_WIDGET(data), 1, 0, 0, 0.0, 0.0);
  return TRUE;
}
static void on_destroy(GtkWidget *, gpointer data) {
  if (window_count > 0) window_count--;
  emit_event(GTK_WIDGET(data), 2, 0, 0, 0.0, 0.0);
  if (window_count == 0 && !exit_requested) request_exit(0);
}
static void on_size_allocate(GtkWidget *, GtkAllocation *allocation, gpointer data) {
  if (allocation->width > 0 && allocation->height > 0 &&
      allocation->width <= 32768 && allocation->height <= 32768) {
    emit_event(GTK_WIDGET(data), 3, allocation->width, allocation->height, 0.0, 0.0);
  }
}
static gboolean on_draw(GtkWidget *, cairo_t *, gpointer data) { emit_event(GTK_WIDGET(data), 6, 0, 0, 0.0, 0.0); return FALSE; }
static gboolean on_focus_in(GtkWidget *, GdkEventFocus *, gpointer data) { emit_event(GTK_WIDGET(data), 5, 1, 0, 0.0, 0.0); return FALSE; }
static gboolean on_focus_out(GtkWidget *, GdkEventFocus *, gpointer data) { emit_event(GTK_WIDGET(data), 5, 0, 0, 0.0, 0.0); return FALSE; }
static void on_scale(GtkWidget *window, GParamSpec *, gpointer data) { emit_event(GTK_WIDGET(data), 4, 0, 0, (double)gtk_widget_get_scale_factor(window), 0.0); }
static gboolean on_key_press(GtkWidget *, GdkEventKey *event, gpointer data) {
  int32_t flags = modifier_bits(event->state) | 16;
  emit_event(GTK_WIDGET(data), 7, (int32_t)event->hardware_keycode, flags, 0.0, 0.0);
  gunichar character = gdk_keyval_to_unicode(event->keyval);
  if (character != 0 && g_unichar_isprint(character)) emit_event(GTK_WIDGET(data), 8, (int32_t)character, 0, 0.0, 0.0);
  return FALSE;
}
static gboolean on_key_release(GtkWidget *, GdkEventKey *event, gpointer data) {
  emit_event(GTK_WIDGET(data), 7, (int32_t)event->hardware_keycode, modifier_bits(event->state), 0.0, 0.0);
  return FALSE;
}
static gboolean on_motion(GtkWidget *widget, GdkEventMotion *event, gpointer data) {
  int scale = gtk_widget_get_scale_factor(widget);
  emit_event(GTK_WIDGET(data), 9, (int32_t)(event->x * scale), (int32_t)(event->y * scale), 0.0, 0.0);
  return FALSE;
}
static gboolean on_enter(GtkWidget *, GdkEventCrossing *, gpointer data) { emit_event(GTK_WIDGET(data), 10, 0, 0, 0.0, 0.0); return FALSE; }
static gboolean on_leave(GtkWidget *, GdkEventCrossing *, gpointer data) { emit_event(GTK_WIDGET(data), 11, 0, 0, 0.0, 0.0); return FALSE; }
static int32_t mouse_button(guint button) {
  if (button == 1) return 1;
  if (button == 3) return 2;
  if (button == 2) return 3;
  if (button == 8) return 4;
  if (button == 9) return 5;
  return (int32_t)button;
}
static gboolean on_button_press(GtkWidget *, GdkEventButton *event, gpointer data) {
  emit_event(GTK_WIDGET(data), 12, mouse_button(event->button), modifier_bits(event->state) | 16, 0.0, 0.0);
  return FALSE;
}
static gboolean on_button_release(GtkWidget *, GdkEventButton *event, gpointer data) {
  emit_event(GTK_WIDGET(data), 12, mouse_button(event->button), modifier_bits(event->state), 0.0, 0.0);
  return FALSE;
}
static gboolean on_scroll(GtkWidget *, GdkEventScroll *event, gpointer data) {
  double x = 0.0, y = 0.0;
  if (!gdk_event_get_scroll_deltas((GdkEvent *)event, &x, &y)) {
    if (event->direction == GDK_SCROLL_UP) y = -1.0;
    else if (event->direction == GDK_SCROLL_DOWN) y = 1.0;
    else if (event->direction == GDK_SCROLL_LEFT) x = -1.0;
    else if (event->direction == GDK_SCROLL_RIGHT) x = 1.0;
  }
  emit_event(GTK_WIDGET(data), 13, 0, modifier_bits(event->state), x, y);
  return FALSE;
}

MOONBIT_FFI_EXPORT int32_t orby_gtk_init(void) {
  int argc = 0;
  char **argv = NULL;
  if (!gtk_init_check(&argc, &argv)) return 0;
  exit_requested = 0;
  exit_code = 0;
  window_count = 0;
  poll_mode = 0;
  return 1;
}
MOONBIT_FFI_EXPORT uint64_t orby_gtk_create_window(moonbit_bytes_t title, int32_t width, int32_t height, int32_t visible, int32_t resizable, int32_t id) {
  GtkWidget *window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  GtkWidget *fixed = gtk_fixed_new();
  gtk_window_set_title(GTK_WINDOW(window), (const char *)title);
  gtk_window_set_default_size(GTK_WINDOW(window), width, height);
  gtk_window_set_resizable(GTK_WINDOW(window), resizable != 0);
  gtk_container_add(GTK_CONTAINER(window), fixed);
  g_object_set_data(G_OBJECT(fixed), "orby-window", window);
  g_object_set_data(G_OBJECT(fixed), "orby-window-id", GINT_TO_POINTER(id));
  g_signal_connect(window, "delete-event", G_CALLBACK(on_delete), fixed);
  g_signal_connect(window, "destroy", G_CALLBACK(on_destroy), fixed);
  g_signal_connect(fixed, "size-allocate", G_CALLBACK(on_size_allocate), fixed);
  g_signal_connect(window, "draw", G_CALLBACK(on_draw), fixed);
  g_signal_connect(window, "focus-in-event", G_CALLBACK(on_focus_in), fixed);
  g_signal_connect(window, "focus-out-event", G_CALLBACK(on_focus_out), fixed);
  g_signal_connect(window, "notify::scale-factor", G_CALLBACK(on_scale), fixed);
  gtk_widget_add_events(window,
      GDK_KEY_PRESS_MASK | GDK_KEY_RELEASE_MASK | GDK_POINTER_MOTION_MASK |
      GDK_ENTER_NOTIFY_MASK | GDK_LEAVE_NOTIFY_MASK | GDK_BUTTON_PRESS_MASK |
      GDK_BUTTON_RELEASE_MASK | GDK_SCROLL_MASK | GDK_SMOOTH_SCROLL_MASK);
  g_signal_connect(window, "key-press-event", G_CALLBACK(on_key_press), fixed);
  g_signal_connect(window, "key-release-event", G_CALLBACK(on_key_release), fixed);
  g_signal_connect(window, "motion-notify-event", G_CALLBACK(on_motion), fixed);
  g_signal_connect(window, "enter-notify-event", G_CALLBACK(on_enter), fixed);
  g_signal_connect(window, "leave-notify-event", G_CALLBACK(on_leave), fixed);
  g_signal_connect(window, "button-press-event", G_CALLBACK(on_button_press), fixed);
  g_signal_connect(window, "button-release-event", G_CALLBACK(on_button_release), fixed);
  g_signal_connect(window, "scroll-event", G_CALLBACK(on_scroll), fixed);
  window_count++;
  if (visible) gtk_widget_show_all(window);
  return (uint64_t)(uintptr_t)fixed;
}
MOONBIT_FFI_EXPORT void orby_gtk_destroy_window(uint64_t host) {
  GtkWidget *fixed = (GtkWidget *)(uintptr_t)host;
  GtkWidget *window = fixed == NULL ? NULL : GTK_WIDGET(g_object_get_data(G_OBJECT(fixed), "orby-window"));
  if (window != NULL) gtk_widget_destroy(window);
}
MOONBIT_FFI_EXPORT void orby_gtk_set_title(uint64_t host, moonbit_bytes_t title) {
  GtkWidget *fixed = (GtkWidget *)(uintptr_t)host;
  GtkWidget *window = fixed == NULL ? NULL : GTK_WIDGET(g_object_get_data(G_OBJECT(fixed), "orby-window"));
  if (window != NULL) gtk_window_set_title(GTK_WINDOW(window), (const char *)title);
}
MOONBIT_FFI_EXPORT void orby_gtk_request_redraw(uint64_t host) { if (host != 0) gtk_widget_queue_draw((GtkWidget *)(uintptr_t)host); }
MOONBIT_FFI_EXPORT void orby_gtk_set_visible(uint64_t host, int32_t visible) {
  GtkWidget *fixed = (GtkWidget *)(uintptr_t)host;
  GtkWidget *window = fixed == NULL ? NULL : GTK_WIDGET(g_object_get_data(G_OBJECT(fixed), "orby-window"));
  if (window != NULL) {
    if (visible) gtk_widget_show_all(window);
    else gtk_widget_hide(window);
  }
}
MOONBIT_FFI_EXPORT void orby_gtk_set_resizable(uint64_t host, int32_t resizable) {
  GtkWidget *fixed = (GtkWidget *)(uintptr_t)host;
  GtkWidget *window = fixed == NULL ? NULL : GTK_WIDGET(g_object_get_data(G_OBJECT(fixed), "orby-window"));
  if (window != NULL) gtk_window_set_resizable(GTK_WINDOW(window), resizable != 0);
}
MOONBIT_FFI_EXPORT void orby_gtk_set_minimized(uint64_t host, int32_t minimized) {
  GtkWidget *window = window_from_host(host);
  if (window != NULL) {
    if (minimized) gtk_window_iconify(GTK_WINDOW(window));
    else gtk_window_deiconify(GTK_WINDOW(window));
  }
}
MOONBIT_FFI_EXPORT int32_t orby_gtk_is_minimized(uint64_t host) {
  GtkWidget *window = window_from_host(host);
  GdkWindow *surface = window == NULL ? NULL : gtk_widget_get_window(window);
  return surface != NULL && (gdk_window_get_state(surface) & GDK_WINDOW_STATE_ICONIFIED) != 0;
}
MOONBIT_FFI_EXPORT void orby_gtk_set_maximized(uint64_t host, int32_t maximized) {
  GtkWidget *window = window_from_host(host);
  if (window != NULL) {
    if (maximized) gtk_window_maximize(GTK_WINDOW(window));
    else gtk_window_unmaximize(GTK_WINDOW(window));
  }
}
MOONBIT_FFI_EXPORT int32_t orby_gtk_is_maximized(uint64_t host) {
  GtkWidget *window = window_from_host(host);
  GdkWindow *surface = window == NULL ? NULL : gtk_widget_get_window(window);
  return surface != NULL && (gdk_window_get_state(surface) & GDK_WINDOW_STATE_MAXIMIZED) != 0;
}
MOONBIT_FFI_EXPORT void orby_gtk_set_decorated(uint64_t host, int32_t decorated) {
  GtkWidget *window = window_from_host(host);
  if (window != NULL) gtk_window_set_decorated(GTK_WINDOW(window), decorated != 0);
}
MOONBIT_FFI_EXPORT void orby_gtk_set_min_inner_size(uint64_t host, int32_t width, int32_t height) {
  GtkWidget *fixed = (GtkWidget *)(uintptr_t)host;
  GtkWidget *window = window_from_host(host);
  OrbySizeConstraints *constraints = constraints_from_host(fixed, 1);
  if (window == NULL || constraints == NULL) return;
  constraints->min_width = width > 0 ? width : 0;
  constraints->min_height = height > 0 ? height : 0;
  if (constraints->max_width > 0 && constraints->min_width > constraints->max_width) constraints->max_width = constraints->min_width;
  if (constraints->max_height > 0 && constraints->min_height > constraints->max_height) constraints->max_height = constraints->min_height;
  apply_size_constraints(window, constraints);
}
MOONBIT_FFI_EXPORT void orby_gtk_set_max_inner_size(uint64_t host, int32_t width, int32_t height) {
  GtkWidget *fixed = (GtkWidget *)(uintptr_t)host;
  GtkWidget *window = window_from_host(host);
  OrbySizeConstraints *constraints = constraints_from_host(fixed, 1);
  if (window == NULL || constraints == NULL) return;
  constraints->max_width = width > 0 ? width : 0;
  constraints->max_height = height > 0 ? height : 0;
  if (constraints->max_width > 0 && constraints->min_width > constraints->max_width) constraints->min_width = constraints->max_width;
  if (constraints->max_height > 0 && constraints->min_height > constraints->max_height) constraints->min_height = constraints->max_height;
  apply_size_constraints(window, constraints);
}
MOONBIT_FFI_EXPORT void orby_gtk_set_inner_size(uint64_t host, int32_t width, int32_t height) {
  GtkWidget *fixed = (GtkWidget *)(uintptr_t)host;
  GtkWidget *window = window_from_host(host);
  OrbySizeConstraints *constraints = constraints_from_host(fixed, 0);
  if (window != NULL) gtk_window_resize(GTK_WINDOW(window),
      constrained_dimension(width, constraints == NULL ? 0 : constraints->min_width, constraints == NULL ? 0 : constraints->max_width),
      constrained_dimension(height, constraints == NULL ? 0 : constraints->min_height, constraints == NULL ? 0 : constraints->max_height));
}
MOONBIT_FFI_EXPORT int32_t orby_gtk_inner_width(uint64_t host) {
  GtkWidget *fixed = (GtkWidget *)(uintptr_t)host;
  return fixed == NULL ? 0 : gtk_widget_get_allocated_width(fixed);
}
MOONBIT_FFI_EXPORT int32_t orby_gtk_inner_height(uint64_t host) {
  GtkWidget *fixed = (GtkWidget *)(uintptr_t)host;
  return fixed == NULL ? 0 : gtk_widget_get_allocated_height(fixed);
}
MOONBIT_FFI_EXPORT double orby_gtk_scale_factor(uint64_t host) {
  GtkWidget *fixed = (GtkWidget *)(uintptr_t)host;
  return fixed == NULL ? 1.0 : (double)gtk_widget_get_scale_factor(fixed);
}
MOONBIT_FFI_EXPORT void orby_gtk_set_outer_position(uint64_t host, int32_t x, int32_t y) {
  GtkWidget *window = window_from_host(host);
  if (window != NULL) gtk_window_move(GTK_WINDOW(window), x, y);
}
MOONBIT_FFI_EXPORT void orby_gtk_request_close(uint64_t host) {
  GtkWidget *fixed = (GtkWidget *)(uintptr_t)host;
  GtkWidget *window = fixed == NULL ? NULL : GTK_WIDGET(g_object_get_data(G_OBJECT(fixed), "orby-window"));
  if (window != NULL) {
    gboolean handled = FALSE;
    g_signal_emit_by_name(window, "delete-event", NULL, &handled);
  }
}
MOONBIT_FFI_EXPORT void orby_gtk_exit(int32_t code) {
  request_exit(code);
}
MOONBIT_FFI_EXPORT void orby_gtk_set_control_flow(int32_t poll) { poll_mode = poll != 0; }
MOONBIT_FFI_EXPORT void orby_gtk_set_event_callback(orby_event_callback callback, void *context) {
  if (event_context != NULL) moonbit_decref(event_context);
  event_callback = callback;
  event_context = context;
}
MOONBIT_FFI_EXPORT int32_t orby_gtk_run(void) {
  while (!exit_requested) {
    while (gtk_events_pending()) gtk_main_iteration();
    if (exit_requested) break;
    emit_application_event(14);
    if (exit_requested || poll_mode) continue;
    gtk_main_iteration();
  }
  int32_t code = exit_code;
  event_callback = NULL;
  if (event_context != NULL) moonbit_decref(event_context);
  event_context = NULL;
  exit_requested = 0;
  exit_code = 0;
  poll_mode = 0;
  return code;
}
#else
#include <moonbit.h>
#include <stdint.h>
MOONBIT_FFI_EXPORT int32_t orby_gtk_init(void) { return 0; }
MOONBIT_FFI_EXPORT uint64_t orby_gtk_create_window(moonbit_bytes_t t, int32_t w, int32_t h, int32_t v, int32_t r, int32_t i) { (void)t; (void)w; (void)h; (void)v; (void)r; (void)i; return 0; }
MOONBIT_FFI_EXPORT void orby_gtk_destroy_window(uint64_t h) { (void)h; }
MOONBIT_FFI_EXPORT void orby_gtk_set_title(uint64_t h, moonbit_bytes_t t) { (void)h; (void)t; }
MOONBIT_FFI_EXPORT void orby_gtk_request_redraw(uint64_t h) { (void)h; }
MOONBIT_FFI_EXPORT void orby_gtk_set_visible(uint64_t h, int32_t v) { (void)h; (void)v; }
MOONBIT_FFI_EXPORT void orby_gtk_set_resizable(uint64_t h, int32_t r) { (void)h; (void)r; }
MOONBIT_FFI_EXPORT void orby_gtk_set_minimized(uint64_t h, int32_t v) { (void)h; (void)v; }
MOONBIT_FFI_EXPORT int32_t orby_gtk_is_minimized(uint64_t h) { (void)h; return 0; }
MOONBIT_FFI_EXPORT void orby_gtk_set_maximized(uint64_t h, int32_t v) { (void)h; (void)v; }
MOONBIT_FFI_EXPORT int32_t orby_gtk_is_maximized(uint64_t h) { (void)h; return 0; }
MOONBIT_FFI_EXPORT void orby_gtk_set_decorated(uint64_t h, int32_t v) { (void)h; (void)v; }
MOONBIT_FFI_EXPORT void orby_gtk_set_min_inner_size(uint64_t h, int32_t w, int32_t t) { (void)h; (void)w; (void)t; }
MOONBIT_FFI_EXPORT void orby_gtk_set_max_inner_size(uint64_t h, int32_t w, int32_t t) { (void)h; (void)w; (void)t; }
MOONBIT_FFI_EXPORT void orby_gtk_set_inner_size(uint64_t h, int32_t w, int32_t t) { (void)h; (void)w; (void)t; }
MOONBIT_FFI_EXPORT int32_t orby_gtk_inner_width(uint64_t h) { (void)h; return 0; }
MOONBIT_FFI_EXPORT int32_t orby_gtk_inner_height(uint64_t h) { (void)h; return 0; }
MOONBIT_FFI_EXPORT double orby_gtk_scale_factor(uint64_t h) { (void)h; return 1.0; }
MOONBIT_FFI_EXPORT void orby_gtk_set_outer_position(uint64_t h, int32_t x, int32_t y) { (void)h; (void)x; (void)y; }
MOONBIT_FFI_EXPORT void orby_gtk_request_close(uint64_t h) { (void)h; }
MOONBIT_FFI_EXPORT void orby_gtk_exit(int32_t c) { (void)c; }
MOONBIT_FFI_EXPORT void orby_gtk_set_control_flow(int32_t p) { (void)p; }
MOONBIT_FFI_EXPORT void orby_gtk_set_event_callback(void *c, void *p) { (void)c; (void)p; }
MOONBIT_FFI_EXPORT int32_t orby_gtk_run(void) { return 1; }
#endif
