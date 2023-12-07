const std = @import("std");

const ui = @import("zgui");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;

const data_path = @import("build_options").data_path;

pub fn main() !void {
    try glfw.init();
    defer glfw.terminate();

    const gl_major = 4;
    const gl_minor = 0;
    glfw.windowHintTyped(.context_version_major, gl_major);
    glfw.windowHintTyped(.context_version_minor, gl_minor);
    glfw.windowHintTyped(.opengl_profile, .opengl_core_profile);
    glfw.windowHintTyped(.opengl_forward_compat, true);
    glfw.windowHintTyped(.client_api, .opengl_api);
    glfw.windowHintTyped(.doublebuffer, true);
    glfw.windowHintTyped(.scale_framebuffer, true);
    glfw.windowHintTyped(.srgb_capable, true);

    var app: Application = .{};

    app.window = try glfw.Window.create(800, 500, app.title, null);
    defer app.window.destroy();

    app.window.setSizeLimits(400, 400, -1, -1);

    glfw.makeContextCurrent(app.window);
    glfw.swapInterval(0);

    try zopengl.loadCoreProfile(glfw.getProcAddress, gl_major, gl_minor);

    var gpa_state = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa_state.deinit();
    const gpa = gpa_state.allocator();

    ui.init(gpa);
    defer ui.deinit();
    ui.plot.init();
    defer ui.plot.deinit();

    ui.io.setConfigFlags(.{
        .dock_enable = true,
        .nav_enable_keyboard = true,
        .is_touch_screen = true,
    });

    const scale_factor = scale_factor: {
        const scale = app.window.getContentScale();
        break :scale_factor @max(scale[0], scale[1]);
    };

    const font_config = ui.FontConfig.init();
    _ = ui.io.addFontFromFileWithConfig(
        data_path ++ "/IBM_Plex_Sans/IBMPlexSans-Regular.ttf",
        std.math.floor(32.0 * scale_factor),
        font_config,
        null,
    );

    ui.getStyle().scaleAllSizes(scale_factor);
    // ui.getStyle().setDefaultColors(.light);

    ////////////////////////////////////////////////////////////////////////////////

    ui.backend.init(app.window);
    defer ui.backend.deinit();

    ////////////////////////////////////////////////////////////////////////////////

    while (!app.window.shouldClose() and app.window.getKey(.escape) != .press) {
        glfw.pollEvents();

        gl.clearBufferfv(gl.COLOR, 0, &app.bg_color);

        const fb_size = app.window.getFramebufferSize();
        ui.backend.newFrame(@intCast(fb_size[0]), @intCast(fb_size[1]));

        try frame(&app);

        ui.backend.draw();

        app.window.swapBuffers();
    }
}

const Application = struct {
    window: *glfw.Window = undefined,

    title: [:0]const u8 = "zig gui demo",

    bg_color: [4]f32 = .{ 0, 0, 0, 1.0 },

    show_demo: bool = true,
};

fn frame(app: *Application) !void {
    const dockspace_id = ui.DockSpaceOverViewport(0, ui.getMainViewport(), .{});
    _ = dockspace_id;

    ui.setNextWindowPos(.{ .x = 20.0, .y = 20.0, .cond = .first_use_ever });
    ui.setNextWindowSize(.{ .w = -1.0, .h = -1.0, .cond = .first_use_ever });
    if (ui.begin("My window", .{})) {
        if (ui.button("Demo!", .{ .w = 200.0 })) {
            app.show_demo = !app.show_demo;
        }
        if (app.show_demo) {
            ui.showDemoWindow(&app.show_demo);
        }
    }
    ui.end();
}
